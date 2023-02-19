// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.3.2 (token/erc721/enumerable/presets/ERC721EnumerableMintableBurnable.cairo)

%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_eq
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_le_felt, is_le, is_not_zero
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.upgrades.library import Proxy
from starkware.cairo.common.bool import TRUE, FALSE
from contracts.loot.constants.adventurer import AdventurerState
from contracts.loot.constants.item import Item, ItemIds
from contracts.loot.interfaces.imodules import IModuleController
from contracts.loot.loot.library import ItemLib
from contracts.loot.loot.metadata import LootUri
from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro
from contracts.settling_game.library.library_module import Module
from contracts.loot.beast.interface import IBeast
from contracts.loot.loot.stats.combat import CombatStats

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    get_tx_info,
    get_contract_address,
)

from contracts.loot.loot.stats.item import ItemStats
from contracts.loot.utils.constants import ModuleIds, ExternalContractIds, STARTING_GOLD
from contracts.loot.adventurer.interface import IAdventurer
from openzeppelin.token.erc721.IERC721 import IERC721

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
    // can only be called by ItemContract/AdventurerContract/BeastContract
    Module.only_approved();
    ERC721Enumerable.transfer_from(from_, to, tokenId);
    return ();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    // can only be called by ItemContract/AdventurerContract/BeastContract
    Module.only_approved();
    ERC721Enumerable.safe_transfer_from(from_, to, tokenId, data_len, data);
    return ();
}

@external
func burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(tokenId: Uint256) {
    // can only be called by ItemContract/AdventurerContract/BeastContract
    Module.only_approved();
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

// Adventurers OWN the Loot items - they cannot transfer them.
@storage_var
func item_adventurer_owner(tokenId: Uint256, adventurerId: Uint256) -> (owner: felt) {
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
    Module.only_approved();

    // fetch new item with random Id
    let (rnd) = get_random_number();
    let (ts) = get_block_timestamp();
    let (new_item: Item) = ItemLib.generate_random_item(rnd * ts);

    let (id) = _mint(to, new_item, adventurer_token_id);

    return ();
}

@external
func mint_from_mart{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, item_id: felt, adventurer_token_id: Uint256
) {
    alloc_locals;

    let (new_item: Item) = ItemLib.generate_item_by_id(item_id);

    let (id) = _mint(to, new_item, adventurer_token_id);

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

    assert_starter_weapon(weapon_id);

    // fetch new item with random Id
    let (new_item: Item) = ItemLib.generate_starter_weapon(weapon_id);

    return _mint(to, new_item, adventurer_token_id);
}

func _mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, _item: Item, adventurer_token_id: Uint256
) -> (item_token_id: Uint256) {
    alloc_locals;

    let (current_id: Uint256) = totalSupply();
    let (next_item_id, _) = uint256_add(current_id, Uint256(1, 0));

    item.write(next_item_id, _item);

    ERC721Enumerable._mint(to, next_item_id);

    item_adventurer_owner.write(next_item_id, adventurer_token_id, TRUE);

    return (next_item_id,);
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

// --------------------
// Market
// --------------------


// This uses a Seed which is created every 12hrs. From this seed X number of items can be purchased
// after they have been bidded on.

// tokenId = ERC721 TokenId
// market_item_id = Market item id - these only exist in the Market listings - they are not actual item ids or token ids.

namespace BidStatus {
    const closed = 0;
    const open = 1;
}

struct Bid {
    price: felt,
    expiry: felt,
    bidder: felt,
    status: felt,
    item_id: felt,
}

@storage_var
func bid(market_item_id: Uint256) -> (bid: Bid) {
}

@storage_var
func last_seed_time() -> (number: felt) {
}

@storage_var
func mint_seed() -> (number: felt) {
}

// index
@storage_var
func mint_index() -> (number: felt) {
}

@storage_var
func new_items() -> (number: felt) {
}

const HOUR = 3600;
const BID_TIME = HOUR / 2;  // 2 hours
const SHUFFLE_TIME = 3600 * 6;
const BASE_PRICE = 3;
const SEED_MULTI = 5846975; // for psudeo randomness now
const NUMBER_LOOT_ITEMS = 101;
const MINIMUM_ITEMS_EMITTED = 20;
const ITEMS_PER_EPOCH_PER_ADVENTUER = 3;

@event
func ItemMerchantUpdate(item: Item, market_item_id: felt, bid: Bid) {
}

// returns TRUE if item is owned
@view
func item_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256, adventurer_token_id: Uint256
) -> (owner: felt) {
    return item_adventurer_owner.read(tokenId, adventurer_token_id);
}

