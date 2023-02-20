from collections import namedtuple

Adventurer = namedtuple(
    'Adventurer',
    'health level strength dexterity vitality intelligence wisdom charisma luck xp '
   	'weapon_id chest_id head_id waist_id feet_id hands_id neck_id ring_id status beast upgrading',
)


def build_adventurer(
    	health, level, strength, dexterity, vitality, intelligence, wisdom, charisma, luck, xp, 
    	weapon_id, chest_id, head_id, waist_id, feet_id, hands_id, neck_id, ring_id, status, beast, upgrading
  ) -> Adventurer:
    
  return Adventurer(
    *[
    	health, level, strength, dexterity, vitality, intelligence, wisdom, charisma, luck, xp, 
      	weapon_id, chest_id, head_id, waist_id, feet_id, hands_id, neck_id, ring_id, status, beast, upgrading
    ])

def build_adventurer_level(level) -> Adventurer:
   
    return Adventurer(
    *[
    	100, level, 1, 1, 1, 1, 1, 1, 1, 0, 
      	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    ])


def pack_adventurer(adventurer: Adventurer):
    packed_1 = (
        adventurer.health * 2**0
        + adventurer.level * 2**10
        + adventurer.strength * 2**20
        + adventurer.dexterity * 2**30
        + adventurer.vitality * 2**40
        + adventurer.intelligence * 2**50
        + adventurer.wisdom * 2**60
        + adventurer.charisma * 2**70
        + adventurer.luck * 2**80
        + adventurer.xp * 2**90
    )
    packed_2 = (
       adventurer.weapon_id * 2**0
       + adventurer.chest_id * 2**41,
       + adventurer.head_id * 2**82,
       + adventurer.waist_id * 2**123,
	)
    packed_3 = (
       adventurer.feet_id * 2**0
       + adventurer.hands_id * 2**41,
       + adventurer.neck_id * 2**82,
       + adventurer.ring_id * 2**123,
	)
    packed_4 = (
       adventurer.status * 2**0
       + adventurer.beast * 2**3,
       + adventurer.upgrading * 2**44,
	)
    return packed_1, packed_2, packed_3, packed_4