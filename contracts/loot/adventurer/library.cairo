// BUILDINGS LIBRARY
//   functions for
//
//
// MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le, assert_nn
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_mul, uint256_unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.memset import memset

from contracts.loot.loot.stats.item import ItemStats

from contracts.loot.constants.adventurer import (
    Adventurer,
    AdventurerState,
    AdventurerStatic,
    AdventurerDynamic,
    PackedAdventurerState,
    SHIFT_P_1,
    SHIFT_P_4,
    ItemShift,
    StatisticShift,
    AdventurerSlotIds,
    AdventurerStatus,
    DiscoveryType,
)

from contracts.loot.constants.obstacle import ObstacleUtils
from contracts.loot.constants.item import Item, ItemIds, Slot, ItemSuffixes
from contracts.settling_game.utils.general import unpack_data
from contracts.settling_game.utils.constants import SHIFT_41
from contracts.loot.constants.beast import Beast, BeastIds
from contracts.loot.loot.stats.combat import CombatStats
from contracts.loot.utils.constants import SUFFIX_STAT_BOOST

namespace AdventurerLib {
    func birth{syscall_ptr: felt*, range_check_ptr}(
        race: felt,
        home_realm: felt,
        name: felt,
        birth_date: felt,
        order: felt,
        image_hash_1: felt,
        image_hash_2: felt,
    ) -> (adventurer_static: AdventurerStatic, adventurer_dynamic: AdventurerDynamic) {
        alloc_locals;

        let Race = race;  // stored state
        let HomeRealm = home_realm;  // stored state
        let Birthdate = birth_date;  // stored state
        let Name = name;  // stored state
        let Order = order;  // stored state
        let ImageHash1 = image_hash_1;  // stored state
        let ImageHash2 = image_hash_2;  // stored state

        let Health = 100;  // stored state
        let XP = 0;  // stored state
        let Level = 1;  // stored state

        // Physical
        let Strength = 0;
        let Dexterity = 0;
        let Vitality = 0;

        // Mental
        let Intelligence = 0;
        let Wisdom = 0;
        let Charisma = 0;

        let Luck = 0;

        let NeckId = 0;
        let WeaponId = 0;
        let RingId = 0;
        let ChestId = 0;
        let HeadId = 0;
        let WaistId = 0;
        let FeetId = 0;
        let HandsId = 0;

        let Status = AdventurerStatus.Idle;
        let Beast = 0;
        let Upgrading = 0;

        return (
            AdventurerStatic(
                Race=Race,
                HomeRealm=HomeRealm,
                Birthdate=Birthdate,
                Name=Name,
                Order=Order,
                ImageHash1=ImageHash1,
                ImageHash2=ImageHash2,
            ),
            AdventurerDynamic(
                Health=Health,
                Level=Level,
                Strength=Strength,
                Dexterity=Dexterity,
                Vitality=Vitality,
                Intelligence=Intelligence,
                Wisdom=Wisdom,
                Charisma=Charisma,
                Luck=Luck,
                XP=XP,
                WeaponId=WeaponId,
                ChestId=ChestId,
                HeadId=HeadId,
                WaistId=WaistId,
                FeetId=FeetId,
                HandsId=HandsId,
                NeckId=NeckId,
                RingId=RingId,
                Status=Status,
                Beast=Beast,
                Upgrading=Upgrading,
            ),
        );
    }

    func aggregate_data{syscall_ptr: felt*, range_check_ptr}(
        adventurer_static: AdventurerStatic, adventurer_dynamic: AdventurerDynamic
    ) -> (adventurer: AdventurerState) {
        let adventurer = AdventurerState(
            adventurer_static.Race,
            adventurer_static.HomeRealm,
            adventurer_static.Birthdate,
            adventurer_static.Name,
            adventurer_static.Order,
            adventurer_static.ImageHash1,
            adventurer_static.ImageHash2,
            adventurer_dynamic.Health,
            adventurer_dynamic.Level,
            adventurer_dynamic.Strength,
            adventurer_dynamic.Dexterity,
            adventurer_dynamic.Vitality,
            adventurer_dynamic.Intelligence,
            adventurer_dynamic.Wisdom,
            adventurer_dynamic.Charisma,
            adventurer_dynamic.Luck,
            adventurer_dynamic.XP,
            adventurer_dynamic.WeaponId,
            adventurer_dynamic.ChestId,
            adventurer_dynamic.HeadId,
            adventurer_dynamic.WaistId,
            adventurer_dynamic.FeetId,
            adventurer_dynamic.HandsId,
            adventurer_dynamic.NeckId,
            adventurer_dynamic.RingId,
            adventurer_dynamic.Status,
            adventurer_dynamic.Beast,
            adventurer_dynamic.Upgrading,
        );

        return (adventurer,);
    }