@view
func get_mint_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (number: felt) {
    return mint_index.read();
}

@view
func get_new_items{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (number: felt) {
    return new_items.read();
}

@external
func mint_daily_items{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    // check 12hrs has passed
    let (current_time) = get_block_timestamp();
    let (_lastSeedTime) = last_seed_time.read();
    let is_past_tick = is_le(_lastSeedTime + SHUFFLE_TIME, current_time);
    with_attr error_message("Item Market: You cannot mint daily items yet...") {
        assert is_past_tick = TRUE;
    }

    let (beast_address) = Module.get_module_address(ModuleIds.Beast);
    let (world_gold_supply) = IBeast.get_world_supply(beast_address);

    let (relative_adventurers_in_world,_) = unsigned_div_rem(world_gold_supply, STARTING_GOLD);

    let less_than_minimum = is_le(relative_adventurers_in_world, MINIMUM_ITEMS_EMITTED);   
    if (less_than_minimum == TRUE) {
        tempvar _new_items = 20;
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar _new_items = relative_adventurers_in_world;
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    tempvar _new_items = _new_items;
     

    // get current index
    let (current_index) = mint_index.read();

    let new_index = current_index + _new_items;

    let (random) = get_random_number();
    mint_seed.write(random * current_time);

    last_seed_time.write(current_time);

    emit_new_items_loop(random, _new_items, current_index);

    // set new index
    mint_index.write(new_index);

    // set number of items in this batch - this allows us to force people to only mint within the new item scope
    // eg: mint items only > mintIndex - new_items && < mintIndex
    // TODO: might be better way than this.
    new_items.write(_new_items);

    // TODO: send 2 gold to the adventurer whoever calls this
    // let (caller) = get_caller_address();
    // IBeast.add_to_balance(beast_address, Uint256(2, 0), 2);

    return ();
}

func emit_new_items_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    daily_seed: felt, item_start_index_len: felt, item_start_index: felt
) -> (item_start_index_len: felt, item_start_index: felt) {
    // we loop over all new items
    if (item_start_index_len == 0) {
        return (0, 0);
    }

    let (new_item: Item) = _get_random_item_from_seed(item_start_index, daily_seed);

    ItemMerchantUpdate.emit(new_item, item_start_index, Bid(BASE_PRICE, 0, 0, 0, new_item.Id));

    return emit_new_items_loop(daily_seed, item_start_index_len - 1, item_start_index + 1);
}

@view
func get_random_item_from_seed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    market_item_id: felt
) -> (item: Item) {
    let (seed) = mint_seed.read();

    return _get_random_item_from_seed(market_item_id, seed);
}

func _get_random_item_from_seed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    market_item_id: felt, daily_seed: felt
) -> (item: Item) {
    let (_, r) = unsigned_div_rem(daily_seed * market_item_id * SEED_MULTI, NUMBER_LOOT_ITEMS);

    let (new_item: Item) = ItemLib.generate_random_item(r);

    return ItemLib.generate_random_item(r);
}

@view
func view_bid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(market_item_id: Uint256) -> (
    bid: Bid
) {
    return bid.read(market_item_id);
}

@view
func view_unminted_item{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    market_item_id: Uint256
) -> (item: Item, bid: Bid) {
    let (item) = get_random_item_from_seed(market_item_id.low);

    let (bid) = view_bid(market_item_id);
    return (item, bid);
}

// loop items by index

