// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.3.2 (token/erc721/enumerable/presets/ERC721EnumerableMintableBurnable.cairo)

%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import unsigned_div_rem

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.upgrades.library import Proxy

from contracts.loot.constants.item import Item, ItemIds
from contracts.loot.interfaces.imodules import IModuleController
from contracts.loot.loot.library import ItemLib
from contracts.loot.loot.metadata import LootUri
from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro
from contracts.settling_game.library.library_module import Module
from contracts.loot.loot.stats.combat import CombatStats

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    get_tx_info,
    get_contract_address,
)

from contracts.loot.loot.stats.item import ItemStats
from contracts.loot.utils.constants import ModuleIds, ExternalContractIds

// -----------------------------------
// Events
// -----------------------------------

@event
func ItemXPIncrease(item_token_id: Uint256, item: Item) {
}

@event
func ItemGreatnessIncrease(item_token_id: Uint256, item: Item) {
}

// -----------------------------------
// Storage
// -----------------------------------

@storage_var
func counter() -> (count: felt) {
}
// -----------------------------------
// Initialize & upgrade
// -----------------------------------

// @notice Module initializer
// @param address_of_controller: Controller/arbiter address
// @return proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt, address_of_controller: felt, proxy_admin: felt
) {
    Module.initializer(address_of_controller);
    ERC721.initializer(name, symbol);
    ERC721Enumerable.initializer();
    Ownable.initializer(proxy_admin);
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
) -> (tokenURI_len: felt, tokenURI: felt*) {
    alloc_locals;
    let (controller) = Module.controller_address();
    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);
    let (item_data) = get_item_by_token_id(tokenId);
    let (tokenURI_len, tokenURI: felt*) = LootUri.build(tokenId, item_data, adventurer_address);
    return (tokenURI_len, tokenURI);
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

@external
func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256
) {
    ERC721Enumerable.transfer_from(from_, to, tokenId);
    return ();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    ERC721Enumerable.safe_transfer_from(from_, to, tokenId, data_len, data);
    return ();
}

@external
func burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(tokenId: Uint256) {
    ERC721.assert_only_token_owner(tokenId);
    ERC721Enumerable._burn(tokenId);
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

@storage_var
func item(tokenId: Uint256) -> (item: Item) {
}

@storage_var
func adventurer_owner(tokenId: Uint256) -> (adventurer_token_id: Uint256) {
}

// -----------------------------
// External Loot Specific
// -----------------------------

// @notice Mint random item
// @param to: Address to mint the item to
@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, adventurer_token_id: Uint256
) {
    alloc_locals;

    // // Only LootMarketArcade and Adventurer
    // Module.only_approved();

    // fetch new item with random Id
    let (rnd) = get_random_number();
    let (new_item: Item) = ItemLib.generate_random_item(rnd);

    let (next_id) = counter.read();

    item.write(Uint256(next_id + 1, 0), new_item);

    adventurer_owner.write(Uint256(next_id + 1, 0), adventurer_token_id);

    ERC721Enumerable._mint(to, Uint256(next_id + 1, 0));

    counter.write(next_id + 1);
    return ();
}

// @notice Mint adventurer starting weapon
// @param to: Address to mint the item to
// @param weapon_id: Weapon ID to mint
// @return item_token_id: The token id of the minted item
@external
func mint_starter_weapon{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, weapon_id: felt, adventurer_token_id: Uint256
) -> (item_token_id: Uint256) {
    alloc_locals;

    Module.only_approved();

    assert_starter_weapon(weapon_id);

    // fetch new item with random Id
    let (new_item: Item) = ItemLib.generate_starter_weapon(weapon_id);

    let (next_id) = counter.read();

    item.write(Uint256(next_id + 1, 0), new_item);

    adventurer_owner.write(Uint256(next_id + 1, 0), adventurer_token_id);

    ERC721Enumerable._mint(to, Uint256(next_id + 1, 0));

    counter.write(next_id + 1);

    return (Uint256(next_id + 1, 0),);
}

// @notice Update item adventurer
// @param tokenId: Id of loot item
// @param adventurerId: Id of adventurer
@external
func update_adventurer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256, adventurerId: felt
) {
    Module.only_approved();
    let (item_: Item) = item.read(tokenId);

    let updated_item = ItemLib.update_adventurer(item_, adventurerId);

    item.write(tokenId, updated_item);
    return ();
}

// @notice Update item xp
// @param tokenId: Id of loot item
// @param xp: Amount of xp to update
@external
func update_xp{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256, xp: felt
) {
    Module.only_approved();
    let (item_: Item) = item.read(tokenId);

    let updated_item = ItemLib.update_xp(item_, xp);

    item.write(tokenId, updated_item);
    return ();
}

// @notice Set loot item data by id
// @param tokenId: Id of loot item
// @param item_: Data of loot item
@external
func set_item_by_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256, item_id: felt, greatness: felt, xp: felt, adventurer: felt, bag_id: felt
) {
    alloc_locals;
    Ownable.assert_only_owner();
    let (item_) = ItemLib.set_item(item_id, greatness, xp, adventurer, bag_id);
    item.write(tokenId, item_);
    return ();
}