    func split_data{syscall_ptr: felt*, range_check_ptr}(adventurer: AdventurerState) -> (
        adventurer_static: AdventurerStatic, adventurer_dynamic: AdventurerDynamic
    ) {
        let adventurer_static = AdventurerStatic(
            adventurer.Race,
            adventurer.HomeRealm,
            adventurer.Birthdate,
            adventurer.Name,
            adventurer.Order,
            adventurer.ImageHash1,
            adventurer.ImageHash2,
        );

        let adventurer_dynamic = AdventurerDynamic(
            adventurer.Health,
            adventurer.Level,
            adventurer.Strength,
            adventurer.Dexterity,
            adventurer.Vitality,
            adventurer.Intelligence,
            adventurer.Wisdom,
            adventurer.Charisma,
            adventurer.Luck,
            adventurer.XP,
            adventurer.WeaponId,
            adventurer.ChestId,
            adventurer.HeadId,
            adventurer.WaistId,
            adventurer.FeetId,
            adventurer.HandsId,
            adventurer.NeckId,
            adventurer.RingId,
            adventurer.Status,
            adventurer.Beast,
            adventurer.Upgrading,
        );

        return (adventurer_static, adventurer_dynamic);
    }

    func pack{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(unpacked_adventurer_state: AdventurerDynamic) -> (packed_adventurer: PackedAdventurerState) {
        alloc_locals;
        // ---------- p1 ---------#
        let Health = unpacked_adventurer_state.Health * SHIFT_P_1._1;
        let Level = unpacked_adventurer_state.Level * SHIFT_P_1._2;
        // Physical
        let Strength = unpacked_adventurer_state.Strength * SHIFT_P_1._3;
        let Dexterity = unpacked_adventurer_state.Dexterity * SHIFT_P_1._4;
        let Vitality = unpacked_adventurer_state.Vitality * SHIFT_P_1._5;

        // Mental
        let Intelligence = unpacked_adventurer_state.Intelligence * SHIFT_P_1._6;
        let Wisdom = unpacked_adventurer_state.Wisdom * SHIFT_P_1._7;
        let Charisma = unpacked_adventurer_state.Charisma * SHIFT_P_1._8;

        let Luck = unpacked_adventurer_state.Luck * SHIFT_P_1._9;

        let XP = unpacked_adventurer_state.XP * SHIFT_P_1._10;

        // Items
        let Weapon = unpacked_adventurer_state.WeaponId * SHIFT_41._1;
        let Chest = unpacked_adventurer_state.ChestId * SHIFT_41._2;
        let Head = unpacked_adventurer_state.HeadId * SHIFT_41._3;
        let Waist = unpacked_adventurer_state.WaistId * SHIFT_41._4;

        let Feet = unpacked_adventurer_state.FeetId * SHIFT_41._1;
        let Hands = unpacked_adventurer_state.HandsId * SHIFT_41._2;
        let Neck = unpacked_adventurer_state.NeckId * SHIFT_41._3;
        let Ring = unpacked_adventurer_state.RingId * SHIFT_41._4;

        let Status = unpacked_adventurer_state.Status * SHIFT_P_4._1;
        let Beast = unpacked_adventurer_state.Beast * SHIFT_P_4._2;
        let Upgrading = unpacked_adventurer_state.Upgrading * SHIFT_P_4._3;

        // packing
        // let p1 = XP + Luck + Charisma + Wisdom + Intelligence + Vitality + Dexterity + Strength + Level + Health;
        let p1 = Health + Level + Strength + Dexterity + Vitality + Intelligence + Wisdom +
            Charisma + Luck + XP;
        // let p2 = Waist + Head + Chest + Weapon;
        let p2 = Weapon + Chest + Head + Waist;
        // let p3 = Ring + Neck + Hands + Feet;
        let p3 = Feet + Hands + Neck + Ring;
        let p4 = Status + Beast + Upgrading;

        let packedAdventurer = PackedAdventurerState(p1, p2, p3, p4);

        return (packedAdventurer,);
    }

    func unpack{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(packed_adventurer: PackedAdventurerState) -> (adventurer: AdventurerDynamic) {
        alloc_locals;

        // ---------- p1 ---------#
        let (Health) = unpack_data(packed_adventurer.p1, 0, 1023);  // 10
        let (Level) = unpack_data(packed_adventurer.p1, 10, 1023);  // 10

        // Physical
        let (Strength) = unpack_data(packed_adventurer.p1, 20, 1023);  // 10
        let (Dexterity) = unpack_data(packed_adventurer.p1, 30, 1023);  // 10
        let (Vitality) = unpack_data(packed_adventurer.p1, 40, 1023);  // 10

        // Mental
        let (Intelligence) = unpack_data(packed_adventurer.p1, 50, 1023);  // 10
        let (Wisdom) = unpack_data(packed_adventurer.p1, 60, 1023);  // 10
        let (Charisma) = unpack_data(packed_adventurer.p1, 70, 1023);  // 10

        // Luck
        let (Luck) = unpack_data(packed_adventurer.p1, 80, 1023);  // 10

        // XP
        let (XP) = unpack_data(packed_adventurer.p1, 90, 134217727);  // 27

        // ---------- p2 ---------#
        let (WeaponId) = unpack_data(packed_adventurer.p2, 0, 2199023255551);  // 41
        let (ChestId) = unpack_data(packed_adventurer.p2, 41, 2199023255551);  // 41
        let (HeadId) = unpack_data(packed_adventurer.p2, 82, 2199023255551);  // 41
        let (WaistId) = unpack_data(packed_adventurer.p2, 123, 2199023255551);  // 41

        // ---------- p3 ---------#
        let (FeetId) = unpack_data(packed_adventurer.p3, 0, 2199023255551);  // 41
        let (HandsId) = unpack_data(packed_adventurer.p3, 41, 2199023255551);  // 41
        let (NeckId) = unpack_data(packed_adventurer.p3, 82, 2199023255551);  // 41
        let (RingId) = unpack_data(packed_adventurer.p3, 123, 2199023255551);  // 41

        // ---------- p4 ---------#
        let (Status) = unpack_data(packed_adventurer.p4, 0, 7);  // 3
        let (Beast) = unpack_data(packed_adventurer.p4, 3, 2199023255551);  // 41
        let (Upgrading) = unpack_data(packed_adventurer.p4, 44, 1);  // 1

        return (
            AdventurerDynamic(
                Health=Health,
                Level=Level,
                Strength=Strength,
                Dexterity=Dexterity,
                Vitality=Vitality,
                Intelligence=Intelligence,
                Wisdom=Wisdom,
                Charisma=Charisma,
                Luck=Luck,
                XP=XP,
                WeaponId=WeaponId,
                ChestId=ChestId,
                HeadId=HeadId,
                WaistId=WaistId,
                FeetId=FeetId,
                HandsId=HandsId,
                NeckId=NeckId,
                RingId=RingId,
                Status=Status,
                Beast=Beast,
                Upgrading=Upgrading,
            ),
        );
    }

    // @notice Casts the state of the adventurer by updating a specific index with a new value
    // @dev This function is internal and should only be called by other functions in the contract
    // @param index The index of the state to be updated
    // @param value The new value to be set at the specified index
    // @param unpacked_adventurer The current state of the adventurer
    // @return new_unpacked_adventurer The updated state of the adventurer
    func cast_state{syscall_ptr: felt*, range_check_ptr}(
        index: felt, value: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // Get the current frame pointer (__fp__) and program counter (_)
        let (__fp__, _) = get_fp_and_pc();

        // Allocate memory for a new local variable (a)
        let (a) = alloc();

        // Copy the first part of the unpacked_adventurer to a
        memcpy(a, &unpacked_adventurer, index);

        // Set the value at the specified index in a
        memset(a + index, value, 1);

        // Copy the remaining part of the unpacked_adventurer to a
        memcpy(
            a + (index + 1),
            &unpacked_adventurer + (index + 1),
            AdventurerDynamic.SIZE - (index + 1),
        );

        // Cast the memory address of a to AdventurerDynamic pointer
        let cast_adventurer = cast(a, AdventurerDynamic*);

        // Return the updated adventurer state as a tuple
        return ([cast_adventurer],);
    }

    // @notice Retrieves the value of a specific state in the adventurer
    // @dev This function is internal and should only be called by other functions in the contract
    // @param index The index of the state to be retrieved
    // @param unpacked_adventurer The current state of the adventurer
    // @return value The value at the specified index in the adventurer's state
    func get_state{syscall_ptr: felt*, range_check_ptr}(
        index: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (value: felt) {
        alloc_locals;

        // Get the current frame pointer (__fp__) and program counter (_)
        let (__fp__, _) = get_fp_and_pc();

        // Get the memory address of the unpacked_adventurer
        let adventurer_fields: felt* = &unpacked_adventurer;

        // Retrieve the value at the specified index from the adventurer's state
        let value = adventurer_fields[index];

        // Return the value as a tuple
        return (value,);
    }

    // @notice Retrieves the item ID of a specific item in the adventurer's inventory
    // @dev This function is internal and should only be called by other functions in the contract
    // @param item The item to retrieve the item ID for
    // @param unpacked_adventurer The current state of the adventurer
    // @return item_id The item ID of the specified item in the adventurer's inventory
    func get_item{syscall_ptr: felt*, range_check_ptr}(
        item: Item, unpacked_adventurer: AdventurerDynamic
    ) -> (item_id: felt) {
        alloc_locals;

        // Pass the index shift and Item slot to get the state value for the item
        let (item_id) = get_state(ItemShift + item.Slot, unpacked_adventurer);

        // Return the item ID as a tuple
        return (item_id,);
    }

    // @notice Equips an item to the adventurer's inventory
    // @dev This function is internal and should only be called by other functions in the contract
    // @param item_token_id The ID of the item token to be equipped
    // @param item The item to be equipped
    // @param unpacked_adventurer The current state of the adventurer
    // @return new_unpacked_adventurer The updated state of the adventurer after equipping the item
    func equip_item{syscall_ptr: felt*, range_check_ptr}(
        item_token_id: felt, item: Item, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // Pass the index shift and Item slot to update the state value for the item
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            ItemShift + item.Slot, item_token_id, unpacked_adventurer
        );

        // Return the updated adventurer state as a tuple
        return (updated_adventurer,);
    }

    // @notice Unequips an item from the adventurer's inventory
    // @dev This function is internal and should only be called by other functions in the contract
    // @param item The item to be unequipped
    // @param unpacked_adventurer The current state of the adventurer
    // @return new_unpacked_adventurer The updated state of the adventurer after unequipping the item
    func unequip_item{syscall_ptr: felt*, range_check_ptr}(
        item: Item, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // pass index shift and Item slot to find what item to update
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            ItemShift + item.Slot, 0, unpacked_adventurer
        );

        // Return the updated adventurer state as a tuple
        return (updated_adventurer,);
    }

    // @notice Retrieves the item token ID at a specific slot in the adventurer's inventory
    // @dev This function is internal and should only be called by other functions in the contract
    // @param slot The slot to retrieve the item token ID from
    // @param unpacked_adventurer The current state of the adventurer
    // @return item_token_id The item token ID at the specified slot
    func get_item_id_at_slot{syscall_ptr: felt*, range_check_ptr}(
        slot: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (item_token_id: felt) {
        alloc_locals;

        // Check the slot and return the corresponding item token ID
        if (slot == Slot.Weapon) {
            return (unpacked_adventurer.WeaponId,);
        }
        if (slot == Slot.Chest) {
            return (unpacked_adventurer.ChestId,);
        }
        if (slot == Slot.Head) {
            return (unpacked_adventurer.HeadId,);
        }
        if (slot == Slot.Waist) {
            return (unpacked_adventurer.WaistId,);
        }
        if (slot == Slot.Foot) {
            return (unpacked_adventurer.FeetId,);
        }
        if (slot == Slot.Hand) {
            return (unpacked_adventurer.HandsId,);
        }
        if (slot == Slot.Neck) {
            return (unpacked_adventurer.NeckId,);
        }
        if (slot == Slot.Ring) {
            return (unpacked_adventurer.RingId,);
        }

        // Return 0 if the slot is invalid
        return (0,);
    }

    // @notice Deducts health from the adventurer based on the damage dealt
    // @dev This function is internal and should only be called by other functions in the contract
    // @param damage The amount of damage dealt to the adventurer
    // @param unpacked_adventurer The current state of the adventurer
    // @return new_unpacked_adventurer The updated state of the adventurer after deducting health
    func deduct_health{syscall_ptr: felt*, range_check_ptr}(
        damage: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // check if damage dealt is less than health remaining
        let still_alive = is_le(damage, unpacked_adventurer.Health);

        // if adventurer is still alive
        if (still_alive == TRUE) {
            // set new health to previous health - damage dealt
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Health, unpacked_adventurer.Health - damage, unpacked_adventurer
            );
        } else {
            // if damage dealt exceeds health remaining, set health to 0
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Health, 0, unpacked_adventurer
            );
        }

        return (updated_adventurer,);
    }

