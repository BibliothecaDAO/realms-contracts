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

struct TradeStatus:
    member Open : felt
    member Executed : felt
    member Cancelled : felt
end

struct Trade:
    member token_contract : felt
    member token_id : Uint256
    member expiration : felt
    member price : felt
    member poster : felt
    member status : felt # from TradeStatus
end


struct TokenTrade:
    member trade: Trade
    member idx : felt 
end

# Indexed list of all trades
@storage_var
func _trades(idx: felt) -> (trade : Trade):
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

# Temporary revers mapping of open trade to token due to no events TOREMOVE
@storage_var
func token_open_trade(token_contract : felt, token_id : Uint256) -> (idx : felt):
end

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        address_of_currency_token: felt
    ):
        currency_token_address.write(address_of_currency_token)
        trade_counter.write(1)
        protocol_fee_bips.write(500)
    return ()
end



@external
func open_trade{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(_token_contract : felt, _token_id : Uint256, _price : felt, _expiration: felt):

    let (caller) = get_caller_address()
    let (contract_address) = get_contract_address()
    let (owner_of) = IERC721.ownerOf(_token_contract, _token_id)
    let (is_approved) = IERC721.isApprovedForAll(_token_contract, caller, contract_address)
    let (trade_count) = trade_counter.read()

    assert owner_of = caller
    assert is_approved = 1

    _trades.write(trade_count, Trade(token_contract=_token_contract, token_id=_token_id, expiration=_expiration, price=_price, poster=caller, status=TradeStatus.Open))
    
    #Remove after Stark Events
    token_open_trade.write(_token_contract, _token_id, trade_count)

    trade_counter.write(trade_count + 1)
    return ()
end

@external
func execute_trade{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(_trade : felt):

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

    IERC721.transferFrom(trade.token_contract, trade.poster, caller, trade.token_id)

    _trades.write(_trade, Trade(token_contract=trade.token_contract, token_id=trade.token_id, expiration=trade.expiration, price=trade.price, poster=trade.poster, status=TradeStatus.Executed))
    token_open_trade.write(trade.token_contract, trade.token_id, 0)

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

    _trades.write(_trade, Trade(token_contract=trade.token_contract, token_id=trade.token_id, expiration=trade.expiration, price=_price, poster=trade.poster, status=trade.status))

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

    _trades.write(_trade, Trade(token_contract=trade.token_contract, token_id=trade.token_id, expiration=trade.expiration, price=trade.price, poster=trade.poster, status=TradeStatus.Cancelled))
    token_open_trade.write(trade.token_contract, trade.token_id, 0)

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
func get_open_trade_by_token{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(token_contract: felt, token_id: Uint256) -> (trade: TokenTrade):

    let (idx) = token_open_trade.read(token_contract, token_id)
    let (_trade : Trade) = _trades.read(idx)

    let indexed_trade = TokenTrade (
        trade = _trade,
        idx = idx,

    )
    return (indexed_trade)
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
func get_trade_token_id{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr
        }(idx: felt) -> (token_id : Uint256):
    let (trade) = _trades.read(idx)
    return (trade.token_id)
end
