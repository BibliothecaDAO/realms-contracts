%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_equal

from contracts.loot.constants.item import ItemIds, ItemNamePrefixes, ItemNameSuffixes, ItemSuffixes
from contracts.loot.loot.library import ItemLib
from contracts.loot.loot.stats.item import ItemStats
from contracts.loot.loot.LootMarketArcade import get_charsima_adjusted_bid

@external
func setup_generate_name_prefix{syscall_ptr: felt*, range_check_ptr}() {
    %{
        given(
            rnd = strategy.integers(1, 101),
        )
    %}
    return ();
}

@external
func test_generate_name_prefix{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rnd: felt
) {
    alloc_locals;

    // https://github.com/Anish-Agnihotri/dhof-loot/blob/master/output/occurences.json
    // is a good resource for verifying Loot item name info

    // Katanas can only receive the following name prefixes:
    // { Armageddon, Blight, Brimstone, Cataclysm, Corruption, Demon, Dread, Eagle, Foe, Gloom, Grim, Honour, Kraken
    //   Mind, Oblivion, Pandemonium, Rage, Skull, Sorrow, Tempest, Victory, Woe }
    let (katana_name_prefix) = ItemLib.generate_name_prefix(ItemIds.Katana, rnd);

    // Verify function worked by asserting it did not return any of the names not in the above list
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Agony);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Apocalypse);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Beast);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Behemoth);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Blood);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Bramble);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Brood);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Carrion);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Chimeric);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Corpse);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Damnation);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Death);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Dire);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Dragon);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Doom);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Dusk);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Empyrean);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Fate);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Gale);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Ghoul);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Glyph);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Golem);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Hate);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Havoc);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Horror);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Hypnotic);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Loath);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Maelstrom);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Miracle);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Morbid);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Onslaught);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Pain);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Phoenix);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Plague);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Rapture);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Rune);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Sol);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Soul);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Spirit);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Storm);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Torment);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Vengeance);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Viper);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Vortex);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Wrath);
    assert_not_equal(katana_name_prefix, ItemNamePrefixes.Lights);

    let (divine_hood_name_prefix) = ItemLib.generate_name_prefix(ItemIds.DivineHood, rnd);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Agony);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Apocalypse);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Beast);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Behemoth);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Blood);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Bramble);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Brood);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Carrion);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Chimeric);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Corpse);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Damnation);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Death);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Dire);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Dragon);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Doom);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Dusk);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Empyrean);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Fate);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Gale);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Ghoul);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Glyph);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Golem);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Hate);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Havoc);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Horror);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Hypnotic);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Loath);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Maelstrom);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Miracle);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Morbid);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Onslaught);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Pain);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Phoenix);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Plague);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Rapture);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Rune);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Sol);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Soul);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Spirit);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Storm);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Torment);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Vengeance);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Viper);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Vortex);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Wrath);
    assert_not_equal(divine_hood_name_prefix, ItemNamePrefixes.Lights);

    let (demonhide_belt_name_prefix) = ItemLib.generate_name_prefix(ItemIds.DemonhideBelt, rnd);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Agony);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Apocalypse);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Beast);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Behemoth);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Blood);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Bramble);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Brood);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Carrion);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Chimeric);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Corpse);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Damnation);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Death);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Dire);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Dragon);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Doom);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Dusk);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Empyrean);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Fate);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Gale);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Ghoul);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Glyph);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Golem);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Hate);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Havoc);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Horror);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Hypnotic);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Loath);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Maelstrom);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Miracle);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Morbid);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Onslaught);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Pain);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Phoenix);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Plague);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Rapture);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Rune);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Sol);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Soul);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Spirit);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Storm);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Torment);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Vengeance);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Viper);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Vortex);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Wrath);
    assert_not_equal(demonhide_belt_name_prefix, ItemNamePrefixes.Lights);

    return ();
}

@external
func setup_generate_name_suffix{syscall_ptr: felt*, range_check_ptr}() {
    %{
        given(
            rnd = strategy.integers(1, 101),
        )
    %}
    return ();
}

