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
from starkware.cairo.common.math import unsigned_div_rem, assert_not_equal, assert_not_zero
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.IERC721 import IERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro
from contracts.settling_game.library.library_module import Module
from contracts.loot.adventurer.library import AdventurerLib
from contracts.loot.constants.adventurer import (
    Adventurer,
    AdventurerState,
    PackedAdventurerState,
    AdventurerStatus,
    DiscoveryType
)
from contracts.loot.constants.beast import Beast
from contracts.loot.interfaces.imodules import IModuleController
from contracts.loot.loot.stats.combat import CombatStats
from contracts.loot.utils.general import _uint_to_felt
from contracts.loot.beast.interface import IBeast
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
    name: felt, symbol: felt, address_of_controller: felt, proxy_admin: felt
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


// @notice Mint an adventurer with null attributes
// @param to: Recipient of adventurer
// @param race: Race of adventurer
// @param home_realm: Home Realm of adventurer
// @param name: Name of adventurer
// @param order: Order of adventurer
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
    IERC20.transferFrom(lords_address, caller, treasury, Uint256(50, 0));
    // send to this contract and set Balance of Adventurer
    let (this) = get_contract_address();
    IERC20.transferFrom(lords_address, caller, this, Uint256(50, 0));
    adventurer_balance.write(next_adventurer_id, Uint256(50, 0));

    return ();
}

