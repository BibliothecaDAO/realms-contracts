%lang starknet

from starkware.starknet.common.syscalls import get_contract_address, get_block_number
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from contracts.settling_game.utils.game_structs import ExternalContractIds, ModuleIds
from contracts.settling_game.modules.bastions.constants import MovingTimes

const X = 3;
const Y = 4;

const ARMY_ID_1 = 1;
const ARMY_ID_2 = 2;

const ORDER_OF_GIANTS = 2;
const ORDER_OF_RAGE = 10;
const ORDER_OF_FURY = 11;

// ORDER OF GIANTS
const REALM_ID_1 = 1;
const REALM_DATA_1 = 40564819207303341694527483217926;  // realm 1: order of giants

const REALM_ID_2 = 2;
const REALM_DATA_2 = 40564819207303340854496404575491;  // realm 20: order of giants

// ORDER OF RAGE
const REALM_ID_3 = 3;
const REALM_DATA_3 = 202824096036516993033911502441218;  // realm 3: order of rage

const REALM_ID_4 = 4;
const REALM_DATA_4 = 202824096041331521743613694971653;  // realm 107: order of rage

// ORDER OF FURY
const REALM_ID_5 = 5;
const REALM_DATA_5 = 223106505663891104000887212282119;  // realm 102: order of fury

const REALM_ID_6 = 6;
const REALM_DATA_6 = 223106505640169024313176976593412;  // realm 114: order of fury

const BONUS_TYPE = 11;

// 2 minutes
const TOWER_COOLDOWN_PERIOD = 2;
// 2 hours => 120 blocks
const CENTRAL_SQUARE_COOLDOWN_PERIOD = 120;

// staging are
const STAGING_AREA_ID = 0;

// towers
const TOWER_1_ID = 1;
const TOWER_2_ID = 2;
const TOWER_3_ID = 3;
const TOWER_4_ID = 4;

// central square
const CENTRAL_SQUARE_ID = 5;

func setup{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    alloc_locals;

    // set block number to 0
    %{ stop_roll = roll(0) %}

    let (local self_address) = get_contract_address();
    %{ context.self_address = ids.self_address %}

    // put one bastion in the storage by instantiating bastion_bonus_type
    %{ store(ids.self_address, "bastion_bonus_type", [ids.BONUS_TYPE], [ids.X, ids.Y]) %}

    // set moving times
    // assuming 1 block = 1 minute
    %{ store(ids.self_address, "bastion_moving_times", [35], [ids.MovingTimes.DistanceStagingAreaCentralSquare]) %}
    %{ store(ids.self_address, "bastion_moving_times", [10], [ids.MovingTimes.DistanceTowerCentralSquare]) %}
    %{ store(ids.self_address, "bastion_moving_times", [10], [ids.MovingTimes.DistanceTowerTowerSameOrder]) %}
    %{ store(ids.self_address, "bastion_moving_times", [25], [ids.MovingTimes.DistanceTowerTowerDifferentOrder]) %}
    %{ store(ids.self_address, "bastion_moving_times", [25], [ids.MovingTimes.DistanceStagingAreaTower]) %}

    // set cooldown periods
    %{ store(ids.self_address, "bastion_location_cooldown_period", [ids.TOWER_COOLDOWN_PERIOD], [ids.TOWER_1_ID]) %}
    %{ store(ids.self_address, "bastion_location_cooldown_period", [ids.TOWER_COOLDOWN_PERIOD], [ids.TOWER_2_ID]) %}
    %{ store(ids.self_address, "bastion_location_cooldown_period", [ids.TOWER_COOLDOWN_PERIOD], [ids.TOWER_3_ID]) %}
    %{ store(ids.self_address, "bastion_location_cooldown_period", [ids.TOWER_COOLDOWN_PERIOD], [ids.TOWER_4_ID]) %}
    %{ store(ids.self_address, "bastion_location_cooldown_period", [ids.CENTRAL_SQUARE_COOLDOWN_PERIOD], [ids.CENTRAL_SQUARE_ID]) %}

    // Module Controller
    // module address
    %{ store(ids.self_address, "module_controller_address", [ids.self_address]) %}
    %{ store(ids.self_address, "address_of_module_id", [ids.self_address], [ids.ModuleIds.Travel]) %}
    %{ store(ids.self_address, "address_of_module_id", [ids.self_address], [ids.ModuleIds.L06_Combat]) %}
    %{ store(ids.self_address, "address_of_module_id", [ids.self_address], [ids.ModuleIds.Realms_Token]) %}
    %{ store(ids.self_address, "address_of_module_id", [ids.self_address], [ids.ModuleIds.Bastions]) %}
    // external contract address
    %{ store(ids.self_address, "external_contract_table", [ids.self_address], [ids.ExternalContractIds.Realms]) %}
    %{ store(ids.self_address, "external_contract_table", [ids.self_address], [ids.ExternalContractIds.S_Realms]) %}
    // set proxy admin
    %{ store(ids.self_address, "Proxy_admin", [ids.self_address]) %}

    // Realms
    // set realms data
    %{ store(ids.self_address, "realm_data", [ids.REALM_DATA_1], [ids.REALM_ID_1, 0]) %}
    %{ store(ids.self_address, "realm_data", [ids.REALM_DATA_2], [ids.REALM_ID_2, 0]) %}
    %{ store(ids.self_address, "realm_data", [ids.REALM_DATA_3], [ids.REALM_ID_3, 0]) %}
    %{ store(ids.self_address, "realm_data", [ids.REALM_DATA_4], [ids.REALM_ID_4, 0]) %}
    %{ store(ids.self_address, "realm_data", [ids.REALM_DATA_5], [ids.REALM_ID_5, 0]) %}
    %{ store(ids.self_address, "realm_data", [ids.REALM_DATA_6], [ids.REALM_ID_6, 0]) %}
    // define self_address owner of relms
    %{ store(ids.self_address, "ERC721_owners", [ids.self_address], [ids.REALM_ID_1, 0]) %}
    %{ store(ids.self_address, "ERC721_owners", [ids.self_address], [ids.REALM_ID_2, 0]) %}
    %{ store(ids.self_address, "ERC721_owners", [ids.self_address], [ids.REALM_ID_3, 0]) %}
    %{ store(ids.self_address, "ERC721_owners", [ids.self_address], [ids.REALM_ID_4, 0]) %}
    %{ store(ids.self_address, "ERC721_owners", [ids.self_address], [ids.REALM_ID_5, 0]) %}
    %{ store(ids.self_address, "ERC721_owners", [ids.self_address], [ids.REALM_ID_6, 0]) %}

    return ();
}
