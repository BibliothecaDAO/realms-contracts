%lang starknet
%builtins pedersen range_check bitwise

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

@external
func test_fetch_trade_data{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local contract_address: felt
    local lords: felt
    local proxy_lords: felt
    local Account: felt
    let (local caller: felt) = get_caller_address()
    local supply: Uint256 = Uint256(1000000000000000000000000,0)

    %{ ids.Account = deploy_contract("./openzeppelin/account/Account.cairo", [123456]).contract_address %}

    %{ print("lords") %}
    %{ ids.lords = deploy_contract("./contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo", [1234, 1234, 18, ids.supply, ids.Account, ids.Account]).contract_address %}
    %{ print("lords1") %}
    %{ ids.proxy_lords = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.lords]).contract_address %}
    LordsInterface.initializer(proxy_lords, 1234, 1234, 18, Uint256(50000, 0), ids.Account, ids.Account)

    #Deploy contract, put address into a local variable. Second argument is calldata array
    %{ ids.contract_address = deploy_contract("./contracts/nft_marketplace/bibliotheca_marketplace.cairo", 
        [ids.lords, 
        ids.caller, 
        ids.caller]).contract_address %}
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