// @notice Allows a bidder to place a bid on an item. If no previous bids have been placed, the bid time will start from the current block timestamp plus the bid time duration. If a previous bid has been placed, the bidder must submit a higher bid within the bid time window of the previous bid.
// @param tokenId The ID of the item being bid on.
// @param price The amount of the bid.
// @param expiry The expiration time of the bid, after which the bidder will no longer be able to claim the item.
// @param bidder The address of the bidder.
// @dev Requires the item to be owned by the market contract and for the bid to be higher than the base price. The function will update the bid price and expiry time for the item.
@external
func bid_on_item{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    market_item_id: Uint256, adventurer_token_id: Uint256, price: felt
) {
    alloc_locals;

    let (caller) = get_caller_address();
    let (current_time) = get_block_timestamp();
    let (this) = get_contract_address();

    // store the id not the Unit in the struct
    let adventurer_id_as_felt = adventurer_token_id.low;

    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);
    let (owner) = IAdventurer.owner_of(adventurer_address, adventurer_token_id);
    with_attr error_message("Item Market: You do not own this Adventurer") { 
        assert caller = owner;
    }
    // check adventurer is alive
    let (adventurer: AdventurerState) = IAdventurer.get_adventurer_by_id(adventurer_address, adventurer_token_id);

    with_attr error_message("Adventurer: Adventurer is dead") {
        assert_not_zero(adventurer.Health);
    }

    // check higher than the base price that is set
    let higer_than_base_price = is_le(BASE_PRICE, price);
    with_attr error_message("Item Market: Your bid is not high enough") {
        assert higer_than_base_price = TRUE;
    }

    let (item) = get_random_item_from_seed(market_item_id.low);

    // read current bid
    let (current_bid) = bid.read(market_item_id);

    // if current expiry = 0 means unbidded = set base time from now + BID_TIME
    if (current_bid.expiry == FALSE) {
        bid.write(market_item_id, Bid(price, current_time + BID_TIME, adventurer_id_as_felt, BidStatus.open, item.Id));
        return ();
    }

    // check higher than the last bid price
    let higher_price = is_le(price, current_bid.price);
    with_attr error_message("Item Market: Your bid is not high enough") {
        assert higher_price = TRUE;
    }

    // check bid time not expired
    let not_expired = is_le(current_bid.expiry, current_time);
    with_attr error_message("Item Market: Bid has expired") {
        assert not_expired = TRUE;
    }

    assert_can_purchase(market_item_id.low);

    // update bid state
    bid.write(market_item_id, Bid(price, current_bid.expiry, adventurer_id_as_felt, BidStatus.open, item.Id));

    let (beast_address) = Module.get_module_address(ModuleIds.Beast);

    // subtract gold balance from buyer

    IBeast.subtract_from_balance(beast_address, adventurer_token_id, price);

    let has_bid = is_not_zero(current_bid.bidder);

    if (has_bid == TRUE) {
        IBeast.add_to_balance(beast_address, Uint256(current_bid.bidder, 0), current_bid.price);
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }


    ItemMerchantUpdate.emit(
        item, market_item_id.low, Bid(price, current_bid.expiry, adventurer_id_as_felt, BidStatus.open, item.Id)
    );

    return ();
}
// @notice Allows a bidder to claim a previously placed bid on an item, provided the bid has expired and the item is still available.
// @param item_id The ID of the item being claimed.
// @dev Requires the caller to be the bidder who previously placed the bid. The function will also mint a token representing the claimed item for the caller and update the bid status to "closed".
@external
func claim_item{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    market_item_id: Uint256, adventurer_token_id: Uint256
) {
    alloc_locals;

    let (caller) = get_caller_address();
    // ownly owner of Adventurer can call
    // TODO: we could open this to anyone to call so bids can be cleared by helper accounts...
    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);
    let (owner) = IAdventurer.owner_of(adventurer_address, adventurer_token_id);
    with_attr error_message("Item Market: You do not own this Adventurer") {
        assert caller = owner;
    }

    let (current_time) = get_block_timestamp();

    let (current_bid) = bid.read(market_item_id);

    // check bid has expired + item is still available
    let expired = is_le(current_bid.expiry, current_time);
    with_attr error_message("Item Market: Item not available") {
        assert current_bid.status = BidStatus.open;
        assert expired = TRUE;
    }

    with_attr error_message("Item Market: Caller not bidder!") {
        assert current_bid.bidder = adventurer_token_id.low;
    }

    // we pass in the current_bid.item_id
    mint_from_mart(caller, current_bid.item_id, adventurer_token_id);

    // this could be optimised
    bid.write(market_item_id, Bid(current_bid.price, 0, adventurer_token_id.low, BidStatus.closed, current_bid.item_id));

    return ();
}

func assert_can_purchase{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    market_item_id: felt
) {

    let (start_index) = mint_index.read();

    let (current_items) = new_items.read();

    let above_start_index = is_le(start_index, market_item_id);

    let below_end_index = is_le(market_item_id, start_index + current_items);

    with_attr error_message("Item Market: Item not available anymore") {
        assert above_start_index = TRUE;
        assert below_end_index = TRUE;
    }

    return ();
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