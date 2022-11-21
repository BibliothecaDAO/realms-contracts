%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from starkware.cairo.common.pow import pow
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from contracts.loot.constants.item import Item, ItemIds, ItemType, ItemSlot, ItemMaterial, State
from contracts.loot.constants.rankings import ItemRank
from contracts.loot.constants.combat import WeaponEfficacy
from contracts.loot.constants.beast import Beast, BeastAttackType, BeastIds
from contracts.loot.constants.obstacle import Obstacle, ObstacleConstants
from contracts.loot.loot.stats.combat import CombatStats
from tests.protostar.loot.test_structs import TestUtils

@external
func test_weapon_vs_armor_efficacy{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    // ---------------------------------------------------------
    // Weapons
    // ---------------------------------------------------------
    // Blade vs Metal inflicts minimal damage
    let (blade_vs_metal) = CombatStats.weapon_vs_armor_efficacy(
        ItemType.Katana, ItemType.OrnateChestplate
    );
    assert blade_vs_metal = WeaponEfficacy.Low;
    // Blade vs Hide inflicts normal damage
    let (blade_vs_hide) = CombatStats.weapon_vs_armor_efficacy(
        ItemType.ShortSword, ItemType.HardLeatherArmor
    );
    assert blade_vs_hide = WeaponEfficacy.Medium;
    // Blade vs Cloth inflicts high damage
    let (blade_vs_cloth) = CombatStats.weapon_vs_armor_efficacy(
        ItemType.LongSword, ItemType.DivineRobe
    );
    assert blade_vs_cloth = WeaponEfficacy.High;

    // Bludgeon vs Metal inflicts normal damage
    let (bludgeon_vs_metal) = CombatStats.weapon_vs_armor_efficacy(
        ItemType.Maul, ItemType.HolyChestplate
    );
    assert bludgeon_vs_metal = WeaponEfficacy.Medium;
    // Bludgeon vs Hide  inflicts high damage
    let (bludgeon_vs_hide) = CombatStats.weapon_vs_armor_efficacy(
        ItemType.Mace, ItemType.HardLeatherArmor
    );
    assert bludgeon_vs_hide = WeaponEfficacy.High;
    // Bludgeon vs Cloth inflicts low damage
    let (bludgeon_vs_cloth) = CombatStats.weapon_vs_armor_efficacy(
        ItemType.Warhammer, ItemType.LinenRobe
    );
    assert bludgeon_vs_cloth = WeaponEfficacy.Low;

    // Magic vs Metal  inflicts high damage
    let (magic_vs_metal) = CombatStats.weapon_vs_armor_efficacy(
        ItemType.Grimoire, ItemType.RingMail
    );
    assert magic_vs_metal = WeaponEfficacy.High;
    // Magic vs Hide inflicts low damage
    let (magic_vs_hide) = CombatStats.weapon_vs_armor_efficacy(
        ItemType.GraveWand, ItemType.DragonskinArmor
    );
    assert magic_vs_hide = WeaponEfficacy.Low;
    // Magic vs Cloth inflicts normal damage
    let (magic_vs_cloth) = CombatStats.weapon_vs_armor_efficacy(ItemType.GhostWand, ItemType.Shirt);
    assert magic_vs_cloth = WeaponEfficacy.Medium;
    // ---------------------------------------------------------

    // ---------------------------------------------------------
    // Obstacles
    // ---------------------------------------------------------
    // Magic Obstacle vs metal is highly effective
    let (magic_obstacle_vs_metal) = CombatStats.weapon_vs_armor_efficacy(
        ObstacleConstants.ObstacleType.DemonicAlter, ItemType.RingMail
    );
    assert magic_obstacle_vs_metal = WeaponEfficacy.High;

    // Sharp Obstacle vs metal is minimally effective
    let (sharp_obstacle_vs_metal) = CombatStats.weapon_vs_armor_efficacy(
        ObstacleConstants.ObstacleType.HiddenArrow, ItemType.HolyChestplate
    );
    assert sharp_obstacle_vs_metal = WeaponEfficacy.Low;

    // Blunt Obstacle vs metal deals normal damage
    let (blunt_obstacle_vs_metal) = CombatStats.weapon_vs_armor_efficacy(
        ObstacleConstants.ObstacleType.SwingingLogs, ItemType.OrnateChestplate
    );
    assert blunt_obstacle_vs_metal = WeaponEfficacy.Medium;
    // ---------------------------------------------------------

    // ---------------------------------------------------------
    // Beasts
    // ---------------------------------------------------------
    // Sharp beasts vs cloth is highly effective
    let (sharp_beast_vs_cloth) = CombatStats.weapon_vs_armor_efficacy(
        BeastAttackType.Vampire, ItemType.DivineRobe
    );
    assert sharp_beast_vs_cloth = WeaponEfficacy.High;

    // Sharp beasts vs metal is minimally effective
    let (sharp_beast_vs_metal) = CombatStats.weapon_vs_armor_efficacy(
        BeastAttackType.Spider, ItemType.RingMail
    );
    assert sharp_beast_vs_metal = WeaponEfficacy.Low;

    // Sharp beasts vs hide deals normal damage
    let (sharp_beast_vs_hide) = CombatStats.weapon_vs_armor_efficacy(
        BeastAttackType.Werewolf, ItemType.DragonskinArmor
    );
    assert sharp_beast_vs_hide = WeaponEfficacy.Medium;
    // ---------------------------------------------------------

    return ();
}

