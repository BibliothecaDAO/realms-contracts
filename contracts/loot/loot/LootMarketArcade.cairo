// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.3.2 (token/erc721/enumerable/presets/ERC721EnumerableMintableBurnable.cairo)

%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le_felt, is_le
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.upgrades.library import Proxy
from starkware.cairo.common.bool import TRUE, FALSE
from contracts.loot.constants.item import Item
from contracts.loot.interfaces.imodules import IModuleController
from contracts.loot.loot.library import ItemLib
from contracts.loot.loot.metadata import LootUri
from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro
from contracts.settling_game.library.library_module import Module
from contracts.loot.beast.interface import IBeast

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    get_tx_info,
    get_contract_address,
)

from contracts.loot.loot.stats.item import ItemStats
from contracts.loot.utils.constants import ModuleIds, ExternalContractIds

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
    let (item_data) = getItemByTokenId(tokenId);
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
    // TODO: can only be called by ItemContract/AdventurerContract/BeastContract
    ERC721Enumerable.transfer_from(from_, to, tokenId);
    return ();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    // TODO: can only be called by ItemContract/AdventurerContract/BeastContract
    ERC721Enumerable.safe_transfer_from(from_, to, tokenId, data_len, data);
    return ();
}

@external
func burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(tokenId: Uint256) {
    // TODO: can only be called by ItemContract/AdventurerContract/BeastContract
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
    let (new_item: Item) = ItemLib.generate_random_item(rnd);

    let (next_id) = counter.read();

    item.write(Uint256(next_id + 1, 0), new_item);

    ERC721Enumerable._mint(to, Uint256(next_id + 1, 0));

    item_adventurer_owner.write(Uint256(next_id + 1, 0), adventurer_token_id, TRUE);

    counter.write(next_id + 1);
    return ();
}

func mintFromMart{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, item_id: felt, adventurer_token_id: Uint256
) {
    alloc_locals;

    let (new_item: Item) = ItemLib.generate_item_by_id(item_id);

    let (next_id) = counter.read();

    item.write(Uint256(next_id + 1, 0), new_item);

    ERC721Enumerable._mint(to, Uint256(next_id + 1, 0));

    item_adventurer_owner.write(Uint256(next_id + 1, 0), adventurer_token_id, TRUE);

    counter.write(next_id + 1);

    return ();
}

// @notice Update item adventurer
// @param tokenId: Id of loot item
// @param adventurerId: Id of adventurer
@external
func updateAdventurer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
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
func updateXP{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
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
func setItemById{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256, item_id: felt, greatness: felt, xp: felt, adventurer: felt, bag_id: felt
) {
    alloc_locals;
    Ownable.assert_only_owner();
    let (item_) = ItemLib.set_item(item_id, greatness, xp, adventurer, bag_id);
    item.write(tokenId, item_);
    return ();
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

// --------------------
// Getters
// --------------------

// @notice Get item data by the token id
// @param tokenId: Id of the item token
// @return item: Item data
@view
func getItemByTokenId{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (item: Item) {
    let (item_: Item) = item.read(tokenId);

    return (item_,);
}

// --------------------
// Market
// --------------------

// @notice Mint adventurer starting weapon
// @param to: Address to mint the item to
// @param weapon_id: Weapon ID to mint
// @return item_token_id: The token id of the minted item
@external
func mintStarterWeapon{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, weapon_id: felt, adventurer_token_id: Uint256
) -> (item_token_id: Uint256) {
    alloc_locals;

    // TODO: Assert the weapon_id is book, wand, club, or short sword

    // fetch new item with random Id
    let (new_item: Item) = ItemLib.generate_starter_weapon(weapon_id);

    let (next_id) = counter.read();

    item.write(Uint256(next_id + 1, 0), new_item);

    ERC721Enumerable._mint(to, Uint256(next_id + 1, 0));

    item_adventurer_owner.write(Uint256(next_id + 1, 0), adventurer_token_id, TRUE);

    counter.write(next_id + 1);

    return (Uint256(next_id + 1, 0),);
}

// This uses a Seed which is created every 12hrs. From this seed X number of items can be purchased
// after they have been bidded on.

namespace BidStatus {
    const closed = 0;
    const open = 1;
}

struct Bid {
    price: felt,
    expiry: felt,
    bidder: felt,
    status: felt,
}

@storage_var
func bid(tokenId: Uint256) -> (bid: Bid) {
}

@storage_var
func lastSeedTime() -> (number: felt) {
}

@storage_var
func mintSeed() -> (number: felt) {
}

// index
@storage_var
func mintIndex() -> (number: felt) {
}

@storage_var
func newItems() -> (number: felt) {
}

const HOUR = 3600;
const BID_TIME = 3600 * 2;  // 2 hours
const SHUFFLE_TIME = 3600 * 6;
const BASE_PRICE = 10;
const SEED_MULTI = 5846975;
const NUMBER_LOOT_ITEMS = 101;

@event
func ItemMerchantUpdate(item: Item, item_id: felt, bid: Bid) {
}

// returns TRUE if token is owned
@view
func itemOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256, adventurer_token_id: Uint256
) -> (owner: felt) {
    return item_adventurer_owner.read(tokenId, adventurer_token_id);
}

@external
func mintDailyItems{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    // check 12hrs has passed
    let (current_time) = get_block_timestamp();
    let (_lastSeedTime) = lastSeedTime.read();
    let is_past_tick = is_le(_lastSeedTime + SHUFFLE_TIME, current_time);
    with_attr error_message("Item Market: You cannot mint daily items yet...") {
        assert is_past_tick = TRUE;
    }

    // TODO: replace with curve according to gold
    let new_items = 20;

    // get current index
    let (current_index) = mintIndex.read();

    let new_index = current_index + new_items;

    let (random) = get_random_number();
    mintSeed.write(random);
    lastSeedTime.write(current_time);

    emitNewItemsLoop(random, new_index, current_index);

    // set new index
    mintIndex.write(new_index);

    // set number of items in this batch - this allows us to force people to only mint within the new item scope
    // eg: mint items only > mintIndex - new_items && < mintIndex
    // TODO: might be better way than this.
    newItems.write(new_items);

    // TODO: send 2 gold to the adventurer whoever calls this

    return ();
}

func emitNewItemsLoop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    daily_seed: felt, item_start_index_len: felt, item_start_index: felt
) -> (item_start_index_len: felt, item_start_index: felt) {
    if (item_start_index_len == item_start_index) {
        return (0, 0);
    }

    let (new_item: Item) = _getRandomItemFromSeed(item_start_index, daily_seed);

    ItemMerchantUpdate.emit(new_item, item_start_index, Bid(BASE_PRICE, 0, 0, 0));

    return emitNewItemsLoop(daily_seed, item_start_index_len - 1, item_start_index + 1);
}

@view
func getRandomItemFromSeed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    item_id: felt
) -> (item: Item) {
    let (seed) = mintSeed.read();

    return _getRandomItemFromSeed(item_id, seed);
}

