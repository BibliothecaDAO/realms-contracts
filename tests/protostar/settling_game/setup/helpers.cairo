%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_mul
from starkware.cairo.common.registers import get_label_location

from contracts.settling_game.modules.settling.interface import ISettling
from contracts.settling_game.interfaces.IERC1155 import IERC1155

from tests.protostar.settling_game.setup.interfaces import Realms, ResourcesToken

func get_resources{syscall_ptr: felt*, range_check_ptr}() -> (resources: Uint256*) {
    let (RESOURCES_ARR) = get_label_location(resource_start);
    return (resources=cast(RESOURCES_ARR, Uint256*));

    resource_start:
    dw 1;
    dw 0;
    dw 2;
    dw 0;
    dw 3;
    dw 0;
    dw 4;
    dw 0;
    dw 5;
    dw 0;
    dw 6;
    dw 0;
    dw 7;
    dw 0;
    dw 8;
    dw 0;
    dw 9;
    dw 0;
    dw 10;
    dw 0;
    dw 11;
    dw 0;
    dw 12;
    dw 0;
    dw 13;
    dw 0;
    dw 14;
    dw 0;
    dw 15;
    dw 0;
    dw 16;
    dw 0;
    dw 17;
    dw 0;
    dw 18;
    dw 0;
    dw 19;
    dw 0;
    dw 20;
    dw 0;
    dw 21;
    dw 0;
    dw 22;
    dw 0;
}

func get_amounts{syscall_ptr: felt*, range_check_ptr}(amount: Uint256) -> (
    amounts_len: felt, amounts: Uint256*
) {
    let (amounts: Uint256*) = alloc();
        assert amounts[0] = amount;
        assert amounts[1] = amount;
        assert amounts[2] = amount;
        assert amounts[3] = amount;
        assert amounts[4] = amount;
        assert amounts[5] = amount;
        assert amounts[6] = amount;
        assert amounts[7] = amount;
        assert amounts[8] = amount;
        assert amounts[9] = amount;
        assert amounts[10] = amount;
        assert amounts[11] = amount;
        assert amounts[12] = amount;
        assert amounts[13] = amount;
        assert amounts[14] = amount;
        assert amounts[15] = amount;
        assert amounts[16] = amount;
        assert amounts[17] = amount;
        assert amounts[18] = amount;
        assert amounts[19] = amount;
        assert amounts[20] = amount;
        assert amounts[21] = amount;
    return (amounts_len=22, amounts=amounts);
}

func get_owners{syscall_ptr: felt*, range_check_ptr}(owner: felt) -> (
    owners_len: felt, owners: felt*
) {
    let (owners: felt*) = alloc();
    assert [owners] = owner;
    assert [owners + 1] = owner;
    assert [owners + 2] = owner;
    assert [owners + 3] = owner;
    assert [owners + 4] = owner;
    assert [owners + 5] = owner;
    assert [owners + 6] = owner;
    assert [owners + 7] = owner;
    assert [owners + 8] = owner;
    assert [owners + 9] = owner;
    assert [owners + 10] = owner;
    assert [owners + 11] = owner;
    assert [owners + 12] = owner;
    assert [owners + 13] = owner;
    assert [owners + 14] = owner;
    assert [owners + 15] = owner;
    assert [owners + 16] = owner;
    assert [owners + 17] = owner;
    assert [owners + 18] = owner;
    assert [owners + 19] = owner;
    assert [owners + 20] = owner;
    assert [owners + 21] = owner;
    return (owners_len=22, owners=owners);
}

@external
func settle_realm{syscall_ptr: felt*, range_check_ptr}(
    realms_address: felt,
    settling_address: felt,
    account_address: felt,
    token_id: Uint256,
) {
    Realms.mint(realms_address, account_address, token_id);
    Realms.approve(realms_address, settling_address, token_id);
    ISettling.settle(settling_address, token_id);
    return ();
}

@external
func mint_resources{syscall_ptr: felt*, range_check_ptr}(
    resources_token: felt, amount: Uint256, to: felt
) {
    let (resource_ids) = get_resources();
    let (decimal_amount, _) = uint256_mul(amount, Uint256(10 ** 18, 0));
    let (_, resource_amounts) = get_amounts(decimal_amount);

    let (data: felt*) = alloc();
    assert data[0] = 1;
    IERC1155.mintBatch(
        resources_token,
        to,
        22,
        resource_ids,
        22,
        resource_amounts,
        1,
        data
    );
    return ();
}
