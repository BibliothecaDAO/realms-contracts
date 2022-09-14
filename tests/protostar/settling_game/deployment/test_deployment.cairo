%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_div
from contracts.settling_game.utils.game_structs import (
    BuildingsFood,
    BuildingsPopulation,
    BuildingsCulture,
)
from contracts.settling_game.interfaces.imodules import IArbiter

@contract_interface
namespace ProxyInterface {
    func initializer(address_of_controller: felt, proxy_admin: felt) {
    }
}

@contract_interface
namespace LordsInterface {
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
namespace RealmsInterface {
    func initializer(name: felt, symbol: felt, proxy_admin: felt) {
    }
}

@contract_interface
namespace ResourcesInterface {
    func initializer(name: felt, symbol: felt) {
    }
}

// @external
// func test_full_deploy{syscall_ptr : felt*, range_check_ptr}():
//     alloc_locals

// local lords : felt
//     local realms : felt
//     local s_realms : felt
//     local resources : felt

// local proxy_lords : felt
//     local proxy_realms : felt
//     local proxy_s_realms : felt
//     local proxy_resources : felt

// local Account : felt
//     local Arbiter : felt
//     local ModuleController : felt

// local L01_Settling : felt
//     local L01_Proxy_Settling : felt

// local L02_Resources : felt
//     local L02_Proxy_Resources : felt

// local L03_Buildings : felt
//     local L03_Proxy_Buildings : felt

// local L04_Calculator : felt
//     local L04_Proxy_Calculator : felt

// local L05_Wonders : felt
//     local L05_Proxy_Wonders : felt

// local L06_Combat : felt
//     local L06_Proxy_Combat : felt

// %{ ids.Account = deploy_contract("./openzeppelin/account/Account.cairo", [123456]).contract_address %}

// %{ print("lords") %}
//     %{ ids.lords = deploy_contract("./contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo", []).contract_address %}
//     %{ ids.proxy_lords = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.lords]).contract_address %}
//     LordsInterface.initializer(proxy_lords, 1234, 1234, 18, Uint256(50000, 0), Account, Account)

// %{ print("realms") %}
//     %{ ids.realms = deploy_contract("./contracts/settling_game/tokens/Realms_ERC721_Mintable.cairo", []).contract_address %}
//     %{ ids.proxy_realms = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.realms]).contract_address %}
//     RealmsInterface.initializer(proxy_realms, 1234, 1234, Account)

// %{ print("s_realms") %}
//     %{ ids.s_realms = deploy_contract("./contracts/settling_game/tokens/S_Realms_ERC721_Mintable.cairo", []).contract_address %}
//     %{ ids.proxy_s_realms = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.s_realms]).contract_address %}
//     RealmsInterface.initializer(proxy_s_realms, 1234, 1234, Account)

// %{ print("resources") %}
//     %{ ids.resources = deploy_contract("./contracts/settling_game/tokens/Resources_ERC1155_Mintable_Burnable.cairo", []).contract_address %}
//     %{ ids.proxy_resources = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.resources]).contract_address %}
//     ResourcesInterface.initializer(proxy_resources, 1234, Account)

// # GAME CONTROLLERS
//     %{ ids.Arbiter = deploy_contract("./contracts/settling_game/Arbiter.cairo", [ids.Account]).contract_address %}
//     %{ ids.ModuleController = deploy_contract("./contracts/settling_game/ModuleController.cairo", [ids.Arbiter,ids.proxy_lords,ids.proxy_lords,ids.proxy_lords,ids.proxy_lords,ids.proxy_lords]).contract_address %}

// # GAME MODULES
//     %{ ids.L01_Settling = deploy_contract("./contracts/settling_game/L01_Settling.cairo", []).contract_address %}
//     %{ ids.L01_Proxy_Settling = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.L01_Settling]).contract_address %}

// %{ ids.L02_Resources = deploy_contract("./contracts/settling_game/L02_Resources.cairo", []).contract_address %}
//     %{ ids.L02_Proxy_Resources = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.L02_Resources]).contract_address %}

// %{ ids.L03_Buildings = deploy_contract("./contracts/settling_game/L03_Buildings.cairo", []).contract_address %}
//     %{ ids.L03_Proxy_Buildings = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.L03_Buildings]).contract_address %}

// %{ ids.L04_Calculator = deploy_contract("./contracts/settling_game/L04_Calculator.cairo", []).contract_address %}
//     %{ ids.L04_Proxy_Calculator = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.L04_Calculator]).contract_address %}

// %{ ids.L05_Wonders = deploy_contract("./contracts/settling_game/L05_Wonders.cairo", []).contract_address %}
//     %{ ids.L05_Proxy_Wonders = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.L05_Wonders]).contract_address %}

// %{ ids.L06_Combat = deploy_contract("./contracts/settling_game/L06_Combat.cairo", []).contract_address %}
//     %{ ids.L06_Proxy_Combat = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.L06_Combat]).contract_address %}

// # batch set all controllers
//     IArbiter.batch_set_controller_addresses(Arbiter, L01_Proxy_Settling, L02_Proxy_Resources, L03_Proxy_Buildings, L04_Proxy_Calculator, L05_Proxy_Wonders, L06_Proxy_Combat)

// # Settling
//     ProxyInterface.initializer(
//         contract_address=L01_Proxy_Settling,
//         address_of_controller=L01_Settling,
//         proxy_admin=L01_Settling,
//     )

// return ()
// end