func _getRandomItemFromSeed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    item_id: felt, daily_seed: felt
) -> (item: Item) {
    let (_, r) = unsigned_div_rem(daily_seed * item_id * SEED_MULTI, NUMBER_LOOT_ITEMS);

    let (new_item: Item) = ItemLib.generate_random_item(r);

    return ItemLib.generate_random_item(r);
}

@view
func viewBid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    bid: Bid
) {
    return bid.read(tokenId);
}

@view
func viewUnmintedItem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (item: Item, bid: Bid) {
    let (item) = getRandomItemFromSeed(tokenId.low);

    let (bid) = viewBid(tokenId);
    return (item, bid);
}

// @notice Allows a bidder to place a bid on an item. If no previous bids have been placed, the bid time will start from the current block timestamp plus the bid time duration. If a previous bid has been placed, the bidder must submit a higher bid within the bid time window of the previous bid.
// @param tokenId The ID of the item being bid on.
// @param price The amount of the bid.
// @param expiry The expiration time of the bid, after which the bidder will no longer be able to claim the item.
// @param bidder The address of the bidder.
// @dev Requires the item to be owned by the market contract and for the bid to be higher than the base price. The function will update the bid price and expiry time for the item.
@external
func bidOnItem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256, adventurer_token_id: Uint256, price: felt
) {
    alloc_locals;

    let (caller) = get_caller_address();
    let (current_time) = get_block_timestamp();
    let (this) = get_contract_address();

    // store the id not the Unit in the struct
    let adventurerIdAsFelt = adventurer_token_id.low;

    // TODO: check caller owner of Adventurer...
    // TODO: check adventurer is alive...

    // check higher than the base price that is set
    let higer_than_base_price = is_le(BASE_PRICE, price);
    with_attr error_message("Item Market: Your bid is not high enough") {
        assert higer_than_base_price = TRUE;
    }

    // read current bid
    let (current_bid) = bid.read(tokenId);

    // if current expiry = 0 means unbidded = set base time from now + BID_TIME
    if (current_bid.expiry == FALSE) {
        bid.write(tokenId, Bid(price, current_time + BID_TIME, adventurerIdAsFelt, BidStatus.open));
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

    // update bid state
    bid.write(tokenId, Bid(price, current_bid.expiry, adventurerIdAsFelt, BidStatus.open));

    let (beast_address) = Module.get_module_address(ModuleIds.Beast);

    // subtract gold balance from buyer
    IBeast.subtractFromBalance(beast_address, adventurer_token_id, price);

    if (current_bid.bidder == FALSE) {
    } else {
        IBeast.addToBalance(beast_address, Uint256(current_bid.bidder, 0), current_bid.price);
    }

    let (item) = getRandomItemFromSeed(tokenId.low);
    ItemMerchantUpdate.emit(
        item, tokenId.low, Bid(price, current_bid.expiry, adventurerIdAsFelt, BidStatus.open)
    );

    return ();
}
// @notice Allows a bidder to claim a previously placed bid on an item, provided the bid has expired and the item is still available.
// @param item_id The ID of the item being claimed.
// @dev Requires the caller to be the bidder who previously placed the bid. The function will also mint a token representing the claimed item for the caller and update the bid status to "closed".
@external
func claimItem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    item_id: Uint256, adventurer_token_id: Uint256
) {
    alloc_locals;
    let (caller) = get_caller_address();
    let (current_time) = get_block_timestamp();

    let (current_bid) = bid.read(item_id);

    // check bid has expired + item is still available
    let expired = is_le(current_bid.expiry, current_time);
    with_attr error_message("Item Market: Item not available") {
        assert current_bid.status = BidStatus.open;
        assert expired = TRUE;
    }

    with_attr error_message("Item Market: Caller not bidder!") {
        assert current_bid.bidder = caller;
    }

    mintFromMart(caller, item_id.low, adventurer_token_id);

    bid.write(item_id, Bid(current_bid.price, 0, adventurer_token_id.low, BidStatus.closed));

    return ();
}
