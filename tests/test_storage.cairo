%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add

@contract_interface
namespace StorageContract:
    func increase_balance(amount : Uint256):
    end

    func get_balance() -> (res : Uint256):
    end
    
    func get_id() -> (res: felt):
    end
end

@external
func test_proxy_contract{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local contract_a_address : felt
    # We deploy contract and put its address into a local variable. Second argument is calldata array
    %{ ids.contract_a_address = deploy_contract("./src/storage_contract.cairo", [100, 0, 1]).contract_address %}

    let (res) = StorageContract.get_balance(contract_address=contract_a_address)
    assert res.low = 100
    assert res.high = 0

    let (id) = StorageContract.get_id(contract_address=contract_a_address)
    assert id = 1
  
    StorageContract.increase_balance(
        contract_address=contract_a_address,
        amount=Uint256(50, 0)
    )

    let (res) = StorageContract.get_balance(contract_address=contract_a_address)
    assert res.low = 150
    assert res.high = 0
    return ()
end

@storage_var
func wonders() -> (res : felt):
end


@external
func test_happiness{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local contract_a_address : felt
    # We deploy contract and put its address into a local variable. Second argument is calldata array
    %{ 
        ids.contract_a_address = deploy_contract("./contracts/settling_game/L04_Calculator.cairo", [123456789]).contract_address 
        # print(contract_a_address)
    %}

    # wonders.write(contract_a_address)

    return ()
end