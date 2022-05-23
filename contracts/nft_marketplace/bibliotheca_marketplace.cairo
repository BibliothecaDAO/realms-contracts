# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.messages import send_message_to_l1
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem
from starkware.cairo.common.uint256 import Uint256, uint256_le

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721

from openzeppelin.access.ownable import Ownable_initializer, Ownable_only_owner

from openzeppelin.security.pausable import (
    Pausable_paused,
    Pausable_pause,
    Pausable_unpause,
    Pausable_when_not_paused,
)
from contracts.settling_game.utils.general import (
    scale,
    unpack_data,
    transform_costs_to_token_ids_values,
)

############
# MAPPINGS #
############

namespace TradeStatus:
    const Open = 1
    const Executed = 2
    const Cancelled = 3
end

struct Trade:
    member token_contract : felt
    member token_id : Uint256
    member expiration : felt
    member price : felt
    member poster : felt
    member status : felt  # from TradeStatus
    member trade_id : felt
end

##########
# EVENTS #
##########

@event
func TradeAction(trade : Trade):
end

###########
# STORAGE #
###########

# Indexed list of all trades
@storage_var
func _trades(idx : felt) -> (trade : Trade):
end

# Contract Address of ERC20 used to purchase or sell items
@storage_var
func currency_token_address() -> (address : felt):
end

# The current number of trades
@storage_var
func trade_counter() -> (value : felt):
end

# Platform fee charged (in basis points)
@storage_var
func protocol_fee_bips() -> (basis_points : felt):
end

# Treasury Account
@storage_var
func treasury_address() -> (address : felt):
end

###############
# CONSTRUCTOR #
###############

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_currency_token : felt, _treasury_address : felt, owner : felt
):
    currency_token_address.write(address_of_currency_token)
    trade_counter.write(1)
    protocol_fee_bips.write(500)
    treasury_address.write(_treasury_address)
    Ownable_initializer(owner)
    return ()
end

###################
# TRADE FUNCTIONS #
###################

@external
func fetch_trade_data{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(trade_data: felt, price: felt, poster: felt) -> (trade: Trade):
    alloc_locals

    # let (data) = get_trade(trade_data)

    let (token_contract) = unpack_data(trade_data, 0, 255)
    let (t_id) = unpack_data(trade_data, 7, 255)
    let (expiration) = unpack_data(trade_data, 27, 255)
    let (status) = unpack_data(trade_data, 52, 255)
    let (trade_id) = unpack_data(trade_data, 54, 255)

    #token_id needs to be Uint256
    let token_id: Uint256 = Uint256(t_id, 0)

    let trade = Trade(
        token_contract,
        token_id,
        expiration,
        price,
        poster,
        status,
        trade_id
    )

    return (trade)

end

@external
func open_trade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _token_contract : felt, _token_id : Uint256, _price : felt, _expiration : felt
):
    alloc_locals
    Pausable_when_not_paused()
    let (caller) = get_caller_address()
    let (contract_address) = get_contract_address()
    let (owner_of) = IERC721.ownerOf(_token_contract, _token_id)
    let (is_approved) = IERC721.isApprovedForAll(_token_contract, caller, contract_address)
    let (trade_count) = trade_counter.read()

    assert owner_of = caller
    assert is_approved = 1

    write_trade(
        trade_count,
        Trade(
        _token_contract, _token_id, _expiration, _price, caller, TradeStatus.Open, trade_count),
    )

    # increment
    trade_counter.write(trade_count + 1)
    return ()
end

@external
func execute_trade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _trade : felt
):
    alloc_locals
    Pausable_when_not_paused()
    let (currency) = currency_token_address.read()

    let (caller) = get_caller_address()
    let (_treasury_address) = treasury_address.read()
    let (trade) = _trades.read(_trade)
    let (fee_bips) = protocol_fee_bips.read()

    assert trade.status = TradeStatus.Open

    assert_time_in_range(_trade)

    # Fee is paid by seller
    let (fee, remainder) = unsigned_div_rem(trade.price * fee_bips, 10000)
    let base_seller_receives = trade.price - fee

    # transfer to poster
    IERC20.transferFrom(currency, caller, trade.poster, Uint256(base_seller_receives, 0))

    # transfer to treasury
    IERC20.transferFrom(currency, caller, _treasury_address, Uint256(fee, 0))

    # transfer item to buyer
    IERC721.transferFrom(trade.token_contract, trade.poster, caller, trade.token_id)

    write_trade(
        _trade,
        Trade(
        trade.token_contract,
        trade.token_id,
        trade.expiration,
        trade.price,
        trade.poster,
        TradeStatus.Executed,
        _trade),
    )

    return ()
end

@external
func update_price{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _trade : felt, _price : felt
):
    alloc_locals
    Pausable_when_not_paused()
    let (trade) = _trades.read(_trade)

    assert trade.status = TradeStatus.Open

    assert_poster(_trade)
    assert_time_in_range(_trade)

    write_trade(
        _trade,
        Trade(trade.token_contract, trade.token_id, trade.expiration, _price, trade.poster, trade.status, _trade),
    )
    return ()
end

@external
func cancel_trade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_trade : felt):
    alloc_locals
    Pausable_when_not_paused()
    let (trade) = _trades.read(_trade)

    assert trade.status = TradeStatus.Open

    assert_poster(_trade)
    assert_time_in_range(_trade)

    write_trade(
        _trade,
        Trade(
        trade.token_contract,
        trade.token_id,
        trade.expiration,
        trade.price,
        trade.poster,
        TradeStatus.Cancelled,
        _trade),
    )

    return ()
end

###########
# HELPERS #
###########

func write_trade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _trade : felt, trade : Trade
):
    _trades.write(_trade, trade)
    TradeAction.emit(trade)
    return ()
end

func assert_time_in_range{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _trade : felt
):
    let (block_timestamp) = get_block_timestamp()
    let (trade) = _trades.read(_trade)
    # check trade within
    assert_nn_le(block_timestamp, trade.expiration)

    return ()
end

func assert_poster{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _trade : felt
):
    let (caller) = get_caller_address()
    let (trade) = _trades.read(_trade)
    assert caller = trade.poster

    return ()
end

###########
# GETTERS #
###########

@view
func get_trade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(idx : felt) -> (
    trade : Trade
):
    return _trades.read(idx)
end

@view
func get_trade_counter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    trade_counter : felt
):
    return trade_counter.read()
end

# Returns a trades status
@view
func get_trade_status{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    idx : felt
) -> (status : felt):
    let (trade) = _trades.read(idx)
    return (trade.status)
end

# Returns a trades token
@view
func get_trade_token_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    idx : felt
) -> (token_id : Uint256):
    let (trade) = _trades.read(idx)
    return (trade.token_id)
end

@view
func paused{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (paused : felt):
    let (paused) = Pausable_paused.read()
    return (paused)
end

###########
# SETTERS #
###########

# Set basis points
@external
func set_basis_points{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    basis_points : felt
) -> (success : felt):
    Ownable_only_owner()
    protocol_fee_bips.write(basis_points)
    return (1)
end

@external
func set_treasury_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
) -> (success : felt):
    Ownable_only_owner()
    treasury_address.write(address)
    return (1)
end

@external
func set_currency_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
) -> (success : felt):
    Ownable_only_owner()
    currency_token_address.write(address)
    return (1)
end

@external
func pause{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    Ownable_only_owner()
    Pausable_pause()
    return ()
end

@external
func unpause{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    Ownable_only_owner()
    Pausable_unpause()
    return ()
end