// @notice Equip loot item to adventurer
// @param tokenId: Id of adventurer
// @param itemTokenId: Id of loot item
@external
func equip_item{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(tokenId: Uint256, itemTokenId: Uint256) -> (success: felt) {
    alloc_locals;

    // only adventurer owner can equip
    ERC721.assert_only_token_owner(tokenId);

    // unpack adventurer
    let (unpacked_adventurer) = get_adventurer_by_id(tokenId);

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

    // After equipping your item
    // if the adventurer is in battle (currently just beasts)
    if (equiped_adventurer.Status == AdventurerStatus.Battle) {
         // The beast will counter attack
        let (beast_address) = Module.get_module_address(ModuleIds.Beast);
        let beast_token_id = Uint256(equiped_adventurer.Beast,0);
        IBeast.counter_attack(beast_address, beast_token_id);
        return (TRUE,);
    }

    return (TRUE,);
}

// @notice Unquip loot item from adventurer
// @param tokenId: Id of adventurer
// @param itemTokenId: Id of loot item
@external
func unequip_item{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(tokenId: Uint256, itemTokenId: Uint256) -> (success: felt) {
    alloc_locals;

    // only adventurer owner can unequip
    ERC721.assert_only_token_owner(tokenId);

    // unpack adventurer
    let (unpacked_adventurer) = get_adventurer_by_id(tokenId);

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

    // After unequipping your item
    // if the adventurer is in battle (currently just beasts)
    if (unequiped_adventurer.Status == AdventurerStatus.Battle) {
         // The beast will counter attack
        let (beast_address) = Module.get_module_address(ModuleIds.Beast);
        let beast_token_id = Uint256(unequiped_adventurer.Beast,0);
        IBeast.counter_attack(beast_address, beast_token_id);
        return (TRUE,);
    }

    return (TRUE,);
}

// @notice Update status of adventurer
// @param tokenId: Id of adventurer
// @param status: Status value
@external
func update_status{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(tokenId: Uint256, status: felt) -> (success: felt) {
    alloc_locals;
    Module.only_approved();

    let (unpacked_adventurer) = get_adventurer_by_id(tokenId);

    let (new_adventurer) = AdventurerLib.update_status(status, unpacked_adventurer);

    let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(new_adventurer);
    adventurer.write(tokenId, packed_new_adventurer);

    emit_adventurer_state(tokenId);

    return (TRUE,);
}

// @notice Deduct health from adventurer
// @param tokenId: Id of adventurer
// @param amount: Health amount to deduct
// @return success: Value indicating success
@external
func deduct_health{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, amount: felt) -> (success: felt) {
    alloc_locals;

    Module.only_approved();

    // unpack adventurer
    let (unpacked_adventurer) = get_adventurer_by_id(adventurer_token_id);

    // deduct health
    let (new_adventurer) = AdventurerLib.deduct_health(amount, unpacked_adventurer);

    // if the adventurer is dead
    if (new_adventurer.Health == 0) {
        // transfer all their LORDS to the beast address
        let (lords_address) = Module.get_external_contract_address(ExternalContractIds.Lords);
        let (beast_address) = Module.get_module_address(ModuleIds.Beast);
        let (adventurer_balance_) = adventurer_balance.read(adventurer_token_id);
        IERC20.transfer(lords_address, beast_address, adventurer_balance_);
        adventurer_balance.write(adventurer_token_id, Uint256(0,0));

        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;

        //TODO MILESTONE2: Figure out how to assign the LORDS tokens to the beast that killed the adventurer
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
    }
 
    let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(new_adventurer);
    adventurer.write(adventurer_token_id, packed_new_adventurer);

    emit_adventurer_state(adventurer_token_id);

    return (TRUE,);
}

// @notice Increase xp of adventurer
// @param tokenId: Id of adventurer
// @param amount: Amount of xp to increase
// @return success: Value indicating success
@external
func increase_xp{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(tokenId: Uint256, amount: felt) -> (success: felt) {
    alloc_locals;

    Module.only_approved();

    // unpack adventurer
    let (unpacked_adventurer) = get_adventurer_by_id(tokenId);

    // increase xp
    let (new_adventurer) = AdventurerLib.increase_xp(amount, unpacked_adventurer);

    let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(new_adventurer);
    adventurer.write(tokenId, packed_new_adventurer);

    emit_adventurer_state(tokenId);

    return (TRUE,);
}

// @notice Explore for discoveries
// @param tokenId: Id of adventurer
// @return success: Value indicating success
@external
func explore{
        pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(token_id: Uint256) -> (success: felt) {
    alloc_locals;

    // only adventurer owner can explore
    ERC721.assert_only_token_owner(token_id);

    // unpack adventurer
    let (unpacked_adventurer) = get_adventurer_by_id(token_id);

    assert_not_dead(token_id);

    // Only idle explorers can explore
    with_attr error_message("Adventurer: Adventurer must be idle") {
        assert unpacked_adventurer.Status = AdventurerStatus.Idle;
    }

    // Only adventurers without assigned beast
    with_attr error_message("Adventurer: Cannot explore while assigned beast") {
        assert unpacked_adventurer.Beast = 0;
    }

    let (rnd) = get_random_number();
    let (discovery) = AdventurerLib.get_random_discovery(rnd);

    // If the adventurer encounter a beast
    if (discovery == DiscoveryType.Beast) {
        // we set their status to battle
        let (unpacked_adventurer: AdventurerState) = AdventurerLib.update_status(
            AdventurerStatus.Battle, unpacked_adventurer
        );
        // create beast
        let (beast_address) = Module.get_module_address(ModuleIds.Beast);
        let (beast_id: Uint256) = IBeast.create(beast_address, token_id);        
        let (updated_adventurer) = AdventurerLib.assign_beast(beast_id.low, unpacked_adventurer);
        let (packed_adventurer) = AdventurerLib.pack(updated_adventurer);
            
        adventurer.write(token_id, packed_adventurer);

        emit_adventurer_state(token_id);

        return (TRUE,);
    }

    return (TRUE,);
}
// -----------------------------
// Internal Adventurer Specific
// -----------------------------

// @notice Revert if adventurer is dead
// @param tokenId: Id of adventurer
func assert_not_dead{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(tokenId: Uint256) {
    let (adventurer: AdventurerState) = get_adventurer_by_id(tokenId);

    with_attr error_message("Adventurer: Adventurer is dead") {
        assert_not_zero(adventurer.Health);
    }

    return ();
}

// @notice Get xoroshiro random number
// @return dice_roll: Xoroshiro random number
func get_random_number{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}() -> (
    dice_roll: felt
) {
    alloc_locals;

    let (controller) = Module.controller_address();
    let (xoroshiro_address_) = IModuleController.get_xoroshiro(controller);
    let (rnd) = IXoroshiro.next(xoroshiro_address_);
    return (rnd,);
}

// @notice Emit state of adventurer
// @param tokenId: Id of adventurer
func emit_adventurer_state{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(tokenId: Uint256) {
    // Get new adventurer
    let (new_adventurer) = get_adventurer_by_id(tokenId);

    NewAdventurerState.emit(tokenId, new_adventurer);

    return ();
}

// --------------------
// Getters
// --------------------

// @notice Get adventurer data from id
// @param tokenId: Id of adventurer
// @return adventurer: Data of adventurer
@view
func get_adventurer_by_id{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(tokenId: Uint256) -> (adventurer: AdventurerState) {
    alloc_locals;

    let (packed_adventurer) = adventurer.read(tokenId);

    // unpack
    let (unpacked_adventurer: AdventurerState) = AdventurerLib.unpack(packed_adventurer);

    return (unpacked_adventurer,);
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