@external
func test_calculate_damage_from_weapon{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    // greatness 20 katana vs greatness 0 shirt
    // max damage - gg
    let (g20_katana) = TestUtils.create_item(ItemIds.Katana, 20);
    let (g0_shirt) = TestUtils.create_item(ItemIds.Shirt, 0);
    let (katana_vs_shirt) = CombatStats.calculate_damage_from_weapon(g20_katana, g0_shirt);
    assert katana_vs_shirt = 300;

    // greatness 3 short sword vs greatness 18 holy chestplate
    // zero damage - "Tis but a scratch"
    let (g3_short_sword) = TestUtils.create_item(ItemIds.ShortSword, 3);
    let (g18_holy_chestplate) = TestUtils.create_item(ItemIds.HolyChestplate, 18);
    let (holy_chestplate_vs_short_sword) = CombatStats.calculate_damage_from_weapon(
        g3_short_sword, g18_holy_chestplate
    );
    assert holy_chestplate_vs_short_sword = 0;

    return ();
}

@external
func test_calculate_damage_from_beast{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    // greatness 20 orc vs greatness 0 shirt (oof)
    let (orc) = TestUtils.create_beast(BeastIds.Orc, 20);
    let (shirt) = TestUtils.create_item(ItemIds.Shirt, 0);
    let (orc_vs_shirt) = CombatStats.calculate_damage_from_beast(orc, shirt);
    assert orc_vs_shirt = 60;

    // greatness 10 giant vs greatness 10 leather armor
    let (leather) = TestUtils.create_item(ItemIds.LeatherArmor, 10);
    let (giant) = TestUtils.create_beast(BeastIds.Giant, 10);
    let (giant_vs_leather) = CombatStats.calculate_damage_from_beast(orc, leather);
    assert giant_vs_leather = 170;

    return ();
}

@external
func test_calculate_damage_from_obstacle{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    // greatness 0 ring mail vs greatness 20 demonic alter
    // max damage - gg
    let (g0_ring_mail) = TestUtils.create_item(ItemIds.RingMail, 0);
    let (g20_demonic_alter) = TestUtils.create_obstacle(ObstacleConstants.ObstacleIds.DemonicAlter, 20);
    let (ring_mail_vs_demonic_alter) = CombatStats.calculate_damage_from_obstacle(
        g20_demonic_alter, g0_ring_mail
    );
    assert ring_mail_vs_demonic_alter = 300;

    // greatness 20 demonhusk vs greatness 0 dark midst
    // min damage - "You call this an obstacle!? This mist is soothing on my demon flesh"
    let (g20_demonhusk) = TestUtils.create_item(ItemIds.DemonHusk, 20);
    let (g0_dark_mist) = TestUtils.create_obstacle(ObstacleConstants.ObstacleIds.DarkMist, 0);
    let (demonhusk_vs_dark_mist) = CombatStats.calculate_damage_from_obstacle(
        g0_dark_mist, g20_demonhusk
    );
    assert demonhusk_vs_dark_mist = 0;

    return ();
}
