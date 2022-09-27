// Declare this file as a StarkNet contract and set the required
// builtins.
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
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_lt_felt
from starkware.cairo.common.uint256 import Uint256, uint256_le

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.IERC721 import IERC721

from openzeppelin.access.ownable.library import Ownable

from openzeppelin.security.pausable.library import Pausable
from contracts.settling_game.utils.general import scale, unpack_data

from contracts.settling_game.utils.constants import (
    SHIFT_NFT_1,
    SHIFT_NFT_2,
    SHIFT_NFT_3,
    SHIFT_NFT_4,
    SHIFT_NFT_5,
)

//###########
// MAPPINGS #
//###########

namespace TradeStatus {
    const Open = 1;
    const Executed = 2;
    const Cancelled = 3;
}

struct Trade {
    token_contract: felt,
    token_id: Uint256,
    expiration: felt,
    price: felt,
    poster: felt,
    status: felt,  // from TradeStatus
    trade_id: felt,
}

// -----------------------------------
// Events
// -----------------------------------

@event
func TradeAction(trade: Trade) {
}

// -----------------------------------
// Storage
// -----------------------------------

// Indexed list of all trades
@storage_var
func _trades(idx: felt) -> (trade: Trade) {
}

// Contract Address of ERC20 used to purchase or sell items
@storage_var
func currency_token_address() -> (address: felt) {
}

// The current number of trades
@storage_var
func trade_counter() -> (value: felt) {
}

// Platform fee charged (in basis points)
@storage_var
func protocol_fee_bips() -> (basis_points: felt) {
}

// Treasury Account
@storage_var
func treasury_address() -> (address: felt) {
}

//##############
// CONSTRUCTOR #
//##############

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address_of_currency_token: felt, _treasury_address: felt, owner: felt
) {
    currency_token_address.write(address_of_currency_token);
    trade_counter.write(1);
    protocol_fee_bips.write(500);
    treasury_address.write(_treasury_address);
    Ownable.initializer(owner);
    return ();
}

//##################
// TRADE FUNCTIONS #
//##################

@external
func fetch_trade_data{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(trade_data: felt, price: felt, poster: felt) -> (trade: Trade) {
    alloc_locals;

    // let (data) = get_trade(trade_data)

    let (token_contract) = unpack_data(trade_data, 0, 127);
    let (t_id) = unpack_data(trade_data, 7, 1048575);
    let (expiration) = unpack_data(trade_data, 27, 33554431);
    let (status) = unpack_data(trade_data, 52, 3);
    let (trade_id) = unpack_data(trade_data, 54, 1048575);

    // token_id needs to be Uint256
    let token_id: Uint256 = Uint256(t_id, 0);

    let trade = Trade(token_contract, token_id, expiration, price, poster, status, trade_id);
    return (trade,);
}

@external
func open_trade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _token_contract: felt, _token_id: Uint256, _price: felt, _expiration: felt
) {
    alloc_locals;
    Pausable.assert_not_paused();
    let (caller) = get_caller_address();
    let (contract_address) = get_contract_address();
    let (owner_of) = IERC721.ownerOf(_token_contract, _token_id);
    let (is_approved) = IERC721.isApprovedForAll(_token_contract, caller, contract_address);
    let (trade_count) = trade_counter.read();

    assert owner_of = caller;
    assert is_approved = 1;

    write_trade(
        trade_count,
        Trade(
        _token_contract, _token_id, _expiration, _price, caller, TradeStatus.Open, trade_count),
    );

    // increment
    trade_counter.write(trade_count + 1);
    return ();
}

@external
func execute_trade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_trade: felt) {
    alloc_locals;
    Pausable.assert_not_paused();
    let (currency) = currency_token_address.read();

    let (caller) = get_caller_address();
    let (_treasury_address) = treasury_address.read();
    let (trade) = _trades.read(_trade);
    let (fee_bips) = protocol_fee_bips.read();

    assert trade.status = TradeStatus.Open;

    assert_time_in_range(_trade);

    // Fee is paid by seller
    let (fee, remainder) = unsigned_div_rem(trade.price * fee_bips, 10000);
    let base_seller_receives = trade.price - fee;

    // transfer to poster
    IERC20.transferFrom(currency, caller, trade.poster, Uint256(base_seller_receives, 0));

    // transfer to treasury
    IERC20.transferFrom(currency, caller, _treasury_address, Uint256(fee, 0));

    // transfer item to buyer
    IERC721.transferFrom(trade.token_contract, trade.poster, caller, trade.token_id);

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
    );

    return ();
}