@external
func test_generate_name_suffix{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rnd: felt
) {
    alloc_locals;

    // https://github.com/Anish-Agnihotri/dhof-loot/blob/master/output/occurences.json
    // is a good resource for verifying Loot item name info

    // Katanas are always "X Grasp" Katana of Y
    let (katana_name_suffix) = ItemLib.generate_name_suffix(ItemIds.Katana, rnd);
    assert katana_name_suffix = ItemNameSuffixes.Grasp;
    let (katana_name_suffix2) = ItemLib.generate_name_suffix(ItemIds.Katana, 2);
    assert katana_name_suffix2 = ItemNameSuffixes.Grasp;
    let (katana_name_suffix3) = ItemLib.generate_name_suffix(ItemIds.Katana, 3);
    assert katana_name_suffix3 = ItemNameSuffixes.Grasp;
    let (katana_name_suffix4) = ItemLib.generate_name_suffix(ItemIds.Katana, 4);
    assert katana_name_suffix4 = ItemNameSuffixes.Grasp;
    let (katana_name_suffix5) = ItemLib.generate_name_suffix(ItemIds.Katana, 5);
    assert katana_name_suffix5 = ItemNameSuffixes.Grasp;
    let (katana_name_suffix6) = ItemLib.generate_name_suffix(ItemIds.Katana, 6);
    assert katana_name_suffix6 = ItemNameSuffixes.Grasp;
    let (katana_name_suffix7) = ItemLib.generate_name_suffix(ItemIds.Katana, 7);
    assert katana_name_suffix7 = ItemNameSuffixes.Grasp;
    let (katana_name_suffix8) = ItemLib.generate_name_suffix(ItemIds.Katana, 8);
    assert katana_name_suffix8 = ItemNameSuffixes.Grasp;

    // Grimoires are always "X Peak" Grimoire of Y
    let (grimoire_name_suffix) = ItemLib.generate_name_suffix(ItemIds.Grimoire, rnd);
    assert grimoire_name_suffix = ItemNameSuffixes.Peak;
    let (grimoire_name_suffix2) = ItemLib.generate_name_suffix(ItemIds.Grimoire, 2);
    assert grimoire_name_suffix2 = ItemNameSuffixes.Peak;
    let (grimoire_name_suffix3) = ItemLib.generate_name_suffix(ItemIds.Grimoire, 3);
    assert grimoire_name_suffix3 = ItemNameSuffixes.Peak;
    let (grimoire_name_suffix4) = ItemLib.generate_name_suffix(ItemIds.Grimoire, 4);
    assert grimoire_name_suffix4 = ItemNameSuffixes.Peak;
    let (grimoire_name_suffix5) = ItemLib.generate_name_suffix(ItemIds.Grimoire, 5);
    assert grimoire_name_suffix5 = ItemNameSuffixes.Peak;

    // Warhammers are always "X Bane" Warhammer of Y
    let (warhammer_name_suffix) = ItemLib.generate_name_suffix(ItemIds.Warhammer, rnd);
    assert warhammer_name_suffix = ItemNameSuffixes.Bane;
    let (warhammer_name_suffix2) = ItemLib.generate_name_suffix(ItemIds.Warhammer, 2);
    assert warhammer_name_suffix2 = ItemNameSuffixes.Bane;
    let (warhammer_name_suffix3) = ItemLib.generate_name_suffix(ItemIds.Warhammer, 3);
    assert warhammer_name_suffix3 = ItemNameSuffixes.Bane;
    let (warhammer_name_suffix4) = ItemLib.generate_name_suffix(ItemIds.Warhammer, 4);
    assert warhammer_name_suffix4 = ItemNameSuffixes.Bane;
    let (warhammer_name_suffix5) = ItemLib.generate_name_suffix(ItemIds.Warhammer, 5);
    assert warhammer_name_suffix5 = ItemNameSuffixes.Bane;

    // Ghost Wands are always "X Whisper" Warhammer of Y
    let (ghostwand_name_suffix) = ItemLib.generate_name_suffix(ItemIds.GhostWand, rnd);
    assert ghostwand_name_suffix = ItemNameSuffixes.Whisper;
    let (ghostwand_name_suffix2) = ItemLib.generate_name_suffix(ItemIds.GhostWand, 2);
    assert ghostwand_name_suffix2 = ItemNameSuffixes.Whisper;
    let (ghostwand_name_suffix3) = ItemLib.generate_name_suffix(ItemIds.GhostWand, 3);
    assert ghostwand_name_suffix3 = ItemNameSuffixes.Whisper;
    let (ghostwand_name_suffix4) = ItemLib.generate_name_suffix(ItemIds.GhostWand, 4);
    assert ghostwand_name_suffix4 = ItemNameSuffixes.Whisper;
    let (ghostwand_name_suffix5) = ItemLib.generate_name_suffix(ItemIds.GhostWand, 5);
    assert ghostwand_name_suffix5 = ItemNameSuffixes.Whisper;

    // Divine Hoods can have {Bender, Grasp, Moon, Peak, Shout, Bite} for their name suffix
    // so we assert function does not return any of the other name suffixes
    let (divine_hood_name_suffix) = ItemLib.generate_name_suffix(ItemIds.DivineHood, rnd);
    assert_not_equal(divine_hood_name_suffix, ItemNameSuffixes.Bane);
    assert_not_equal(divine_hood_name_suffix, ItemNameSuffixes.Root);
    assert_not_equal(divine_hood_name_suffix, ItemNameSuffixes.Song);
    assert_not_equal(divine_hood_name_suffix, ItemNameSuffixes.Roar);
    assert_not_equal(divine_hood_name_suffix, ItemNameSuffixes.Instrument);
    assert_not_equal(divine_hood_name_suffix, ItemNameSuffixes.Glow);
    assert_not_equal(divine_hood_name_suffix, ItemNameSuffixes.Shadow);
    assert_not_equal(divine_hood_name_suffix, ItemNameSuffixes.Whisper);
    assert_not_equal(divine_hood_name_suffix, ItemNameSuffixes.Growl);
    assert_not_equal(divine_hood_name_suffix, ItemNameSuffixes.Tear);
    assert_not_equal(divine_hood_name_suffix, ItemNameSuffixes.Form);
    assert_not_equal(divine_hood_name_suffix, ItemNameSuffixes.Sun);

    // Gold Rings can have any of the name suffixes except for {Bane, Instrument, Shadow, Growl, Form, Song}
    let (gold_ring_name_suffix) = ItemLib.generate_name_suffix(ItemIds.GoldRing, rnd);
    assert_not_equal(gold_ring_name_suffix, ItemNameSuffixes.Bane);
    assert_not_equal(gold_ring_name_suffix, ItemNameSuffixes.Song);
    assert_not_equal(gold_ring_name_suffix, ItemNameSuffixes.Instrument);
    assert_not_equal(gold_ring_name_suffix, ItemNameSuffixes.Shadow);
    assert_not_equal(gold_ring_name_suffix, ItemNameSuffixes.Growl);
    assert_not_equal(gold_ring_name_suffix, ItemNameSuffixes.Form);

    return ();
}

