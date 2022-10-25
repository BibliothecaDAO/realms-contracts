%lang starknet

from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.uint256 import Uint256

from contracts.settling_game.utils.game_structs import ModuleIds, ExternalContractIds

from contracts.settling_game.interfaces.imodules import IModuleController

from contracts.token.constants import (
    IERC1155_ID,
    IERC1155_METADATA_ID,
    IERC1155_RECEIVER_ID,
    IACCOUNT_ID,
    ON_ERC1155_RECEIVED_SELECTOR,
    ON_ERC1155_BATCH_RECEIVED_SELECTOR,
)

@contract_interface
namespace Controller {
    func initializer(arbiter: felt, proxy_admin: felt) {
    }
}

@contract_interface
namespace Module {
    func initializer(controller_address: felt, proxy_admin: felt) {
    }
}

@contract_interface
namespace Crypts {
    func initializer(name: felt, symbol: felt, proxy_admin: felt) {
    }
}

@contract_interface
namespace Lords {
    func initializer(
        name: felt,
        symbol: felt,
        decimals: felt,
        initial_supply: Uint256,
        recipient: felt,
        proxy_admin: felt,
    ) {
    }
}

@contract_interface
namespace Realms {
    func initializer(name: felt, symbol: felt, proxy_admin: felt) {
    }
}

@contract_interface
namespace ResourcesToken {
    func initializer(uri: felt, proxy_admin: felt, controller_address: felt) {
    }
}

@contract_interface
namespace S_Crypts {
    func initializer(name: felt, symbol: felt, proxy_admin: felt) {
    }
}

@contract_interface
namespace S_Realms {
    func initializer(name: felt, symbol: felt, proxy_admin: felt, controller_address: felt) {
    }
}

const E18 = 10 ** 18;

const ERC721_NAME = 0x4e6f47616d6520;
const ERC721_SYMBOL = 0x4f474d302e31;

const URI_LEN = 1;
const URI = 10101010;

const PK = 11111;
const PK2 = 22222;

struct Contracts {
    Settling: felt,
    Resources: felt,
    Buildings: felt,
    Calculator: felt,
    L06_Combat: felt,
    L07_Crypts: felt,
    L08_Crypts_Resources: felt,
    L09_Relics: felt,
    L10_Food: felt,
    GoblinTown: felt,
    Travel: felt,
    Crypts_Token: felt,
    Lords_Token: felt,
    Realms_Token: felt,
    Resources_Token: felt,
    S_Crypts_Token: felt,
    S_Realms_Token: felt,
}

func deploy_account{syscall_ptr: felt*, range_check_ptr}(private_key: felt) -> (account_address: felt) {
    alloc_locals;
    local account_address;
    %{
        ids.account_address = deploy_contract("./lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo", 
            [ids.private_key]
        ).contract_address
        mock_start = mock_call(ids.account_address, 'supportsInterface', [1])
        mock_start = mock_call(ids.account_address, 'onERC1155BatchReceived', [ids.ON_ERC1155_BATCH_RECEIVED_SELECTOR])
    %}
    return (account_address,);
}

func deploy_controller{syscall_ptr: felt*, range_check_ptr}(arbiter: felt, proxy_admin: felt) -> (controller_address: felt) {
    alloc_locals;

    local controller_class_hash;
    local controller_address;

    %{
        declared = declare("./contracts/settling_game/ModuleController.cairo")
        ids.controller_class_hash = declared.class_hash
        ids.controller_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
            [ids.controller_class_hash]
        ).contract_address
    %}
    Controller.initializer(controller_address, arbiter, proxy_admin); 
    return (controller_address,);
}

