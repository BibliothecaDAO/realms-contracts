# Loot Survivor

This is a fork of the OG Loot physics to show how a minigame can be created.

This is experimental. Put a Fork in it.

#### TODO High priority:
- ADD Statistics Points
-- At XP level - spend points onto a Stat level
-- Health Shop - Bid style


#### TODO Low priority:
- Multipler damage for adventurer Level. The Adventurer should both, deal more damange and receive more damage. 

### Objective

Get the highest gold balance without dying.... Do you dare? You can always stop on top


### How to play

First mint an Adventurer

```
nile mint_adventurer_with_item
```

You now have an adventurer - see them with:

```
nile get_adventurer 7

_____________________*+ loaf +*______________________
_____________________________________________________

| Race : 1                                 | HomeRealm : 1                            
| Birthdate : 1676262189                   | Name : 1819238758                        
| Order : 1                                | ImageHash1 : 123                         
| ImageHash2 : 123                         | Health : 100                             
| Level : 1                                | Strength : 0                             
| Dexterity : 0                            | Vitality : 0                             
| Intelligence : 0                         | Wisdom : 0                               
| Charisma : 0                             | Luck : 0                                 
| XP : 0                                   | WeaponId : 0                             
| ChestId : 0                              | HeadId : 0                               
| WaistId : 0                              | FeetId : 0                               
| HandsId : 0                              | NeckId : 6                               
| RingId : 0                               | Status :  
| Beast : 0
```



You can do three things, choose wisely

### Explore

This is like searching the long grass in pokemon... You might discover a Beast... You might discover gold... You might discover a trap

Once you have discovered - you can flee or fight. If you flee you might get hurt.

```
nile explore

🤔 You discovered nothing

try again....
```

### Fight



### Buy

There is a native dynamic loot market. However there are some rules.

- Items are not tradable from an Adventurer. They are soul bound to that Character.
- Items can be rerolled every 6hrs by anyone. It is an open function and the Adventurer who rolls it gets 3 gold.
- When rerolled the past Items that have not been purchased are no longer purchasable.
- You must bid on an Item above the minimum bid, currently (3)
- You must claim your item after you have won the bid


# LORDS


### Statistics

|   Type   |  Metal  |  Hide  | Cloth |
| :------: | :-----: | :----: | :---: |
|  Blade   |   Low   | Medium | Strong|
| Bludgeon | Medium  | Strong |  Low  |
|  Magic   |   High  |  Low   |Medium |

Blade: 
    low vs metal
    medium vs hide
    strong vs cloth
Bludgeon:
    medium vs metal
    strong vs hide
    low vs cloth
Magic:
    High vs metal
    Low vs hide
    Medium vs cloth