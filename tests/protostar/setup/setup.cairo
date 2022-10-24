%lang starknet

from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.uint256 import Uint256

from contracts.settling_game.utils.game_structs import ModuleIds

from contracts.settling_game.interfaces.imodules import IModuleController

@contract_interface
namespace Module {
    func initializer(controller_address, proxy_admin) {
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
    func initializer(uri: felt, proxy_admin: felt) {
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
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(ModuleIds.Settling, proxy_address);
        IModuleController.set_write_access(ModuleIds.Settling, ModuleIds.Realms_Token);
        IModuleController.set_write_access(ModuleIds.Settling, ModuleIds.S_Realms_Token);
        IModuleController.set_write_access(ModuleIds.Settling, ModuleIds.GoblinTown);
        IModuleController.set_write_access(ModuleIds.Settling, ModuleIds.Resources);
        return (proxy_address,);
    }
    if (module_id == ModuleIds.Resources) {
        %{
            declared = declare("./contracts/settling_game/modules/resources/Resources.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(ModuleIds.Resources, proxy_address);
        IModuleController.set_write_access(ModuleIds.Resources, ModuleIds.Realms_Token);
        IModuleController.set_write_access(ModuleIds.Resources, ModuleIds.Settling);
        IModuleController.set_write_access(ModuleIds.Resources, ModuleIds.Buildings);
        IModuleController.set_write_access(ModuleIds.Resources, ModuleIds.GoblinTown);
        return (proxy_address,);
    }
    if (module_id == ModuleIds.Buildings) {
        %{
            declared = declare("./contracts/settling_game/modules/buildings/Buildings.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(ModuleIds.Buildings, proxy_address);
        IModuleController.set_write_access(ModuleIds.Buildings, ModuleIds.Realms_Token);
        IModuleController.set_write_access(ModuleIds.Buildings, ModuleIds.L10_Food);
        return (proxy_address,);
    }
    if (module_id == ModuleIds.Calculator) {
        %{
            declared = declare("./contracts/settling_game/modules/calculator/Calculator.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(ModuleIds.Calculator, proxy_address);
        IModuleController.set_write_access(ModuleIds.Calculator, ModuleIds.Settling);
        IModuleController.set_write_access(ModuleIds.Calculator, ModuleIds.L06_Combat);
        IModuleController.set_write_access(ModuleIds.Calculator, ModuleIds.Buildings);
        return (proxy_address,);
    }
    if (module_id == ModuleIds.L06_Combat) {
        %{
            declared = declare("./contracts/settling_game/modules/combat/Combat.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(ModuleIds.L06_Combat, proxy_address);
        IModuleController.set_write_access(ModuleIds.L06_Combat, ModuleIds.GoblinTown);
        IModuleController.set_write_access(ModuleIds.L06_Combat, ModuleIds.L10_Food);
        IModuleController.set_write_access(ModuleIds.L06_Combat, ModuleIds.L09_Relics);
        IModuleController.set_write_access(ModuleIds.L06_Combat, ModuleIds.Travel);
        IModuleController.set_write_access(ModuleIds.L06_Combat, ModuleIds.Resources);
        IModuleController.set_write_access(ModuleIds.L06_Combat, ModuleIds.Buildings);
        IModuleController.set_write_access(ModuleIds.L06_Combat, ModuleIds.Realms_Token);
        return (proxy_address,);
    }
    if (module_id == ModuleIds.L07_Crypts) {
        %{
            declared = declare("./contracts/settling_game/modules/crypts/L07_Crypts.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(ModuleIds.L07_Crypts, proxy_address);
        IModuleController.set_write_access(ModuleIds.L07_Crypts, ModuleIds.L08_Crypts_Resources);
        return (proxy_address,);
    }
    if (module_id == ModuleIds.L08_Crypts_Resources) {
        %{
            declared = declare("./contracts/settling_game/modules/crypts/L08_Crypts_Resources.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(ModuleIds.L08_Crypts_Resources, proxy_address);
        IModuleController.set_write_access(ModuleIds.L08_Crypts_Resources, ModuleIds.L07_Crypts);
        return (proxy_address,);
    }
    if (module_id == ModuleIds.L09_Relics) {
        %{
            declared = declare("./contracts/settling_game/modules/relics/Relics.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(ModuleIds.L09_Relics, proxy_address);
        IModuleController.set_write_access(ModuleIds.L09_Relics, ModuleIds.Realms_Token);
        return (proxy_address,);
    }
    if (module_id == ModuleIds.L10_Food) {
        %{
            declared = declare("./contracts/settling_game/modules/food/Food.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(ModuleIds.L10_Food, proxy_address);
        IModuleController.set_write_access(ModuleIds.L10_Food, ModuleIds.Buildings);
        IModuleController.set_write_access(ModuleIds.L10_Food, ModuleIds.Realms_Token);
        IModuleController.set_write_access(ModuleIds.L10_Food, ModuleIds.Calculator);
        IModuleController.set_write_access(ModuleIds.L10_Food, ModuleIds.S_Realms_Token);
        IModuleController.set_write_access(ModuleIds.L10_Food, ModuleIds.Resources_Token);
        return (proxy_address,);
    }
    if (module_id == ModuleIds.GoblinTown) {
        %{
            declared = declare("./contracts/settling_game/modules/goblintown/GoblinTown.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(ModuleIds.GoblinTown, proxy_address);
        IModuleController.set_write_access(ModuleIds.GoblinTown, ModuleIds.Realms_Token);
        return (proxy_address,);
    }
    if (module_id == ModuleIds.Travel) {
        %{
            declared = declare("./contracts/settling_game/modules/travel/Travel.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
        %}
        Module.initializer(proxy_address, controller_address, proxy_admin);
        IModuleController.set_address_for_module_id(ModuleIds.Travel, proxy_address);
        return (proxy_address,);
    }
    if (module_id == ModuleIds.Crypts_Token) {
        %{
            declared = declare("./contracts/settling_game/tokens/Crypts_ERC721_Mintable.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
        %}
        Crypts.initializer(proxy_address, 1, 1, proxy_admin);
        IModuleController.set_address_for_module_id(ModuleIds.Crypts_Token, proxy_address);
        return (proxy_address,);
    }
    if (module_id == ModuleIds.Lords_Token) {
        %{
            declared = declare("./contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
        %}
        Lords.initializer(proxy_address, 1, 1, 18, Uint256(10000, 0), 1, proxy_admin);
        IModuleController.set_address_for_module_id(ModuleIds.Lords_Token, proxy_address);
        return (proxy_address,);
    }
    if (module_id == ModuleIds.Realms_Token) {
        %{
            declared = declare("./contracts/settling_game/tokens/Realms_ERC721_Mintable.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
        %}
        Realms.initializer(proxy_address, 1, 1, proxy_admin);
        IModuleController.set_address_for_module_id(ModuleIds.Realms_Token, proxy_address);
        return (proxy_address,);
    }
    if (module_id == ModuleIds.Resources_Token) {
        %{
            declared = declare("./contracts/settling_game/tokens/Resources_ERC1155_Mintable_Burnable.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
        %}
        ResourcesToken.initializer(proxy_address, 1, proxy_admin);
        IModuleController.set_address_for_module_id(ModuleIds.Resources_Token, proxy_address);
        return (proxy_address,);
    }
    if (module_id == ModuleIds.S_Crypts_Token) {
        %{
            declared = declare("./contracts/settling_game/tokens/S_Crypts_ERC721_Mintable.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
        %}
        S_Crypts.initializer(proxy_address, 1, 1, proxy_admin);
        IModuleController.set_address_for_module_id(ModuleIds.S_Crypts_Token, proxy_address);
        return (proxy_address,);
    }
    if (module_id == ModuleIds.S_Realms_Token) {
        %{
            declared = declare("./contracts/settling_game/tokens/S_Realms_ERC721_Mintable.cairo")
            ids.module_class_hash = declared.class_hash
            ids.proxy_address = deploy_contract("./contracts/settling_game/proxy/PROXY_logic.cairo", 
                [ids.module_class_hash]
            ).contract_address
        %}
        S_Realms.initializer(proxy_address, 1, 1, proxy_admin, controller_address);
        IModuleController.set_address_for_module_id(ModuleIds.S_Realms_Token, proxy_address);
        IModuleController.set_write_access(ModuleIds.S_Realms_Token, ModuleIds.Realms_Token);
        return (proxy_address,);
    }
    return (proxy_address,);
}

func time_warp{syscall_ptr: felt*, range_check_ptr}(new_timestamp: felt, target: felt) {
    %{ stop_warp = warp(ids.new_timestamp, target_contract_address=ids.target) %}
    return ();
}