func deploy_module{syscall_ptr: felt*, range_check_ptr}(
    module_id: felt, controller_address: felt, proxy_admin: felt
) -> (module_address: felt) {
    alloc_locals;

    local proxy_address;
    local module_class_hash;

    if (module_id == ModuleIds.Settling) {
        %{
            declared = declare("./contracts/settling_game/modules/settling/Settling.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
            stop_prank = start_prank(ids.proxy_admin, ids.controller_address)
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(controller_address, ModuleIds.Settling, proxy_address);
        IModuleController.set_write_access(controller_address, ModuleIds.Settling, ModuleIds.Realms_Token);
        IModuleController.set_write_access(controller_address, ModuleIds.Settling, ModuleIds.S_Realms_Token);
        IModuleController.set_write_access(controller_address, ModuleIds.Settling, ModuleIds.GoblinTown);
        IModuleController.set_write_access(controller_address, ModuleIds.Settling, ModuleIds.Resources);
        %{
            stop_prank()
        %}
        return (proxy_address,);
    }
    if (module_id == ModuleIds.Resources) {
        %{
            declared = declare("./contracts/settling_game/modules/resources/Resources.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
            stop_prank = start_prank(ids.proxy_admin, ids.controller_address)
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(controller_address, ModuleIds.Resources, proxy_address);
        IModuleController.set_write_access(controller_address, ModuleIds.Resources, ModuleIds.Realms_Token);
        IModuleController.set_write_access(controller_address, ModuleIds.Resources, ModuleIds.S_Realms_Token);
        IModuleController.set_write_access(controller_address, ModuleIds.Resources, ModuleIds.Resources_Token);
        IModuleController.set_write_access(controller_address, ModuleIds.Resources, ModuleIds.Settling);
        IModuleController.set_write_access(controller_address, ModuleIds.Resources, ModuleIds.Buildings);
        IModuleController.set_write_access(controller_address, ModuleIds.Resources, ModuleIds.GoblinTown);
        %{
            stop_prank()
        %}
        return (proxy_address,);
    }
    if (module_id == ModuleIds.Buildings) {
        %{
            declared = declare("./contracts/settling_game/modules/buildings/Buildings.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
            stop_prank = start_prank(ids.proxy_admin, ids.controller_address)
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(controller_address, ModuleIds.Buildings, proxy_address);
        IModuleController.set_write_access(controller_address, ModuleIds.Buildings, ModuleIds.Realms_Token);
        IModuleController.set_write_access(controller_address, ModuleIds.Buildings, ModuleIds.L10_Food);
        %{
            stop_prank()
        %}
        return (proxy_address,);
    }
    if (module_id == ModuleIds.Calculator) {
        %{
            declared = declare("./contracts/settling_game/modules/calculator/Calculator.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
            stop_prank = start_prank(ids.proxy_admin, ids.controller_address)
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(controller_address, ModuleIds.Calculator, proxy_address);
        IModuleController.set_write_access(controller_address, ModuleIds.Calculator, ModuleIds.Settling);
        IModuleController.set_write_access(controller_address, ModuleIds.Calculator, ModuleIds.L06_Combat);
        IModuleController.set_write_access(controller_address, ModuleIds.Calculator, ModuleIds.Buildings);
        %{
            stop_prank()
        %}
        return (proxy_address,);
    }
    if (module_id == ModuleIds.L06_Combat) {
        %{
            declared = declare("./contracts/settling_game/modules/combat/Combat.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
            stop_prank = start_prank(ids.proxy_admin, ids.controller_address)
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(controller_address, ModuleIds.L06_Combat, proxy_address);
        IModuleController.set_write_access(controller_address, ModuleIds.L06_Combat, ModuleIds.GoblinTown);
        IModuleController.set_write_access(controller_address, ModuleIds.L06_Combat, ModuleIds.L10_Food);
        IModuleController.set_write_access(controller_address, ModuleIds.L06_Combat, ModuleIds.L09_Relics);
        IModuleController.set_write_access(controller_address, ModuleIds.L06_Combat, ModuleIds.Travel);
        IModuleController.set_write_access(controller_address, ModuleIds.L06_Combat, ModuleIds.Resources);
        IModuleController.set_write_access(controller_address, ModuleIds.L06_Combat, ModuleIds.Buildings);
        IModuleController.set_write_access(controller_address, ModuleIds.L06_Combat, ModuleIds.Realms_Token);
        %{
            stop_prank()
        %}
        return (proxy_address,);
    }
    if (module_id == ModuleIds.L07_Crypts) {
        %{
            declared = declare("./contracts/settling_game/modules/crypts/L07_Crypts.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
            stop_prank = start_prank(ids.proxy_admin, ids.controller_address)
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(controller_address, ModuleIds.L07_Crypts, proxy_address);
        IModuleController.set_write_access(controller_address, ModuleIds.L07_Crypts, ModuleIds.L08_Crypts_Resources);
        %{
            stop_prank()
        %}
        return (proxy_address,);
    }
    if (module_id == ModuleIds.L08_Crypts_Resources) {
        %{
            declared = declare("./contracts/settling_game/modules/crypts/L08_Crypts_Resources.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
            stop_prank = start_prank(ids.proxy_admin, ids.controller_address)
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(controller_address, ModuleIds.L08_Crypts_Resources, proxy_address);
        IModuleController.set_write_access(controller_address, ModuleIds.L08_Crypts_Resources, ModuleIds.L07_Crypts);
        %{
            stop_prank()
        %}
        return (proxy_address,);
    }
    if (module_id == ModuleIds.L09_Relics) {
        %{
            declared = declare("./contracts/settling_game/modules/relics/Relics.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
            stop_prank = start_prank(ids.proxy_admin, ids.controller_address)
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(controller_address, ModuleIds.L09_Relics, proxy_address);
        IModuleController.set_write_access(controller_address, ModuleIds.L09_Relics, ModuleIds.Realms_Token);
        %{
            stop_prank()
        %}
        return (proxy_address,);
    }
    if (module_id == ModuleIds.L10_Food) {
        %{
            declared = declare("./contracts/settling_game/modules/food/Food.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
            stop_prank = start_prank(ids.proxy_admin, ids.controller_address)
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(controller_address, ModuleIds.L10_Food, proxy_address);
        IModuleController.set_write_access(controller_address, ModuleIds.L10_Food, ModuleIds.Buildings);
        IModuleController.set_write_access(controller_address, ModuleIds.L10_Food, ModuleIds.Realms_Token);
        IModuleController.set_write_access(controller_address, ModuleIds.L10_Food, ModuleIds.Calculator);
        IModuleController.set_write_access(controller_address, ModuleIds.L10_Food, ModuleIds.S_Realms_Token);
        IModuleController.set_write_access(controller_address, ModuleIds.L10_Food, ModuleIds.Resources_Token);
        %{
            stop_prank()
        %}
        return (proxy_address,);
    }
    if (module_id == ModuleIds.GoblinTown) {
        %{
            declared = declare("./contracts/settling_game/modules/goblintown/GoblinTown.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
            stop_prank = start_prank(ids.proxy_admin, ids.controller_address)
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(controller_address, ModuleIds.GoblinTown, proxy_address);
        IModuleController.set_write_access(controller_address, ModuleIds.GoblinTown, ModuleIds.Realms_Token);
        %{
            stop_prank()
        %}
        return (proxy_address,);
    }
    if (module_id == ModuleIds.Travel) {
        %{
            declared = declare("./contracts/settling_game/modules/travel/Travel.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
            stop_prank = start_prank(ids.proxy_admin, ids.controller_address)
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(controller_address, ModuleIds.Travel, proxy_address);
        %{
            stop_prank()
        %}
        return (proxy_address,);
    }
    if (module_id == ModuleIds.Crypts_Token) {
        %{
            declared = declare("./contracts/settling_game/tokens/Crypts_ERC721_Mintable.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
            stop_prank = start_prank(ids.proxy_admin, ids.controller_address)
        %}
        Crypts.initializer(proxy_address, 1, 1, proxy_admin);
        IModuleController.set_address_for_module_id(controller_address, ModuleIds.Crypts_Token, proxy_address);
        IModuleController.set_address_for_external_contract(controller_address, ExternalContractIds.Crypts, proxy_address);
        %{
            stop_prank()
        %}
        return (proxy_address,);
    }
    if (module_id == ModuleIds.Lords_Token) {
        %{
            declared = declare("./contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
            stop_prank = start_prank(ids.proxy_admin, ids.controller_address)
        %}
        Lords.initializer(proxy_address, 1, 1, 18, Uint256(10000, 0), 1, proxy_admin);
        IModuleController.set_address_for_module_id(controller_address, ModuleIds.Lords_Token, proxy_address);
        IModuleController.set_address_for_external_contract(controller_address, ExternalContractIds.Lords, proxy_address);
        %{
            stop_prank()
        %}
        return (proxy_address,);
    }
    if (module_id == ModuleIds.Realms_Token) {
        %{
            declared = declare("./contracts/settling_game/tokens/Realms_ERC721_Mintable.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
            stop_prank = start_prank(ids.proxy_admin, ids.controller_address)
        %}
        Realms.initializer(proxy_address, 1, 1, proxy_admin);
        IModuleController.set_address_for_module_id(controller_address, ModuleIds.Realms_Token, proxy_address);
        IModuleController.set_address_for_external_contract(controller_address, ExternalContractIds.Realms, proxy_address);
        %{
            stop_prank()
        %}
        return (proxy_address,);
    }
    if (module_id == ModuleIds.Resources_Token) {
        %{
            declared = declare("./contracts/settling_game/tokens/Resources_ERC1155_Mintable_Burnable.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
            stop_prank = start_prank(ids.proxy_admin, ids.controller_address)
        %}
        ResourcesToken.initializer(proxy_address, 1, proxy_admin, controller_address);
        IModuleController.set_address_for_module_id(controller_address, ModuleIds.Resources_Token, proxy_address);
        IModuleController.set_address_for_external_contract(controller_address, ExternalContractIds.Resources, proxy_address);
        %{
            stop_prank()
        %}
        return (proxy_address,);
    }
    if (module_id == ModuleIds.S_Crypts_Token) {
        %{
            declared = declare("./contracts/settling_game/tokens/S_Crypts_ERC721_Mintable.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
            stop_prank = start_prank(ids.proxy_admin, ids.controller_address)
        %}
        S_Crypts.initializer(proxy_address, 1, 1, proxy_admin);
        IModuleController.set_address_for_module_id(controller_address, ModuleIds.S_Crypts_Token, proxy_address);
        IModuleController.set_address_for_external_contract(controller_address, ExternalContractIds.S_Crypts, proxy_address);
        %{
            stop_prank()
        %}
        return (proxy_address,);
    }
    if (module_id == ModuleIds.S_Realms_Token) {
        %{
            declared = declare("./contracts/settling_game/tokens/S_Realms_ERC721_Mintable.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
            stop_prank = start_prank(ids.proxy_admin, ids.controller_address)
        %}
        S_Realms.initializer(proxy_address, 1, 1, proxy_admin, controller_address);
        IModuleController.set_address_for_module_id(controller_address, ModuleIds.S_Realms_Token, proxy_address);
        IModuleController.set_write_access(controller_address, ModuleIds.S_Realms_Token, ModuleIds.Realms_Token);
        IModuleController.set_address_for_external_contract(controller_address, ExternalContractIds.S_Realms, proxy_address);
        %{
            stop_prank()
        %}
        return (proxy_address,);
    }
    return (proxy_address,);
}

func time_warp{syscall_ptr: felt*, range_check_ptr}(new_timestamp: felt, target: felt) {
    %{ stop_warp = warp(ids.new_timestamp, target_contract_address=ids.target) %}
    return ();
}
