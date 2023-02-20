from collections import namedtuple

Adventurer = namedtuple(
    'Adventurer',
    'race home_realm birthdate name order image_hash_1 image_hash_2 health level strength dexterity vitality intelligence wisdom'
    'charisma luck xp weapon_id chest_id head_id waist_id feet_id hands_id neck_id ring_id status beast upgrading',
)


def build_radventurer(
    	race, home_realm, birthdate, name, order, image_hash_1, image_hash_2, health, level, strength, dexterity, vitality, intelligence, 
    	wisdom, charisma, luck, xp, weapon_id, chest_id, head_id, waist_id, feet_id, hands_id, neck_id, ring_id, status, beast, upgrading
  ) -> Adventurer:
    
  return Adventurer(
    *[
    	race, home_realm, birthdate, name, order, image_hash_1, image_hash_2, health, level, strength, dexterity, vitality, intelligence,
    	wisdom, charisma, luck, xp, weapon_id, chest_id, head_id, waist_id, feet_id, hands_id, neck_id, ring_id, status, beast, upgrading
    ])


# def pack_adventurer(realm: Adventurer) -> int:
#     packed = (
#         realm.region * 2**0
#         + realm.cities * 2**8
#         + realm.harbours * 2**16
#         + realm.rivers * 2**24
#         + realm.resource_number * 2**32
#         + realm.resource_1 * 2**40
#         + realm.resource_2 * 2**48
#         + realm.resource_3 * 2**56
#         + realm.resource_4 * 2**64
#         + realm.resource_5 * 2**72
#         + realm.resource_6 * 2**80
#         + realm.resource_7 * 2**88
#         + realm.wonder * 2**96
#         + realm.order * 2**104
#     )
#     return packed