// @notice Increase xp of an item
// @param item_token_id: Id of the item
// @param amount: Amount of xp to increase
// @return success: Value indicating success
@external
func increase_xp{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    item_token_id: Uint256, amount: felt
) -> (success: felt) {
    alloc_locals;

    // Only approved modules can increase and items xp
    Module.only_approved();

    // call internal function for updating xp
    let (result) = _increase_xp(item_token_id, amount);

    // return result
    return (result,);
}

// -----------------------------
// Internal Loot Specific
// -----------------------------

// @notice Asserts that the weapon is a starter weapon
// @param weapon_id: Id of loot weapon
func assert_starter_weapon{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
    weapon_id: felt
) {
    // book, wand, club, or short sword
    if (weapon_id == ItemIds.Book) {
        return ();
    }
    if (weapon_id == ItemIds.Wand) {
        return ();
    }
    if (weapon_id == ItemIds.Club) {
        return ();
    }
    if (weapon_id == ItemIds.ShortSword) {
        return ();
    }
    with_attr error_message("Loot: Item is not a starter weapon") {
        assert TRUE = FALSE;
    }
    return ();
}

// @notice Get xiroshiro random number
// @return dice_roll: Random number
@view
func get_random_number{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}() -> (
    dice_roll: felt
) {
    alloc_locals;

    let (controller) = Module.controller_address();
    let (xoroshiro_address_) = IModuleController.get_xoroshiro(controller);
    let (rnd) = IXoroshiro.next(xoroshiro_address_);
    return (rnd,);  // values from 1 to 101 inclusive
}

// --------------------
// Getters
// --------------------

// @notice Get item data by the token id
// @param tokenId: Id of the item token
// @return item: Item data
@view
func get_item_by_token_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (item: Item) {
    let (item_: Item) = item.read(tokenId);

    return (item_,);
}

// @notice Get adventurer owner
// @param tokenId: Id of the item token
// @return adventurer_token_id: Id of the adventurer
@view
func get_adventurer_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (adventurer_token_id: Uint256) {
    let (adventurer_token_id) = adventurer_owner.read(tokenId);

    return (adventurer_token_id,);
}

// @notice Increases the "XP" attribute of an item, represented by its unique token ID, by a specified amount.
// @dev This function updates the XP of the specified item and writes the updated item to the blockchain.
//      If the XP increase results in a level increase (i.e. the item's "greatness" attribute is increased),
//      the function also increases the item's greatness attribute and writes the updated item to the blockchain.
// @param item_token_id Unique token ID of the item to be updated.
// @param amount The amount by which to increase the item's "XP" attribute.
// @return success Boolean value indicating whether the function succeeded.
func _increase_xp{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
    item_token_id: Uint256, amount: felt
) -> (success: felt) {
    alloc_locals;

    // get item
    let (_item) = get_item_by_token_id(item_token_id);

    // increase xp
    let item_updated_xp = ItemLib.update_xp(_item, amount);

    // check if item received a greatness increase
    let (greatness_increased) = CombatStats.check_for_level_increase(
        item_updated_xp.XP, item_updated_xp.Greatness
    );

    // if greatness increased
    if (greatness_increased == TRUE) {
        // increase greatness
        let (result) = _increase_greatness(item_token_id, item_updated_xp.Greatness + 1);
        return (result,);
    } else {
        // if greatness did not increase, we we still update XP
        item.write(item_token_id, item_updated_xp);

        // and emit an XP increase event
        emit_item_xp_increase(item_token_id);

        // return success
        return (TRUE,);
    }
}

// @notice Increases the "greatness" attribute of an item, represented by its unique token ID, by a specified amount.
// @dev This function updates the greatness of the specified item and writes the updated item to the blockchain.
// @param item_token_id Unique token ID of the item to be updated.
// @param greatness The amount by which to increase the item's "greatness" attribute.
// @return success Boolean value indicating whether the function succeeded.
func _increase_greatness{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
    item_token_id: Uint256, greatness: felt
) -> (success: felt) {
    alloc_locals;

    // get item
    let (_item) = get_item_by_token_id(item_token_id);

    // update greatness
    let item_updated_greatness = ItemLib.update_greatness(_item, greatness);

    // write to blockchain
    item.write(item_token_id, item_updated_greatness);

    // emit greatness increase event
    emit_item_greatness_increase(item_token_id);

    // return success
    return (TRUE,);
}

// @notice Emits a greatness increase event for an item
// @param item_token_id: the token id of the item that increased in greatness
func emit_item_greatness_increase{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
    item_token_id: Uint256
) {
    // Get item from token id
    let (item) = get_item_by_token_id(item_token_id);
    // emit leveled up event
    ItemGreatnessIncrease.emit(item_token_id, item);
    return ();
}

// @notice Emits an xp increase event for an item
// @param item_token_id: the token id of the item whose xp increased
func emit_item_xp_increase{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
    item_token_id: Uint256
) {
    // Get item from token id
    let (item) = get_item_by_token_id(item_token_id);
    // emit leveled up event
    ItemXPIncrease.emit(item_token_id, item);
    return ();
}
