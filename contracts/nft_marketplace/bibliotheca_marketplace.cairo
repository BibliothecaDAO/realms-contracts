# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.messages import send_message_to_l1
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem
from starkware.cairo.common.uint256 import (Uint256, uint256_le)

from contracts.token.IERC20 import IERC20
from contracts.token.IERC721 import IERC721

@storage_var
func token_listings(token_type : felt) -> (balance : felt):
end

struct TradeStatus:
    member Open : felt
    member Executed : felt
    member Cancelled : felt
end

struct Trade:
    member item : Uint256
    member expiration : felt
    member price : felt
    member poster : felt
    member status : felt # from TradeStatus
end

# Indexed list of all trades
@storage_var
func _trades(idx: felt) -> (trade : Trade):
end

# Contract Address of ERC20 used to purchase or sell items
@storage_var
func currency_token_address() -> (address : felt):
end

# Contract Address of Realms NFT
@storage_var
func realms_address() -> (address : felt):
end

# The current number of trades
@storage_var
func trade_counter() -> (value : felt):
end

# Platform fee charged (in basis points)
@storage_var
func protocol_fee_bips() -> (basis_points : felt):
end

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        address_of_currency_token: felt,
        address_of_realms: felt
    ):
        currency_token_address.write(address_of_currency_token)
        realms_address.write(address_of_realms)
        trade_counter.write(0)
        protocol_fee_bips.write(500)
    return ()
end



@external
func open_trade{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(_item : Uint256, _price : felt, _expiration: felt):

    let (realms) = realms_address.read()
    let (caller) = get_caller_address()
    let (contract_address) = get_contract_address()
    let (owner_of) = IERC721.ownerOf(realms, _item)
    let (is_approved) = IERC721.isApprovedForAll(realms, caller, contract_address)
    let (trade_count) = trade_counter.read()

    assert owner_of = caller
    assert is_approved = 1

    _trades.write(trade_count, Trade(item=_item, expiration=_expiration, price=_price, poster=caller, status=TradeStatus.Open))
    trade_counter.write(trade_count + 1)

    return ()
end

@external
func execute_trade{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(_trade : felt):

    let (realms) = realms_address.read()
    let (currency) = currency_token_address.read()

    let (caller) = get_caller_address()
    let (contract_address) = get_contract_address()
    let (trade) = _trades.read(_trade)
    let (fee_bips) = protocol_fee_bips.read()

    assert trade.status = TradeStatus.Open

   # TODO assert expiration not over (requires StarkNet timestamps)

    # Fee is paid by seller
    let (fee, remainder) = unsigned_div_rem(trade.price * fee_bips, 10000)
    let base_seller_receives = trade.price - fee

    IERC20.transferFrom(currency, caller, trade.poster, Uint256(base_seller_receives, 0))
    IERC20.transferFrom(currency, caller, contract_address, Uint256(fee, 0))

    IERC721.transferFrom(realms, trade.poster, caller, trade.item)

    _trades.write(_trade, Trade(item=trade.item, expiration=trade.expiration, price=trade.price, poster=trade.poster, status=TradeStatus.Executed))

    return ()
end

@external
func update_price{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(_trade : felt, _price: felt):

    let (caller) = get_caller_address()
    let (trade) = _trades.read(_trade)

    assert trade.status = TradeStatus.Open

    # Require caller to be the poster of the trade
    assert caller = trade.poster

   # TODO assert expiration not over (requires StarkNet timestamps)

    _trades.write(_trade, Trade(item=trade.item, expiration=trade.expiration, price=_price, poster=trade.poster, status=trade.status))

    return ()
end

@external
func cancel_trade{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(_trade : felt):

    let (caller) = get_caller_address()
    let (trade) = _trades.read(_trade)

    assert trade.status = TradeStatus.Open

    # Require caller to be the poster of the trade
    assert caller = trade.poster

   # TODO assert expiration not over (requires StarkNet timestamps)

    _trades.write(_trade, Trade(item=trade.item, expiration=trade.expiration, price=trade.price, poster=trade.poster, status=TradeStatus.Cancelled))

    return ()
end

@view
func get_trade{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(idx: felt) -> (trade: Trade):
    return _trades.read(idx)
end
@view
func get_trades_by_token{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(idx: felt) -> (trade: Trade):
    return _trades.read(idx)
end

@view
func get_trade_counter{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (trade_counter: felt):
    return trade_counter.read()
end

# Returns a trades status
@view
func get_trade_status{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr
        }(idx: felt) -> (status : felt):
    let (trade) = _trades.read(idx)
    return (trade.status)
end

# Returns a trades token
@view
func get_trade_item{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr
        }(idx: felt) -> (item : Uint256):
    let (trade) = _trades.read(idx)
    return (trade.item)
end
