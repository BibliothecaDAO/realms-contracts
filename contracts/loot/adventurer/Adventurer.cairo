// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.3.2 (token/erc721/enumerable/presets/ERC721EnumerableMintableBurnable.cairo)

%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.math import unsigned_div_rem, assert_lt_felt
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.IERC721 import IERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.upgrades.library import Proxy

from contracts.loot.adventurer.library import AdventurerLib
from contracts.loot.constants.adventurer import Adventurer, AdventurerState, PackedAdventurerState
from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro

from contracts.loot.loot.ILoot import ILoot

// const MINT_COST = 5000000000000000000

// -----------------------------------
// Storage
// -----------------------------------

@storage_var
func xoroshiro_address() -> (address: felt) {
}

@storage_var
func item_address() -> (address: felt) {
}

@storage_var
func bag_address() -> (address: felt) {
}

@storage_var
func lords_address() -> (address: felt) {
}

// -----------------------------------
// Initialize & upgrade
// -----------------------------------

// @notice Module initializer
// @param address_of_controller: Controller/arbiter address
// @return proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt,
    symbol: felt,
    proxy_admin: felt,
    xoroshiro_address_: felt,
    item_address_: felt,
    bag_address_: felt,
    lords_address_: felt,
) {
    ERC721.initializer(name, symbol);
    ERC721Enumerable.initializer();
    Proxy.initializer(proxy_admin);

    // contracts
    xoroshiro_address.write(xoroshiro_address_);
    item_address.write(item_address_);
    bag_address.write(bag_address_);
    lords_address.write(lords_address_);
    return ();
}

// @notice Set new proxy implementation
// @dev Can only be set by the arbiter
// @param new_implementation: New implementation contract address
@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}

//
// Getters
//

@view
func totalSupply{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (totalSupply: Uint256) = ERC721Enumerable.total_supply();
    return (totalSupply,);
}

@view
func tokenByIndex{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    index: Uint256
) -> (tokenId: Uint256) {
    let (tokenId: Uint256) = ERC721Enumerable.token_by_index(index);
    return (tokenId,);
}

@view
func tokenOfOwnerByIndex{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, index: Uint256
) -> (tokenId: Uint256) {
    let (tokenId: Uint256) = ERC721Enumerable.token_of_owner_by_index(owner, index);
    return (tokenId,);
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    let (success) = ERC165.supports_interface(interfaceId);
    return (success,);
}

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    let (name) = ERC721.name();
    return (name,);
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    let (symbol) = ERC721.symbol();
    return (symbol,);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    let (balance: Uint256) = ERC721.balance_of(owner);
    return (balance,);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    owner: felt
) {
    let (owner: felt) = ERC721.owner_of(tokenId);
    return (owner,);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (approved: felt) {
    let (approved: felt) = ERC721.get_approved(tokenId);
    return (approved,);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (isApproved: felt) {
    let (isApproved: felt) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved,);
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (tokenURI: felt) {
    let (tokenURI: felt) = ERC721.token_uri(tokenId);
    return (tokenURI,);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    let (owner: felt) = Ownable.owner();
    return (owner,);
}

//
// Externals
//

@external
func approve{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    ERC721.approve(to, tokenId);
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    ERC721.set_approval_for_all(operator, approved);
    return ();
}

// @external
// func transferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
//     from_ : felt, to : felt, tokenId : Uint256
// ):
//     ERC721Enumerable.transfer_from(from_, to, tokenId)
//     return ()
// end

// @external
// func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
//     from_ : felt, to : felt, tokenId : Uint256, data_len : felt, data : felt*
// ):
//     ERC721Enumerable.safe_transfer_from(from_, to, tokenId, data_len, data)
//     return ()
// end

@external
func burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(tokenId: Uint256) {
    ERC721.assert_only_token_owner(tokenId);
    ERC721Enumerable._burn(tokenId);
    return ();
}

@external
func setTokenURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    tokenId: Uint256, tokenURI: felt
) {
    Ownable.assert_only_owner();
    ERC721._set_token_uri(tokenId, tokenURI);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.renounce_ownership();
    return ();
}

// ------------ADVENTURERS

@storage_var
func adventurer(tokenId: Uint256) -> (adventurer: PackedAdventurerState) {
}

@external
func mint{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(to: felt, race: felt, home_realm: felt, name: felt, order: felt) {
    alloc_locals;

    // birth
    let (birth_time) = get_block_timestamp();
    let (new_adventurer: AdventurerState) = AdventurerLib.birth(
        race, home_realm, name, birth_time, order
    );

    // pack
    let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(new_adventurer);

    // get current ID and add 1
    let (current_id: Uint256) = totalSupply();
    let (next_adventurer_id, _) = uint256_add(current_id, Uint256(1, 0));

    // store
    adventurer.write(next_adventurer_id, packed_new_adventurer);

    ERC721Enumerable._mint(to, next_adventurer_id);

    return ();
}

@external
func set_xoroshiro{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    xoroshiro: felt
) {
    Proxy.assert_only_admin();
    xoroshiro_address.write(xoroshiro);
    return ();
}

@view
func get_xoroshiro{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt
) {
    return xoroshiro_address.read();
}

@external
func set_lords{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(lords: felt) {
    Proxy.assert_only_admin();
    lords_address.write(lords);
    return ();
}

@view
func get_lords{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt
) {
    return lords_address.read();
}

@external
func set_loot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(loot: felt) {
    Proxy.assert_only_admin();
    lords_address.write(loot);
    return ();
}

@view
func get_loot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt
) {
    return item_address.read();
}

@external
func getAdventurerById{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(tokenId: Uint256) -> (adventurer: AdventurerState) {
    alloc_locals;

    let (packed_adventurer) = adventurer.read(tokenId);

    // unpack
    let (unpacked_adventurer: AdventurerState) = AdventurerLib.unpack(packed_adventurer);

    return (unpacked_adventurer,);
}

@external
func equipItem{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(tokenId: Uint256, itemTokenId: Uint256) -> (success: felt) {
    alloc_locals;

    // only adventurer can equip ofc
    ERC721.assert_only_token_owner(tokenId);

    // unpack adventurer
    let (unpacked_adventurer) = getAdventurerById(tokenId);

    // Get Item from Loot contract
    let (loot_address) = get_loot();
    let (item) = ILoot.getItemByTokenId(loot_address, itemTokenId);

    assert item.Adventurer = 0;
    assert item.Bag = 0;

    // Check item is owned by caller
    let (owner) = IERC721.ownerOf(loot_address, itemTokenId);
    let (caller) = get_caller_address();
    assert owner = caller;

    // Convert token to Felt
    let (token_to_felt) = _uint_to_felt(itemTokenId);

    // Equip Item
    let (equiped_adventurer) = AdventurerLib.equip_item(token_to_felt, item, unpacked_adventurer);

    // TODO: Move to function that emits adventurers state
    let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(equiped_adventurer);
    adventurer.write(tokenId, packed_new_adventurer);

    let (adventurer_to_felt) = _uint_to_felt(tokenId);

    // update state
    ILoot.updateAdventurer(loot_address, itemTokenId, adventurer_to_felt);

    return (1,);
}

// TODO: Move to Utils
func _uint_to_felt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    value: Uint256
) -> (value: felt) {
    assert_lt_felt(value.high, 2 ** 123);
    return (value.high * (2 ** 128) + value.low,);
}