    // @notice Adds the specified amount of health to the adventurer's current health
    // / @dev This function is internal and should only be called by other functions in the contract
    // / @param health The amount of health to be added to the adventurer's current health
    // / @param unpacked_adventurer The current state of the adventurer
    // / @return new_unpacked_adventurer The updated state of the adventurer after adding the health
    func add_health{syscall_ptr: felt*, range_check_ptr}(
        health: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // set new health to previous health - damage dealt
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            AdventurerSlotIds.Health, unpacked_adventurer.Health + health, unpacked_adventurer
        );

        return (updated_adventurer,);
    }

    // @notice Increases the adventurer's XP by the specified amount
    // @dev This function is internal and should only be called by other functions in the contract
    // @param xp The amount of XP to be added to the adventurer's current XP
    // @param unpacked_adventurer The current state of the adventurer
    // @return new_unpacked_adventurer The updated state of the adventurer after increasing the XP
    func increase_xp{syscall_ptr: felt*, range_check_ptr}(
        xp: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // update adventurer xp
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            AdventurerSlotIds.XP, xp + unpacked_adventurer.XP, unpacked_adventurer
        );

        // return updated adventurer
        return (updated_adventurer,);
    }

    // @notice Updates the adventurer's level to the specified level
    // @dev This function is internal and should only be called by other functions in the contract
    // @param level The new level to be set for the adventurer
    // @param unpacked_adventurer The current state of the adventurer
    // @return new_unpacked_adventurer The updated state of the adventurer after updating the level
    func update_level{syscall_ptr: felt*, range_check_ptr}(
        level: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // update adventurer level
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            AdventurerSlotIds.Level, level, unpacked_adventurer
        );

        // return updated adventurer
        return (updated_adventurer,);
    }

    // @notice Updates the adventurer's status to the specified status
    // @dev This function is internal and should only be called by other functions in the contract
    // @param status The new status to be set for the adventurer
    // @param unpacked_adventurer The current state of the adventurer
    // @return new_unpacked_adventurer The updated state of the adventurer after updating the status
    func update_status{syscall_ptr: felt*, range_check_ptr}(
        status: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // Make sure status is within allowable range
        assert_le(status, AdventurerStatus.Dead + 1);

        // update adventurer status
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            AdventurerSlotIds.Status, status, unpacked_adventurer
        );

        // return updated adventurer
        return (updated_adventurer,);
    }

    // @notice Assigns a beast ID to the adventurer
    // @dev This function is internal and should only be called by other functions in the contract
    // @param beast_id The ID of the beast to be assigned to the adventurer
    // @param unpacked_adventurer The current state of the adventurer
    // @return new_unpacked_adventurer The updated state of the adventurer after assigning the beast
    func assign_beast{syscall_ptr: felt*, range_check_ptr}(
        beast_id: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // update adventurer beast
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            AdventurerSlotIds.Beast, beast_id, unpacked_adventurer
        );

        // return updated adventurer
        return (updated_adventurer,);
    }

    // @notice Removes the assigned beast from the adventurer
    // @dev This function is internal and should only be called by other functions in the contract
    // @param unpacked_adventurer The current state of the adventurer
    // @return new_unpacked_adventurer The updated state of the adventurer after removing the beast
    func remove_beast{syscall_ptr: felt*, range_check_ptr}(
        unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // zero out the beast associated with the adventurer
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            AdventurerSlotIds.Beast, 0, unpacked_adventurer
        );

        // return updated adventurer
        return (updated_adventurer,);
    }

    // @notice Retrieves a random discovery based on the provided XORoshiro random number
    // @dev This function is internal and should only be called by other functions in the contract
    // @param xoroshiro_random The XORoshiro random number used to calculate the discovery
    // @return discovery A random discovery value from 0 to 3 (inclusive)
    func get_random_discovery{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
        xoroshiro_random: felt
    ) -> (discovery: felt) {
        alloc_locals;

        // Calculate the remainder when dividing the XORoshiro random number by 4
        let (_, r) = unsigned_div_rem(xoroshiro_random, 4);

        // Return the random discovery value as a tuple
        return (r,);
    }

    // @notice Retrieves an item discovery based on the provided XORoshiro random number
    // @dev This function is internal and should only be called by other functions in the contract
    // @param xoroshiro_random The XORoshiro random number used to calculate the discovery
    // @return discovery An item discovery value from 0 to 2 (inclusive)
    func get_item_discovery{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
        xoroshiro_random: felt
    ) -> (discovery: felt) {
        alloc_locals;

        // Calculate the remainder when dividing the XORoshiro random number by 3
        let (_, r) = unsigned_div_rem(xoroshiro_random, 3);

        // Return the item discovery value as a tuple
        return (r,);
    }

    // @notice Updates a statistic value in the adventurer's state by incrementing it by 1
    // @dev This function is internal and should only be called by other functions in the contract
    // @param stat The statistic value to be updated
    // @param unpacked_adventurer The current state of the adventurer
    // @return new_unpacked_adventurer The updated state of the adventurer after updating the statistic
    func update_statistics{syscall_ptr: felt*, range_check_ptr}(
        stat: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // Check which statistic is being updated
        if (stat == AdventurerSlotIds.Strength) {
            // Increment the Strength statistic by 1
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Strength, unpacked_adventurer.Strength + 1, unpacked_adventurer
            );
            return (updated_adventurer,);
        }
        if (stat == AdventurerSlotIds.Dexterity) {
            // Increment the Dexterity statistic by 1
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Dexterity, unpacked_adventurer.Dexterity + 1, unpacked_adventurer
            );
            return (updated_adventurer,);
        }
        if (stat == AdventurerSlotIds.Vitality) {
            // Increment the Vitality statistic by 1
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Vitality, unpacked_adventurer.Vitality + 1, unpacked_adventurer
            );
            return (updated_adventurer,);
        }
        if (stat == AdventurerSlotIds.Intelligence) {
            // Increment the Intelligence statistic by 1
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Intelligence,
                unpacked_adventurer.Intelligence + 1,
                unpacked_adventurer,
            );
            return (updated_adventurer,);
        }
        if (stat == AdventurerSlotIds.Wisdom) {
            // Increment the Wisdom statistic by 1
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Wisdom, unpacked_adventurer.Wisdom + 1, unpacked_adventurer
            );
            return (updated_adventurer,);
        }
        if (stat == AdventurerSlotIds.Charisma) {
            // Increment the Charisma statistic by 1
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Charisma, unpacked_adventurer.Charisma + 1, unpacked_adventurer
            );
            return (updated_adventurer,);
        } else {
            // Increment the Luck statistic by 1 (fallback case)
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Luck, unpacked_adventurer.Luck + 1, unpacked_adventurer
            );
            return (updated_adventurer,);
        }
    }

    // @notice Sets the upgrading status for the adventurer
    // @dev This function is internal and should only be called by other functions in the contract
    // @param upgrading The upgrading status to be set for the adventurer
    // @param unpacked_adventurer The current state of the adventurer
    // @return new_unpacked_adventurer The updated state of the adventurer after setting the upgrading status
    func set_upgrading{syscall_ptr: felt*, range_check_ptr}(
        upgrading: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        // Set the upgrading status for the adventurer
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            AdventurerSlotIds.Upgrading, upgrading, unpacked_adventurer
        );

        // Return the updated adventurer state as a tuple
        return (updated_adventurer,);
    }

    // @notice Calculates the gold discovery based on the provided random number
    // @dev This function is internal and should only be called by other functions in the contract
    // @param rnd The random number used to calculate the gold discovery
    // @return gold_discovery The calculated gold discovery value
    func calculate_gold_discovery{syscall_ptr: felt*, range_check_ptr}(
        rnd: felt, adventurer_level: felt
    ) -> (gold_discovery: felt) {
        let (gold_multi, _) = unsigned_div_rem(adventurer_level, 5);
        let gold_range = (1 + gold_multi) * 3;

        // Calculate the remainder when dividing the random number by gold range
        let (_, discover_multi) = unsigned_div_rem(rnd, gold_range);

        // Calculate the gold discovery value
        let gold_discovery = 1 + discover_multi;

        // Return the gold discovery value as a tuple
        return (gold_discovery,);
    }

    // @notice Calculates the health discovery based on the provided random number
    // @dev This function is internal and should only be called by other functions in the contract
    // @param rnd The random number used to calculate the health discovery
    // @return health_discovery The calculated health discovery value
    func calculate_health_discovery{syscall_ptr: felt*, range_check_ptr}(rnd: felt) -> (
        health_discovery: felt
    ) {
        // Calculate the remainder when dividing the random number by 4
        let (_, discover_multi) = unsigned_div_rem(rnd, 4);

        // Calculate the health discovery value
        let health_discovery = 10 + (5 * discover_multi);

        // Return the health discovery value as a tuple
        return (health_discovery,);
    }

    // @notice Calculates the XP discovery based on the provided random number
    // @dev This function is internal and should only be called by other functions in the contract
    // @param rnd The random number used to calculate the XP discovery
    // @return xp_discovery The calculated XP discovery value
    func calculate_xp_discovery{syscall_ptr: felt*, range_check_ptr}(
        rnd: felt, adventurer_level: felt
    ) -> (xp_discovery: felt) {
        let (xp_multi, _) = unsigned_div_rem(adventurer_level, 5);
        let xp_range = (1 + xp_multi) * 10;

        // Calculate the remainder when dividing the random number by xp range
        let (_, discover_multi) = unsigned_div_rem(rnd, xp_range);

        // Calculate the XP discovery value
        let xp_discovery = 1 + discover_multi;

        // Return the XP discovery value as a tuple
        return (xp_discovery,);
    }

    // @notice Retrieves the starting beast ID based on the provided weapon ID
    // @dev This function is internal and should only be called by other functions in the contract
    // @param weapon_id The ID of the weapon
    // @return beast_id The ID of the starting beast associated with the weapon
    func get_starting_beast_from_weapon{syscall_ptr: felt*, range_check_ptr}(weapon_id: felt) -> (
        beast_id: felt
    ) {
        // Check which weapon is being used and return the associated starting beast ID
        if (weapon_id == ItemIds.ShortSword) {
            return (BeastIds.Gnome,);
        }
        if (weapon_id == ItemIds.Book) {
            return (BeastIds.Ogre,);
        }
        if (weapon_id == ItemIds.Wand) {
            return (BeastIds.Ogre,);
        }
        if (weapon_id == ItemIds.Club) {
            return (BeastIds.Rat,);
        }
        return (0,);
    }

    // @notice Updates the luck stat modifier for jewelry items in the adventurer's state
    // @dev This function is internal and should only be called by other functions in the contract
    // @param item The jewelry item to be updated
    // @param unpacked_adventurer The current state of the adventurer
    // @param jewlery_greatness The new value of the luck stat modifier for jewelry
    // @return new_unpacked_adventurer The updated state of the adventurer after updating the jewelry stat modifier
    func update_jewerly_stat_modifier{syscall_ptr: felt*, range_check_ptr}(
        item: Item, unpacked_adventurer: AdventurerDynamic, jewlery_greatness: felt
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        // Remove the previous stat modifier from jewelry by setting the luck to the new value
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            AdventurerSlotIds.Luck, jewlery_greatness, unpacked_adventurer
        );
        return (updated_adventurer,);
    }

    // @notice Checks if an item is jewelry
    // @dev This function is internal and should only be called by other functions in the contract
    // @param item The item to be checked
    // @return is_jewerly A boolean indicating whether the item is jewelry (TRUE) or not (FALSE)
    func is_item_jewlery{syscall_ptr: felt*, range_check_ptr}(item: Item) -> (is_jewerly: felt) {
        // Check if the item's slot is either Slot.Neck or Slot.Ring
        if (item.Slot == Slot.Neck) {
            return (TRUE,);
        }
        if (item.Slot == Slot.Ring) {
            return (TRUE,);
        }
        return (FALSE,);
    }

    // @notice Checks if an item impacts the stat modifier
    // @dev This function is internal and should only be called by other functions in the contract
    // @param item The item to be checked
    // @return impacts_stat_modifier A boolean indicating whether the item impacts the stat modifier (TRUE) or not (FALSE)
    func impacts_stat_modifier{syscall_ptr: felt*, range_check_ptr}(item: Item) -> (
        impacts_stat_modifier: felt
    ) {
        // Check if the item is jewelry (which always impacts the stat modifier) or if its greatness is 15
        let (is_jewlery) = is_item_jewlery(item);
        if (is_jewlery == TRUE) {
            return (TRUE,);
        }

        // weapons and amor impacts stat modifier at greatness 15
        if (item.Greatness == 15) {
            return (TRUE,);
        }

        return (FALSE,);
    }

    // @notice Removes the stat modifiers from jewelry items in the adventurer's state
    // @dev This function is internal and should only be called by other functions in the contract
    // @param item The jewelry item to remove the stat modifiers from
    // @param unpacked_adventurer The current state of the adventurer
    // @return new_unpacked_adventurer The updated state of the adventurer after removing the jewelry stat modifiers
    func remove_jewerly_stat_modifiers{syscall_ptr: felt*, range_check_ptr}(
        item: Item, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        // Calculate the new luck amount by subtracting the jewelry item's greatness from the adventurer's luck
        let new_luck_amount = unpacked_adventurer.Luck - item.Greatness;
        return update_jewerly_stat_modifier(item, unpacked_adventurer, new_luck_amount);
    }

    // @notice Adds the stat modifiers from jewelry items in the adventurer's state
    // @dev This function is internal and should only be called by other functions in the contract
    // @param item The jewelry item to add the stat modifiers from
    // @param unpacked_adventurer The current state of the adventurer
    // @return new_unpacked_adventurer The updated state of the adventurer after adding the jewelry stat modifiers
    func add_jewerly_stat_modifiers{syscall_ptr: felt*, range_check_ptr}(
        item: Item, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        // Calculate the new luck amount by adding the jewelry item's greatness to the adventurer's luck
        let new_luck_amount = unpacked_adventurer.Luck + item.Greatness;
        return update_jewerly_stat_modifier(item, unpacked_adventurer, new_luck_amount);
    }

    // @notice Retrieves the stat amount for a specific item suffix in the adventurer's state
    // @dev This function is internal and should only be called by other functions in the contract
    // @param item The item to retrieve the stat amount for
    // @param unpacked_adventurer The current state of the adventurer
    // @return amount The amount of the specific stat associated with the item suffix
    func get_stat_for_item{syscall_ptr: felt*, range_check_ptr}(
        item: Item, unpacked_adventurer: AdventurerDynamic
    ) -> (amount: felt) {
        // Check the item suffix and return the associated stat amount from the adventurer's state
        if (item.Suffix == ItemSuffixes.of_Power) {
            return (unpacked_adventurer.Strength,);
        }
        if (item.Suffix == ItemSuffixes.of_Giant) {
            return (unpacked_adventurer.Vitality,);
        }

        if (item.Suffix == ItemSuffixes.of_Titans) {
            return (unpacked_adventurer.Dexterity,);
        }

        if (item.Suffix == ItemSuffixes.of_Skill) {
            return (unpacked_adventurer.Intelligence,);
        }

        if (item.Suffix == ItemSuffixes.of_Perfection) {
            return (unpacked_adventurer.Intelligence,);
        }

        if (item.Suffix == ItemSuffixes.of_Brilliance) {
            return (unpacked_adventurer.Intelligence,);
        }

        if (item.Suffix == ItemSuffixes.of_Enlightenment) {
            return (unpacked_adventurer.Wisdom,);
        }

        if (item.Suffix == ItemSuffixes.of_Protection) {
            return (unpacked_adventurer.Vitality,);
        }

        if (item.Suffix == ItemSuffixes.of_Anger) {
            return (unpacked_adventurer.Strength,);
        }

        if (item.Suffix == ItemSuffixes.of_Rage) {
            return (unpacked_adventurer.Wisdom,);
        }

        if (item.Suffix == ItemSuffixes.of_Fury) {
            return (unpacked_adventurer.Dexterity,);
        }

        if (item.Suffix == ItemSuffixes.of_Vitriol) {
            return (unpacked_adventurer.Charisma,);
        }

        if (item.Suffix == ItemSuffixes.of_the_Fox) {
            return (unpacked_adventurer.Intelligence,);
        }

        if (item.Suffix == ItemSuffixes.of_Detection) {
            return (unpacked_adventurer.Wisdom,);
        }

        if (item.Suffix == ItemSuffixes.of_Reflection) {
            return (unpacked_adventurer.Wisdom,);
        }

        if (item.Suffix == ItemSuffixes.of_the_Twins) {
            return (unpacked_adventurer.Dexterity,);
        }

        return (0,);
    }

    // @notice Updates the non-jewelry stat modifier in the adventurer's state based on the item suffix
    // @dev This function is internal and should only be called by other functions in the contract
    // @param item The item to update the stat modifier for
    // @param original_adventurer The original state of the adventurer
    // @param amount The new amount of the stat modifier
    // @return updated_adventurer The updated state of the adventurer after updating the non-jewelry stat modifier
    func update_non_jewelery_stat_modifier{syscall_ptr: felt*, range_check_ptr}(
        item: Item, original_adventurer: AdventurerDynamic, amount: felt
    ) -> (updated_adventurer: AdventurerDynamic) {
        // Update the stat modifier based on the item suffix
        if (item.Suffix == ItemSuffixes.of_Power) {
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Strength, amount, original_adventurer
            );
            return (updated_adventurer,);
        }
        if (item.Suffix == ItemSuffixes.of_Giant) {
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Vitality, amount, original_adventurer
            );
            return (updated_adventurer,);
        }
        if (item.Suffix == ItemSuffixes.of_Titans) {
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Dexterity, amount, original_adventurer
            );
            return (updated_adventurer,);
        }
        if (item.Suffix == ItemSuffixes.of_Skill) {
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Intelligence, amount, original_adventurer
            );
            return (updated_adventurer,);
        }
        if (item.Suffix == ItemSuffixes.of_Perfection) {
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Intelligence, amount, original_adventurer
            );
            return (updated_adventurer,);
        }
        if (item.Suffix == ItemSuffixes.of_Brilliance) {
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Intelligence, amount, original_adventurer
            );
            return (updated_adventurer,);
        }
        if (item.Suffix == ItemSuffixes.of_Enlightenment) {
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Wisdom, amount, original_adventurer
            );
            return (updated_adventurer,);
        }
        if (item.Suffix == ItemSuffixes.of_Protection) {
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Vitality, amount, original_adventurer
            );
            return (updated_adventurer,);
        }
        if (item.Suffix == ItemSuffixes.of_Anger) {
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Strength, amount, original_adventurer
            );
            return (updated_adventurer,);
        }
        if (item.Suffix == ItemSuffixes.of_Rage) {
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Wisdom, amount, original_adventurer
            );
            return (updated_adventurer,);
        }
        if (item.Suffix == ItemSuffixes.of_Fury) {
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Dexterity, amount, original_adventurer
            );
            return (updated_adventurer,);
        }
        if (item.Suffix == ItemSuffixes.of_Vitriol) {
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Charisma, amount, original_adventurer
            );
            return (updated_adventurer,);
        }
        if (item.Suffix == ItemSuffixes.of_the_Fox) {
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Intelligence, amount, original_adventurer
            );
            return (updated_adventurer,);
        }
        if (item.Suffix == ItemSuffixes.of_Detection) {
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Wisdom, amount, original_adventurer
            );
            return (updated_adventurer,);
        }
        if (item.Suffix == ItemSuffixes.of_Reflection) {
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Wisdom, amount, original_adventurer
            );
            return (updated_adventurer,);
        }
        if (item.Suffix == ItemSuffixes.of_the_Twins) {
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Dexterity, amount, original_adventurer
            );
            return (updated_adventurer,);
        }

        return (original_adventurer,);
    }

    // @notice Removes the stat modifier from the adventurer's state based on the item
    // @dev This function is internal and should only be called by other functions in the contract
    // @param item The item to remove the stat modifier for
    // @param original_adventurer The original state of the adventurer
    // @return updated_adventurer The updated state of the adventurer after removing the item stat modifier
    func remove_item_stat_modifier{syscall_ptr: felt*, range_check_ptr}(
        item: Item, original_adventurer: AdventurerDynamic
    ) -> (updated_adventurer: AdventurerDynamic) {
        // Check if the item is jewelry
        let (is_jewlery) = is_item_jewlery(item);
        if (is_jewlery == TRUE) {
            // if so, remove jewlery stat modifier
            let (unpacked_dynamic_adventurer) = remove_jewerly_stat_modifiers(
                item, original_adventurer
            );
            return (unpacked_dynamic_adventurer,);
        }

        // if the item is above greatness 15
        let item_above_greatness_15 = is_le(15, item.Greatness);
        if (item_above_greatness_15 == TRUE) {
            // lookup the stat associated with the item
            let (base_stat) = get_stat_for_item(item, original_adventurer);

            // if the item is greatness 20 or higher
            let item_above_greatness_20 = is_le(20, item.Greatness);
            if (item_above_greatness_20 == TRUE) {
                // remove an additional 1 stat point
                let (updated_dynamic_adventurer) = update_non_jewelery_stat_modifier(
                    item, original_adventurer, base_stat - SUFFIX_STAT_BOOST - 1
                );
                return (updated_dynamic_adventurer,);
            }

            // and remove the stat boost from it
            let (unpacked_dynamic_adventurer) = update_non_jewelery_stat_modifier(
                item, original_adventurer, base_stat - SUFFIX_STAT_BOOST
            );

            return (unpacked_dynamic_adventurer,);
        }

        return (original_adventurer,);
    }

    // @notice Applies the stat modifier from the item to the adventurer's state
    // @dev This function is internal and should only be called by other functions in the contract
    // @param item The item to apply the stat modifier for
    // @param original_adventurer The original state of the adventurer
    // @return updated_adventurer The updated state of the adventurer after applying the item stat modifier
    func apply_item_stat_modifier{syscall_ptr: felt*, range_check_ptr}(
        item: Item, original_adventurer: AdventurerDynamic
    ) -> (update_adventurer: AdventurerDynamic) {
        // Check if the item is jewelry
        let (is_jewlery) = is_item_jewlery(item);
        if (is_jewlery == TRUE) {
            // add jewlery stat modifier
            let (updated_dynamic_adventurer) = add_jewerly_stat_modifiers(
                item, original_adventurer
            );
            return (updated_dynamic_adventurer,);
        }

        // if the item is above greatness 15
        let item_above_greatness_15 = is_le(15, item.Greatness);
        if (item_above_greatness_15 == TRUE) {
            // lookup the stat associated with the item
            let (base_stat) = get_stat_for_item(item, original_adventurer);

            // if the item is greatness 20 or higher
            let item_above_greatness_20 = is_le(20, item.Greatness);
            if (item_above_greatness_20 == TRUE) {
                // add an additional +1 stat boost
                let (updated_dynamic_adventurer) = update_non_jewelery_stat_modifier(
                    item, original_adventurer, base_stat + SUFFIX_STAT_BOOST + 1
                );
                return (updated_dynamic_adventurer,);
            }

            // if item is not greatness 20 or higher, give it standard stat boost
            let (updated_dynamic_adventurer) = update_non_jewelery_stat_modifier(
                item, original_adventurer, base_stat + SUFFIX_STAT_BOOST
            );

            return (updated_dynamic_adventurer,);
        }

        // If the item does not have a stat modifier, return the original adventurer
        return (original_adventurer,);
    }
}
