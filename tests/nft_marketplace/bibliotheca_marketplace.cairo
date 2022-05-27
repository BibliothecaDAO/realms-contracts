%lang starknet
# %builtins pedersen range_check bitwise

from protostar.asserts import (
    assert_eq, assert_not_eq, assert_signed_lt, assert_signed_le, assert_signed_gt,
    assert_unsigned_lt, assert_unsigned_le, assert_unsigned_gt, assert_signed_ge,
    assert_unsigned_ge)

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.starknet.common.syscalls import (
    get_contract_address, get_block_number, get_block_timestamp, get_caller_address
)

from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check, uint256_eq
)

@storage_var
func caller_address() -> (i : felt):
end

@contract_interface
namespace LordsInterface:
    func initializer(
        name : felt,
        symbol : felt,
        decimals : felt,
        initial_supply : Uint256,
        recipient : felt,
        proxy_admin : felt,
    ):
    end
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

@contract_interface
namespace NFT_Marketplace:
    func pack_trade_data(trade: Trade) -> (trade_data: felt):
    end

    func fetch_trade_data(trade_data: felt, price: felt, poster: felt) -> (trade: Trade):
    end

    func _uint_to_felt(value: Uint256) -> (value: felt):
    end
end


@external
func test_fetch_trade_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}():
    alloc_locals

    local contract_address: felt
    local lords: felt
    local proxy_lords: felt
    local Account: felt
    let (local caller: felt) = get_caller_address()
    local supply: Uint256 = Uint256(1000000000000000000000000,0)

    %{ ids.Account = deploy_contract("./openzeppelin/account/Account.cairo", [123456]).contract_address %}

    %{ ids.lords = deploy_contract("./contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo", []).contract_address %}
    # %{ print("lords contract: " + str(ids.lords)) %}
    %{ ids.proxy_lords = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.lords]).contract_address %}
    # %{ print("proxy_lords contract: " + str(ids.proxy_lords)) %}
    LordsInterface.initializer(proxy_lords, 1234, 1234, 18, supply, Account, Account)
    # %{ print("lords interface initialized") %}

    #Deploy contract, put address into a local variable. Second argument is calldata array
    %{ ids.contract_address = deploy_contract("./contracts/nft_marketplace/bibliotheca_marketplace.cairo", 
        [ids.proxy_lords, 
        ids.caller, 
        ids.caller]).contract_address %}
    
    # %{ print("realms_marketplace contract: " + str(ids.contract_address)) %}

    local trade_data: felt = 18014416252971264319588
    local price: felt = 1000000000000000000

    
    # fetch_trade_data test
    let (trade: Trade) = NFT_Marketplace.fetch_trade_data(contract_address=contract_address, trade_data=trade_data, price=price, poster=contract_address)
    assert_eq(trade.token_contract, 100)
    assert_eq(trade.token_id.low, 1000000)
    assert_eq(trade.expiration, 31536000)
    assert_eq(trade.status, 3)
    assert_eq(trade.trade_id, 1000000)


    # pack_trade_data test
    let (packed_trade_data: felt) = NFT_Marketplace.pack_trade_data(contract_address=contract_address, trade=trade)
    assert_eq(packed_trade_data, trade_data)

    return ()
end




# @external
# func test_proxy_contract{syscall_ptr : felt*, range_check_ptr}():
#     alloc_locals

#     local contract_address : felt
#     # We deploy contract and put its address into a local variable. Second argument is calldata array
#     %{ ids.contract_address = deploy_contract("./src/storage_contract.cairo", [100, 0, 1]).contract_address %}

#     let (res) = StorageContract.get_balance(contract_address=contract_address)
#     assert res.low = 100
#     assert res.high = 0

#     let (id) = StorageContract.get_id(contract_address=contract_address)
#     assert id = 1

#     StorageContract.increase_balance(contract_address=contract_address, amount=Uint256(50, 0))

#     let (res) = StorageContract.get_balance(contract_address=contract_address)
#     assert res.low = 150
#     assert res.high = 0
#     return ()
# end