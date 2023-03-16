%lang starknet
// starkware
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_contract_address

// settling game
from contracts.settling_game.modules.bastions.bastions import (
    spawn_bastions,
    set_bastion_location_cooldown,
    set_bastion_bonus_type,
    set_bastion_moving_times,
)
from contracts.settling_game.ModuleController import get_arbiter, get_module_address
from contracts.settling_game.utils.game_structs import (
    TravelInformation,
    ExternalContractIds,
    Point,
    ModuleIds,
)
from contracts.settling_game.modules.travel.travel import set_coordinates

@external
func test_spawn_bastions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    let (local self_address) = get_contract_address();

    // setup permissions
    %{ store(ids.self_address, "module_controller_address", [ids.self_address]) %}
    %{ store(ids.self_address, "arbiter", [ids.self_address]) %}
    %{ store(ids.self_address, "address_of_module_id", [ids.self_address], [ids.ModuleIds.Travel]) %}
    %{ store(ids.self_address, "Proxy_admin", [ids.self_address]) %}

    let (points: Point*) = alloc();
    assert points[0] = Point(1, 2);
    assert points[1] = Point(3, 4);

    let (bonus_types: felt*) = alloc();
    assert bonus_types[0] = 1;
    assert bonus_types[1] = 2;

    %{ stop_prank_callable = start_prank(caller_address=ids.self_address) %}
    spawn_bastions(
        points_len=2, points=points, bonus_types_len=2, bonus_types=bonus_types, grid_dimension=4
    );

    %{
        # check bastions
        bastion_1_bonus_type = load(ids.self_address, "bastion_bonus_type", "felt", [1, 2])[0]
        assert bastion_1_bonus_type == 1
        bastion_2_bonus_type = load(ids.self_address, "bastion_bonus_type", "felt", [3, 4])[0]
        assert bastion_2_bonus_type == 2

        # check coordinates
        bastion_1_id = (1*4) + 2
        bastion_1_coordinates = load(ids.self_address, "coordinates", "Point", [ids.ModuleIds.Bastions, bastion_1_id, 0, 0]),
        assert bastion_1_coordinates == ([1, 2],)
        bastion_2_id = (3*4) + 4
        bastion_2_coordinates = load(ids.self_address, "coordinates", "Point", [ids.ModuleIds.Bastions, bastion_2_id, 0, 0]),
        assert bastion_2_coordinates == ([3, 4],)
    %}

    return ();
}

@external
func test_deploy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    let (local self_address) = get_contract_address();
    local bastions_address;
    %{ ids.bastions_address = deploy_contract('contracts/settling_game/modules/bastions/Bastions.cairo').contract_address %}
    return ();
}

@external
func test_set_bastion_location_cooldown{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    let (local self_address) = get_contract_address();
    set_bastion_location_cooldown(10, 1);
    %{
        cooldown_period = load(ids.self_address, "bastion_location_cooldown_period", "felt", [1])[0]
        assert cooldown_period == 10
    %}
    return ();
}

@external
func test_set_bastion_bonus_type{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> () {
    alloc_locals;
    let (local self_address) = get_contract_address();
    set_bastion_bonus_type(Point(1, 1), 1);
    %{
        bonus_type = load(ids.self_address, "bastion_bonus_type", "felt", [1, 1])[0]
        assert bonus_type == 1
    %}
    return ();
}

@external
func test_set_bastion_moving_times{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> () {
    alloc_locals;
    let (local self_address) = get_contract_address();
    set_bastion_moving_times(1, 10);
    %{
        move_time = load(ids.self_address, "bastion_moving_times", "felt", [1])[0]
        assert move_time == 10
    %}
    return ();
}
