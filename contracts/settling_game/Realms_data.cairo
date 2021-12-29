%lang starknet
%builtins pedersen range_check ecdsa bitwise
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_not_zero

from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.pow import pow
from contracts.token.ERC721_base import (
    ERC721_initializer, ERC721_approve, ERC721_set_approval_for_all, ERC721_transferFrom,
    ERC721_safeTransferFrom, ERC721_mint, ERC721_burn, ERC721_balances)
from contracts.token.IERC20 import IERC20

from contracts.Ownable_base import Ownable_initializer, Ownable_only_owner

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        name : felt, symbol : felt, owner : felt):
    ERC721_initializer(name, symbol)
    Ownable_initializer(owner)
    return ()
end

#
# Bibliotheca added methods (remove all balance_details functions after events)
#

# # democritus methods for on-chain data
@storage_var
func realm_name(realm_id : Uint256) -> (name : felt):
end

@storage_var
func realm_data(realm_id : Uint256) -> (data : felt):
end

@storage_var
func is_settled(realm_id : Uint256) -> (data : felt):
end

@external
func get_realm_info{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        realm_id : Uint256) -> (realm_data : felt):
    let (data) = realm_data.read(realm_id)
    return (data)
end

struct RealmData:
    member cities : felt  #
    member regions : felt  #
    member rivers : felt  #
    member harbours : felt  # 
    member resource_1 : felt  # 
    member resource_2 : felt  # 
    member resource_3 : felt  # 
    member resource_4 : felt  # 
    member resource_5 : felt  # 
    member resource_6 : felt  # 
    member resource_7 : felt  #            
end

func unpack_realm_data{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr}(realm_id : Uint256, index : felt) -> (score : felt):
    alloc_locals
    # User data is a binary encoded value with alternating
    # 6-bit id followed by a 4-bit score (see top of file).
    let (local data) = realm_data.read(realm_id)
    local syscall_ptr : felt* = syscall_ptr
    local pedersen_ptr : HashBuiltin* = pedersen_ptr
    local bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
    # 1. Create a 4-bit mask at and to the left of the index
    # E.g., 000111100 = 2**2 + 2**3 + 2**4 + 2**5
    # E.g.,  2**(i) + 2**(i+1) + 2**(i+2) + 2**(i+3) = (2**i)(15)
    let (power) = pow(2, index)
    # 1 + 2 + 4 + 8 = 15
    let mask = 15 * power

    # 2. Apply mask using bitwise operation: mask AND data.
    let (masked) = bitwise_and(mask, data)

    # 3. Shift element right by dividing by the order of the mask.
    let (result, _) = unsigned_div_rem(masked, power)

    return (score=result)
end

@external
func fetch_realm_data{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(realm_id : Uint256) -> (realm_stats : RealmData):
    alloc_locals

    # Indicies are defined in the UserRegistry contract.
    # Call the UserRegsitry contract to get scores for given user.
    let (local cities) = unpack_realm_data(realm_id, 0)
    let (local regions) = unpack_realm_data(realm_id, 6)
    let (local rivers) = unpack_realm_data(realm_id, 12)
    let (local harbours) = unpack_realm_data(realm_id, 18)
    let (local resource_1) = unpack_realm_data(realm_id, 24)
    let (local resource_2) = unpack_realm_data(realm_id, 30)
    let (local resource_3) = unpack_realm_data(realm_id, 36)
    let (local resource_4) = unpack_realm_data(realm_id, 42)
    let (local resource_5) = unpack_realm_data(realm_id, 48)
    let (local resource_6) = unpack_realm_data(realm_id, 54)
    let (local resource_7) = unpack_realm_data(realm_id, 60)

    # Populate struct.
    let realm_stats = RealmData(
        cities=cities,
        regions=regions,
        rivers=rivers,
        harbours=harbours,
        resource_1=resource_1,
        resource_2=resource_2,
        resource_3=resource_3,
        resource_4=resource_4,
        resource_5=resource_5,
        resource_6=resource_6,
        resource_7=resource_7                
        )
    return (realm_stats=realm_stats)
end
