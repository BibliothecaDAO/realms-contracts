// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.3.2 (token/erc721/enumerable/presets/ERC721EnumerableMintableBurnable.cairo)

%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import unsigned_div_rem

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.upgrades.library import Proxy

from contracts.loot.constants.item import Item
from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    get_tx_info,
    get_contract_address,
)

from contracts.loot.loot.stats.item import ItemStats

// -----------------------------------
// Storage
// -----------------------------------

@storage_var
func xoroshiro_address() -> (address: felt) {
}

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
    name: felt, symbol: felt, proxy_admin: felt, xoroshiro_address_: felt
) {
    ERC721.initializer(name, symbol);
    ERC721Enumerable.initializer();
    Proxy.initializer(proxy_admin);
    xoroshiro_address.write(xoroshiro_address_);
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

@storage_var
func item(tokenId: Uint256) -> (item: Item) {
}

@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(to: felt) {
    alloc_locals;

    // fetch new item with random Id
    let (new_item: Item) = generateRandomItem();

    let (next_id) = counter.read();

    item.write(Uint256(next_id, 0), new_item);

    ERC721Enumerable._mint(to, Uint256(next_id, 0));

    counter.write(next_id + 1);
    return ();
}

// ------------new

@view
func getItemByTokenId{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (item: Item) {
    let (storedItem: Item) = item.read(tokenId);

    let Id = storedItem.Id;
    let (Slot) = ItemStats.item_slot(storedItem.Id);  // determined by Id
    let (Type) = ItemStats.item_type(storedItem.Id);  // determined by Id
    let (Material) = ItemStats.item_material(storedItem.Id);  // determined by Id
    let (Rank) = ItemStats.item_rank(storedItem.Id);  // stored state
    let (Prefix_1) = ItemStats.item_name_prefix(1);  // stored state
    let (Prefix_2) = ItemStats.item_name_suffix(1);  // stored state
    let (Suffix) = ItemStats.item_suffix(1);  // stored state
    let Greatness = 0;  // stored state
    let CreatedBlock = storedItem.CreatedBlock;  // timestamp
    let XP = 0;  // stored state
    let Adventurer = 0;
    let Bag = 0;

    return (
        Item(
        Id=Id,
        Slot=Slot,
        Type=Type,
        Material=Material,
        Rank=Rank,
        Prefix_1=Prefix_1,
        Prefix_2=Prefix_2,
        Suffix=Suffix,
        Greatness=Greatness,
        CreatedBlock=CreatedBlock,
        XP=XP,
        Adventurer=Adventurer,
        Bag=Bag
        ),
    );
}

// TODO: Unequip Item

@external
func updateAdventurer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256, adventurerId: felt
) {
    // TODO: Only allow calling by Adventurer Contract
    let (item_: Item) = item.read(tokenId);

    // TODO: Move library
    let update_item = Item(
        Id=item_.Id,
        Slot=item_.Slot,
        Type=item_.Type,
        Material=item_.Material,
        Rank=item_.Rank,
        Prefix_1=item_.Prefix_1,
        Prefix_2=item_.Prefix_2,
        Suffix=item_.Suffix,
        Greatness=item_.Greatness,
        CreatedBlock=item_.CreatedBlock,
        XP=item_.XP,
        Adventurer=adventurerId,
        Bag=item_.Bag,
    );

    setItemById(tokenId, update_item);
    return ();
}

@external
func setItemById{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256, item_: Item
) {
    // TODO: Security
    item.write(tokenId, item_);
    return ();
}

func generateRandomItem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    item: Item
) {
    // set blank item
    let (Id) = roll_dice();
    let Slot = 0;  // determined by Id
    let Type = 0;  // determined by Id
    let Material = 0;  // determined by Id
    let Rank = 0;  // stored state
    let Prefix_1 = 0;  // stored state
    let Prefix_2 = 0;  // stored state
    let Suffix = 0;  // stored state
    let Greatness = 0;  // stored state
    let (CreatedBlock) = get_block_timestamp();  // timestamp
    let XP = 0;  // stored state
    let Adventurer = 0;
    let Bag = 0;

    return (
        Item(
        Id=Id,
        Slot=Slot,
        Type=Type,
        Material=Material,
        Rank=Rank,
        Prefix_1=Prefix_1,
        Prefix_2=Prefix_2,
        Suffix=Suffix,
        Greatness=Greatness,
        CreatedBlock=CreatedBlock,
        XP=XP,
        Adventurer=Adventurer,
        Bag=Bag
        ),
    );
}

@external
func set_xoroshiro{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    xoroshiro: felt
) {
    // TODO:
    Proxy.assert_only_admin();
    xoroshiro_address.write(xoroshiro);
    return ();
}

@view
func get_xoroshiro{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (x: felt) {
    let (xoroshiro) = xoroshiro_address.read();
    return (xoroshiro,);
}

func roll_dice{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}() -> (
    dice_roll: felt
) {
    alloc_locals;
    let (xoroshiro_address_) = xoroshiro_address.read();
    let (rnd) = IXoroshiro.next(xoroshiro_address_);

    // useful for testing:
    // local rnd
    // %{
    //     import random
    //     ids.rnd = random.randint(0, 5000)
    // %}
    let (_, r) = unsigned_div_rem(rnd, 101);
    return (r + 1,);  // values from 1 to 101 inclusive
}
