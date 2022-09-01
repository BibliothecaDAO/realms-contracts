# ____TRAVEL
#   Logic for travel
#   Assets must exist on the same point in space in order to interact with each other.
#
# MIT License

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    get_tx_info,
    get_contract_address,
)

from contracts.settling_game.utils.game_structs import TravelInformation

@storage_var
func travel_information(traveller_asset_id : felt, traveller : Uint256) -> (
    travel_information : TravelInformation
):
end

# @traveller_asset_id: ContractId
# @traveller: Asset moving (Realm, Adventurer)
# @destination_asset_id: ContractId
# @destination: Destination
@external
func travel{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    traveller_asset_id : felt,
    traveller : Uint256,
    destination_asset_id : felt,
    destination : Uint256,
):
    alloc_locals

    let (now) = get_block_timestamp()

    # check owner of asset calling the traveller_asset_id

    # get distance between two points

    # set travel_information
    travel_information.write(
        traveller_asset_id, traveller, TravelInformation(destination, destination_asset_id, now)
    )

    return ()
end
