%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.math import unsigned_div_rem

from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_div

const food = -106
const culture = 285
const population = 300

@external
func test_happiness{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals
    let (pop_calc, _) = unsigned_div_rem(population, 100)
    let culture_calc = culture - pop_calc
    let food_calc = food - pop_calc

    let happiness = culture_calc + food_calc

    %{ print(ids.happiness) %}

    return ()
end

@external
func test_food{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let castleImpact = 1 * 1

    let food = 25 - castleImpact + -1 + -1 - -1 - -1 + -1 - -1 - -1 - -1 - -1 + -1 + -1 + 1 - -1 + -1 - -1 - -1 - -1 - -1

    %{ print(ids.castleImpact) %}

    return ()
end
# @contract_interface
# namespace ProxyInterface:
#     func initializer(address_of_controller : felt, proxy_admin : felt):
#     end
# end

# @contract_interface
# namespace LordsInterface:
#     func initializer(
#         name : felt,
#         symbol : felt,
#         decimals : felt,
#         initial_supply : Uint256,
#         recipient : felt,
#         proxy_admin : felt,
#     ):
#     end
# end

# @contract_interface
# namespace RealmsInterface:
#     func initializer(
#         name: felt,
#         symbol: felt,
#         proxy_admin: felt
#     ):
#     end
# end

# @external
# func test_happiness{syscall_ptr : felt*, range_check_ptr}():
#     alloc_locals

#     local lords : felt
#     local realms : felt
#     local s_realms : felt
#     local resources : felt

#     local proxy_lords : felt
#     local proxy_realms : felt
#     local proxy_s_realms : felt
#     local proxy_resources : felt

#     local Account : felt
#     local Arbiter : felt
#     local ModuleController : felt

#     local L01_Settling : felt
#     local L01_Proxy_Settling : felt

#     local L02_Resources : felt
#     local L03_Buildings : felt
#     local L04_Calculator : felt

#     %{ ids.Account = deploy_contract("./openzeppelin/account/Account.cairo", [123456]).contract_address %}

#     %{ print("lords") %}
#     %{ ids.lords = deploy_contract("./contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo", []).contract_address %}
#     %{ ids.proxy_lords = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.lords]).contract_address %}
#     LordsInterface.initializer(proxy_lords, 1234, 1234, 18, Uint256(50000, 0), Account, Account)

#     %{ print("realms") %}
#     %{ ids.realms = deploy_contract("./contracts/settling_game/tokens/Realms_ERC721_Mintable.cairo", []).contract_address %}
#     %{ ids.proxy_realms = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.realms]).contract_address %}
#     RealmsInterface.initializer(proxy_realms, 1234, 1234, Account)

#     %{ print("s_realms") %}
#     %{ ids.s_realms = deploy_contract("./contracts/settling_game/tokens/S_Realms_ERC721_Mintable.cairo", []).contract_address %}
#     %{ ids.proxy_s_realms = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.s_realms]).contract_address %}
#     RealmsInterface.initializer(proxy_s_realms, 1234, 1234, Account)

#     # GAME CONTROLLERS
#     %{ ids.Arbiter = deploy_contract("./contracts/settling_game/Arbiter.cairo", [ids.Account]).contract_address %}
#     %{ ids.ModuleController = deploy_contract("./contracts/settling_game/ModuleController.cairo", [ids.Arbiter,ids.proxy_lords,ids.proxy_lords,ids.proxy_lords,ids.proxy_lords,ids.proxy_lords]).contract_address %}

#     # GAME MODULES
#     %{ ids.L01_Settling = deploy_contract("./contracts/settling_game/L01_Settling.cairo", []).contract_address %}
#     %{ ids.L01_Proxy_Settling = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.L01_Settling]).contract_address %}

#     # Settling
#     ProxyInterface.initializer(
#         contract_address=L01_Proxy_Settling,
#         address_of_controller=L01_Settling,
#         proxy_admin=L01_Settling,
#     )

#     # %{ ids.L02_Resources = deploy_contract("./contracts/settling_game/L02_Resources.cairo", []).contract_address %}
#     # %{ ids.L03_Buildings = deploy_contract("./contracts/settling_game/L03_Buildings.cairo", []).contract_address %}
#     # %{ ids.L04_Calculator = deploy_contract("./contracts/settling_game/L04_Calculator.cairo", []).contract_address %}

#     # wonders.write(contract_a_address)

#     return ()
# end
