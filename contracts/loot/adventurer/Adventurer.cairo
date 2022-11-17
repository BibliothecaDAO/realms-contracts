// -----------------------------------
//   Module.Adventurer
//   Adventurer logic
//
//
//
// -----------------------------------
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.3.2 (token/erc721/enumerable/presets/ERC721EnumerableMintableBurnable.cairo)

%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.math import unsigned_div_rem, assert_lt_felt
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.IERC721 import IERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.library.library_module import Module
from contracts.loot.adventurer.library import AdventurerLib
from contracts.loot.constants.adventurer import Adventurer, AdventurerState, PackedAdventurerState, AdventurerMode
from contracts.loot.interfaces.imodules import IModuleController
from contracts.loot.utils.general import _uint_to_felt

from contracts.loot.loot.ILoot import ILoot
from contracts.loot.utils.constants import ModuleIds, ExternalContractIds

// const MINT_COST = 5000000000000000000

// -----------------------------------
// Events
// -----------------------------------

@event
func NewAdventurerState(adventurer_id: Uint256, adveturer_state: AdventurerState) {
}

// -----------------------------------
// Storage
// -----------------------------------

@storage_var
func adventurer(tokenId: Uint256) -> (adventurer: PackedAdventurerState) {
}

// balance of $LORDS
@storage_var
func adventurer_balance(tokenId: Uint256) -> (balance: Uint256) {
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
    address_of_controller: felt,
) {
    // set as module
    Module.initializer(address_of_controller);

    // 721 setup
    ERC721.initializer(name, symbol);
    ERC721Enumerable.initializer();
    Proxy.initializer(proxy_admin);
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

// -----------------------------
// External Adventurer Specific
// -----------------------------

@external
func mint{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(to: felt, race: felt, home_realm: felt, name: felt, order: felt) {
    alloc_locals;

    let (controller) = Module.controller_address();
    let (caller) = get_caller_address();

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

    // mint
    ERC721Enumerable._mint(to, next_adventurer_id);

    // lords
    let (lords_address) = Module.get_external_contract_address(ExternalContractIds.Lords);

    // send to Nexus
    let (treasury) = Module.get_external_contract_address(ExternalContractIds.Treasury);

    // IERC20.transferFrom(lords_address, caller, treasury, Uint256(50 * 10 ** 18, 0));

    // send to this contract and set Balance of Adventurer
    let (this) = get_contract_address();
    // IERC20.transferFrom(lords_address, caller, this, Uint256(50 * 10 ** 18, 0));
    adventurer_balance.write(next_adventurer_id, Uint256(50 * 10 ** 18, 0));

    return ();
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
    let (loot_address) = Module.get_module_address(ModuleIds.Loot);

    // Get Item from Loot contract
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

    // Pack adventurer
    let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(equiped_adventurer);
    adventurer.write(tokenId, packed_new_adventurer);

    let (adventurer_to_felt) = _uint_to_felt(tokenId);

    // Update item
    ILoot.updateAdventurer(loot_address, itemTokenId, adventurer_to_felt);

    emit_adventurer_state(tokenId);

    return (1,);
}

@external
func unequipItem{
        pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(tokenId: Uint256, itemTokenId: Uint256) -> (success: felt) {
    alloc_locals;

    // only adventurer can unequip ofc
    ERC721.assert_only_token_owner(tokenId);

    // unpack adventurer
    let (unpacked_adventurer) = getAdventurerById(tokenId);

    // Get Item from Loot contract
    let (loot_address) = Module.get_module_address(ModuleIds.Loot);

    let (item) = ILoot.getItemByTokenId(loot_address, itemTokenId);

    assert item.Adventurer = tokenId.low;

    // Check item is owned by caller
    let (owner) = IERC721.ownerOf(loot_address, itemTokenId);
    let (caller) = get_caller_address();
    assert owner = caller;

    // Convert token to Felt
    let (token_to_felt) = _uint_to_felt(itemTokenId);

    // Unequip Item
    let (unequiped_adventurer) = AdventurerLib.unequip_item(item, unpacked_adventurer);

    // Pack adventurer
    let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(unequiped_adventurer);
    adventurer.write(tokenId, packed_new_adventurer);

    // Update item
    ILoot.updateAdventurer(loot_address, itemTokenId, 0);

    emit_adventurer_state(tokenId);

    return (1,);
}

@external
func deductHealth{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(tokenId: Uint256, amount: felt) -> (success: felt) {
    alloc_locals;

    Module.only_approved();
    // ERC721.assert_only_token_owner(tokenId);

    // unpack adventurer
    let (unpacked_adventurer) = getAdventurerById(tokenId);

    // deduct health
    let (equiped_adventurer) = AdventurerLib.deduct_health(amount, unpacked_adventurer);

    // TODO: Move to function that emits adventurers state
    let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(equiped_adventurer);
    adventurer.write(tokenId, packed_new_adventurer);

    // Get new adventurer
    emit_adventurer_state(tokenId);

    return (1,);
}

// -----------------------------
// Internal Adventurer Specific
// -----------------------------

func emit_adventurer_state{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(tokenId: Uint256) {
    // Get new adventurer
    let (new_adventurer) = getAdventurerById(tokenId);

    NewAdventurerState.emit(tokenId, new_adventurer);

    return ();
}

// --------------------
// Getters
// --------------------

@view
func getAdventurerById{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(tokenId: Uint256) -> (adventurer: AdventurerState) {
    alloc_locals;

    let (packed_adventurer) = adventurer.read(tokenId);

    // unpack
    let (unpacked_adventurer: AdventurerState) = AdventurerLib.unpack(packed_adventurer);

    return (unpacked_adventurer,);
}

// Checks if dead
// Might be better as an assert....
@external
func is_dead{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(tokenId: Uint256) -> (is_dead: felt) {
    let (adventurer: AdventurerState) = getAdventurerById(tokenId);

    if (adventurer.Health == 0) {
        return (is_dead=TRUE);
    }

    return (is_dead=FALSE);
}

// --------------------
// Base ERC721 Functions
// --------------------

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
