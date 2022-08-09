# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.messages import send_message_to_l1
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem
from starkware.cairo.common.uint256 import Uint256, uint256_le
from contracts.loot.adventurer.library import CalculateAdventurer
from contracts.loot.item.constants import (
    ItemAgility,
    Item,
    ItemSlot,
    ItemClass,
    Adventurer,
    PackedAdventurerStats,
    AdventurerState,
)

@storage_var
func storage_adventurer(token_id : Uint256) -> (adventurer : PackedAdventurerStats):
end

@external
func get_adventurer{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256) -> (adventurer : AdventurerState):
    let (unpacked_adventurer : PackedAdventurerStats) = storage_adventurer.read(token_id)

    # import and use namespace __unpack_adventurer
    let (adventurer) = CalculateAdventurer._unpack_adventurer(unpacked_adventurer)

    return (adventurer)
end
