%lang starknet

from starkware.cairo.common.uint256 import Uint256

from contracts.loot.utils.constants import ModuleIds, ExternalContractIds

from tests.protostar.loot.setup.interfaces import (
    IController, 
    IAdventurer,
    IBeast,
    ILoot, 
    IRealms, 
    ILords
)

struct Contracts {
    account_1: felt,
    controller: felt,
    xoroshiro: felt,
    treasury: felt,
    adventurer: felt,
    beast: felt,
    loot: felt,
    realms: felt,
    lords: felt,
}

const PK1 = 11111;
const PK2 = 22222;
const PK3 = 33333;

// @notice Deploy account
// @param public_key: Public key of the account calling
// @return account_address: Address of the deployed account
func deploy_account{syscall_ptr: felt*, range_check_ptr}(private_key: felt) -> (account_address: felt) {
    alloc_locals;
    local account_address;
    %{
        ids.account_address = deploy_contract("./lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo", 
            [ids.PK1]
        ).contract_address
    %}
    return (account_address,);
}

// @notice Deploy module controller
// @param arbiter: Account mainatining controller
// @param proxy_admin: Account maintaining upgrades
// @return controller_address: Address of the deployed module controller
func deploy_controller{syscall_ptr: felt*, range_check_ptr}(arbiter: felt, proxy_admin: felt) -> (controller_address: felt) {
    alloc_locals;

    local controller_class_hash;
    local controller_address;

    %{
        declared = declare("./contracts/loot/ModuleController.cairo")
        ids.controller_class_hash = declared.class_hash
        ids.controller_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
            [ids.controller_class_hash]
        ).contract_address
    %}
    IController.initializer(controller_address, arbiter, proxy_admin); 
    return (controller_address,);
}


func deploy_all{
    syscall_ptr: felt*, range_check_ptr
}() -> Contracts {
    alloc_locals;

    tempvar contracts: Contracts;

    %{
        ids.contracts.account_1 = deploy_contract("./lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo", 
            [ids.PK1]
        ).contract_address
        declared = declare("./contracts/loot/ModuleController.cairo")
        ids.contracts.controller = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
            [declared.class_hash]
        ).contract_address
        ids
        ids.contracts.xoroshiro = deploy_contract("./contracts/utils/xoroshiro128_starstar.cairo", 
            [123]
        ).contract_address
        ids.contracts.treasury = deploy_contract("./lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo", 
            [ids.PK2]
        ).contract_address
        declared = declare("./contracts/loot/adventurer/Adventurer.cairo")
        ids.contracts.adventurer = deploy_contract("./contracts/settling_game/proxy/PROXY_LOGIC.cairo",
            [declared.class_hash]
        ).contract_address
        declared = declare("./contracts/loot/beast/Beast.cairo")
        ids.contracts.beast = deploy_contract("./contracts/settling_game/proxy/PROXY_LOGIC.cairo",
            [declared.class_hash]
        ).contract_address
        declared = declare("./contracts/loot/loot/Loot.cairo")
        ids.contracts.loot = deploy_contract("./contracts/settling_game/proxy/PROXY_LOGIC.cairo",
            [declared.class_hash]
        ).contract_address
        declared = declare("./contracts/settling_game/tokens/Realms_ERC721_Mintable.cairo")
        ids.contracts.realms = deploy_contract("./contracts/settling_game/proxy/PROXY_LOGIC.cairo",
            [declared.class_hash]
        ).contract_address
        declared = declare("./contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo")
        ids.contracts.lords = deploy_contract("./contracts/settling_game/proxy/PROXY_LOGIC.cairo",
            [declared.class_hash]
        ).contract_address
        stop_prank_controller = start_prank(ids.contracts.account_1, ids.contracts.controller)
    %}
    IController.initializer(contracts.controller, contracts.account_1, contracts.account_1);
    IController.set_xoroshiro(contracts.controller, contracts.xoroshiro);
    IController.set_address_for_external_contract(contracts.controller, ExternalContractIds.Treasury, contracts.treasury);

    IAdventurer.initializer(contracts.adventurer, 1, 1, contracts.controller, contracts.account_1);
    IController.set_address_for_module_id(contracts.controller, ModuleIds.Adventurer, contracts.adventurer);
    IController.set_write_access(contracts.controller, ModuleIds.Adventurer, ModuleIds.Loot);
    IController.set_write_access(contracts.controller, ModuleIds.Adventurer, ModuleIds.Beast);

    IBeast.initializer(contracts.beast, contracts.controller, contracts.account_1);
    IController.set_address_for_module_id(contracts.controller, ModuleIds.Beast, contracts.beast);
    IController.set_write_access(contracts.controller, ModuleIds.Beast, ModuleIds.Adventurer);
    IController.set_write_access(contracts.controller, ModuleIds.Beast, ModuleIds.Loot);

    ILoot.initializer(contracts.loot, 1, 1, contracts.controller, contracts.account_1);
    IController.set_address_for_module_id(contracts.controller, ModuleIds.Loot, contracts.loot);
    IController.set_write_access(contracts.controller, ModuleIds.Loot, ModuleIds.Adventurer);

    IRealms.initializer(contracts.realms, 1, 1, contracts.account_1);
    ILords.initializer(contracts.lords, 1, 1, 18, Uint256(100000000000000000000, 0), contracts.account_1, contracts.account_1);
    IController.set_address_for_external_contract(contracts.controller, ExternalContractIds.Realms, contracts.realms);
    IController.set_address_for_external_contract(contracts.controller, ExternalContractIds.Lords, contracts.lords);

    %{
        stop_prank_controller()
    %}

    return contracts;
}