@external
func setup_generate_item_suffix{syscall_ptr: felt*, range_check_ptr}() {
    %{
        given(
            rnd = strategy.integers(0, 101),
        )
    %}
    return ();
}

@external
func test_generate_item_suffix{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    rnd: felt
) {
    alloc_locals;

    // https://github.com/Anish-Agnihotri/dhof-loot/blob/master/output/occurences.json
    // is a good resource for verifying Loot item name info

    // Katanas only receive the suffixes/Orders:
    // {of Giants, of Skill, of Brilliance, of Protection, of Rage, of Vitriol, of Detection, of the Twins}
    let (katana_suffix) = ItemLib.generate_item_suffix(ItemIds.Katana, rnd);

    // Verify function works by asserting it did not respond one of the other suffixes/orders
    assert_not_equal(katana_suffix, ItemSuffixes.of_Power);
    assert_not_equal(katana_suffix, ItemSuffixes.of_Titans);
    assert_not_equal(katana_suffix, ItemSuffixes.of_Perfection);
    assert_not_equal(katana_suffix, ItemSuffixes.of_Enlightenment);
    assert_not_equal(katana_suffix, ItemSuffixes.of_Anger);
    assert_not_equal(katana_suffix, ItemSuffixes.of_Fury);
    assert_not_equal(katana_suffix, ItemSuffixes.of_the_Fox);
    assert_not_equal(katana_suffix, ItemSuffixes.of_Reflection);

    // Grimoires only receive the suffixes/Orders:
    // {of Power, of Titans, of Perfection, of Enlightenment, of Anger, of Fury, of the Fox, of Reflection}
    let (grimoire_suffix) = ItemLib.generate_item_suffix(ItemIds.Grimoire, rnd);

    // Verify function works by asserting it did not respond one of the other suffixes/orders
    assert_not_equal(grimoire_suffix, ItemSuffixes.of_Giant);
    assert_not_equal(grimoire_suffix, ItemSuffixes.of_Skill);
    assert_not_equal(grimoire_suffix, ItemSuffixes.of_Brilliance);
    assert_not_equal(grimoire_suffix, ItemSuffixes.of_Protection);
    assert_not_equal(grimoire_suffix, ItemSuffixes.of_Rage);
    assert_not_equal(grimoire_suffix, ItemSuffixes.of_Vitriol);
    assert_not_equal(grimoire_suffix, ItemSuffixes.of_Detection);
    assert_not_equal(grimoire_suffix, ItemSuffixes.of_the_Twins);

    return ();
}

@external
func test_get_charsima_adjusted_bid{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let no_charisma = 0;
    let bid_two = 2;
    let (charisma_adjusted_bid) = get_charsima_adjusted_bid(no_charisma, bid_two);
    assert charisma_adjusted_bid = 2;

    let one_charisma = 1;
    let bid_five = 5;
    let (charisma_adjusted_bid) = get_charsima_adjusted_bid(one_charisma, bid_five);
    assert charisma_adjusted_bid = 8;

    let ten_charisma = 10;
    let ten_bid = 10;
    let (charisma_adjusted_bid) = get_charsima_adjusted_bid(ten_charisma, ten_bid);
    assert charisma_adjusted_bid = 40;

    return ();
}