@external
func update_price{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _trade: felt, _price: felt
) {
    alloc_locals;
    Pausable.assert_not_paused();
    let (trade) = _trades.read(_trade);

    assert trade.status = TradeStatus.Open;

    assert_poster(_trade);
    assert_time_in_range(_trade);

    write_trade(
        _trade,
        Trade(trade.token_contract, trade.token_id, trade.expiration, _price, trade.poster, trade.status, _trade),
    );
    return ();
}

@external
func cancel_trade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_trade: felt) {
    alloc_locals;
    Pausable.assert_not_paused();
    let (trade) = _trades.read(_trade);

    assert trade.status = TradeStatus.Open;

    assert_poster(_trade);
    assert_time_in_range(_trade);

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
    );

    return ();
}

@external
func pack_trade_data{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(trade: Trade) -> (trade_data: felt) {
    alloc_locals;

    let (nft_params: felt*) = alloc();

    local id_1 = trade.token_contract * SHIFT_NFT_1;
    nft_params[0] = id_1;

    local t_id: Uint256 = trade.token_id;
    let (local tid: felt) = _uint_to_felt(t_id);
    local id_2 = tid * SHIFT_NFT_2;
    nft_params[1] = id_2;

    local id_3 = trade.expiration * SHIFT_NFT_3;
    nft_params[2] = id_3;

    local id_4 = trade.status * SHIFT_NFT_4;
    nft_params[3] = id_4;

    local id_5 = trade.trade_id * SHIFT_NFT_5;
    nft_params[4] = id_5;

    tempvar value = nft_params[4] + nft_params[3] + nft_params[2] + nft_params[1] + nft_params[0];

    return (value,);
}

//##########
// HELPERS #
//##########

func write_trade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _trade: felt, trade: Trade
) {
    _trades.write(_trade, trade);
    TradeAction.emit(trade);
    return ();
}

func assert_time_in_range{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _trade: felt
) {
    let (block_timestamp) = get_block_timestamp();
    let (trade) = _trades.read(_trade);
    // check trade within
    assert_nn_le(block_timestamp, trade.expiration);

    return ();
}

func assert_poster{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_trade: felt) {
    let (caller) = get_caller_address();
    let (trade) = _trades.read(_trade);
    assert caller = trade.poster;

    return ();
}

func _uint_to_felt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    value: Uint256
) -> (value: felt) {
    assert_lt_felt(value.high, 2 ** 123);
    return (value.high * (2 ** 128) + value.low,);
}

//##########
// GETTERS #
//##########

@view
func get_trade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(idx: felt) -> (
    trade: Trade
) {
    return _trades.read(idx);
}

@view
func get_trade_counter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    value: felt
) {
    return trade_counter.read();
}

// Returns a trades status
@view
func get_trade_status{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    idx: felt
) -> (status: felt) {
    let (trade) = _trades.read(idx);
    return (trade.status,);
}

// Returns a trades token
@view
func get_trade_token_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    idx: felt
) -> (token_id: Uint256) {
    let (trade) = _trades.read(idx);
    return (trade.token_id,);
}

@view
func paused{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (paused: felt) {
    let (paused) = Pausable.is_paused();
    return (paused,);
}

//##########
// SETTERS #
//##########

// Set basis points
@external
func set_basis_points{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    basis_points: felt
) -> (success: felt) {
    Ownable.assert_only_owner();
    protocol_fee_bips.write(basis_points);
    return (1,);
}

@external
func set_treasury_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) -> (success: felt) {
    Ownable.assert_only_owner();
    treasury_address.write(address);
    return (1,);
}

@external
func set_currency_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) -> (success: felt) {
    Ownable.assert_only_owner();
    currency_token_address.write(address);
    return (1,);
}

@external
func pause{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.assert_only_owner();
    Pausable._pause();
    return ();
}

@external
func unpause{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.assert_only_owner();
    Pausable._unpause();
    return ();
}
