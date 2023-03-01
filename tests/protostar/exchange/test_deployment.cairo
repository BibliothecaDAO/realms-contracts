%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from contracts.settling_game.utils.game_structs import BuildingsPopulation
from starkware.cairo.common.alloc import alloc
from contracts.settling_game.interfaces.imodules import IArbiter

@contract_interface
namespace ProxyInterface {
    func initializer(address_of_controller: felt, proxy_admin: felt) {
    }
}

@contract_interface
namespace ILords {
    func initializer(
        name: felt,
        symbol: felt,
        decimals: felt,
        initial_supply: Uint256,
        recipient: felt,
        proxy_admin: felt,
    ) {
    }
    func approve(spender: felt, amount: Uint256) {
    }
}

@contract_interface
namespace IResources {
    func initializer(name: felt, symbol: felt) {
    }
    func mintBatch(to: felt, ids_len: felt, ids: Uint256*, amounts_len: felt, amounts: Uint256*) {
    }

    func setApprovalForAll(operator: felt, approved: felt) {
    }
}

@contract_interface
namespace IAMM {
    func initializer(
        currency_address_: felt,
        token_address_: felt,
        lp_fee_thousands_: Uint256,
        royalty_fee_thousands_: Uint256,
        royalty_fee_address_: felt,
        proxy_admin: felt,
    ) {
    }
    func initial_liquidity(
        currency_amounts_len: felt,
        currency_amounts: Uint256*,
        token_ids_len: felt,
        token_ids: Uint256*,
        token_amounts_len: felt,
        token_amounts: Uint256*,
    ) {
    }
    func get_all_sell_price(
        token_ids_len: felt, token_ids: Uint256*, token_amounts_len: felt, token_amounts: Uint256*
    ) -> (sell_value_len: felt, sell_value: Uint256*) {
    }
    func get_all_buy_price(
        token_ids_len: felt, token_ids: Uint256*, token_amounts_len: felt, token_amounts: Uint256*
    ) -> (sell_value_len: felt, sell_value: Uint256*) {
    }
}

@external
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;
    local lords: felt;
    local resources: felt;

    local proxy_lords: felt;
    local proxy_resources: felt;

    local Account: felt;

    local ERC1155_AMM: felt;
    local proxy_ERC1155_AMM: felt;

    // %{ ids.Account = deploy_contract("./lib/cairo_contracts/src/openzeppelin/account/Account.cairo", [123456]).contract_address %}

    %{ print("lords") %}
    %{ ids.lords = deploy_contract("./contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo", []).contract_address %}
    %{ ids.proxy_lords = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.lords]).contract_address %}

    %{ print("resources") %}
    %{ ids.resources = deploy_contract("./contracts/settling_game/tokens/Resources_ERC1155_Mintable_Burnable.cairo", []).contract_address %}
    %{ ids.proxy_resources = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.resources]).contract_address %}
    IResources.initializer(proxy_resources, 1234, 123);

    %{ print("AMM") %}
    %{ ids.ERC1155_AMM = deploy_contract("./contracts/exchange/Exchange_ERC20_1155.cairo", []).contract_address %}
    %{ ids.proxy_ERC1155_AMM = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.ERC1155_AMM]).contract_address %}

    return ();
}

@external
func test_full_deploy{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    // local lords : felt
    // local resources : felt

    // local proxy_lords : felt
    // local proxy_resources : felt

    // local Account : felt

    // local ERC1155_AMM : felt
    // local proxy_ERC1155_AMM : felt

    // %{ ids.Account = deploy_contract("./openzeppelin/account/Account.cairo", [123456]).contract_address %}

    // %{ print("lords") %}
    // %{ ids.lords = deploy_contract("./contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo", []).contract_address %}
    // %{ ids.proxy_lords = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.lords]).contract_address %}

    // %{ print("resources") %}
    // %{ ids.resources = deploy_contract("./contracts/settling_game/tokens/Resources_ERC1155_Mintable_Burnable.cairo", []).contract_address %}
    // %{ ids.proxy_resources = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.resources]).contract_address %}
    // IResources.initializer(proxy_resources, 1234, Account)

    // %{ print("AMM") %}
    // %{ ids.ERC1155_AMM = deploy_contract("./contracts/exchange/Exchange_ERC20_1155.cairo", []).contract_address %}
    // %{ ids.proxy_ERC1155_AMM = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.ERC1155_AMM]).contract_address %}
    // IAMM.initializer(
    //     proxy_ERC1155_AMM,
    //     proxy_lords,
    //     proxy_resources,
    //     Uint256(100, 0),
    //     Uint256(100, 0),
    //     Account,
    //     Account,
    // )

    // ILords.initializer(
    //     proxy_lords, 1234, 1234, 18, Uint256(5000000000000000000000, 0), proxy_ERC1155_AMM, proxy_ERC1155_AMM
    // )

    // let (resources_mint : Uint256*) = alloc()
    // let (values : Uint256*) = alloc()
    // let (lords_values : Uint256*) = alloc()

    // assert resources_mint[0] = Uint256(1, 0)
    // assert resources_mint[1] = Uint256(2, 0)

    // assert values[0] = Uint256(10, 0)
    // assert values[1] = Uint256(100, 0)

    // assert lords_values[0] = Uint256(100, 0)
    // assert lords_values[1] = Uint256(100, 0)

    // MINT RESOURCES
    // IResources.mintBatch(proxy_resources, Account, 2, resources_mint, 2, values)

    // APPROVALS
    // IResources.setApprovalForAll(proxy_resources, proxy_ERC1155_AMM, 1)
    // ILords.approve(proxy_lords, proxy_ERC1155_AMM, Uint256(5000000000000000000000, 0))

    // IAMM.initial_liquidity(proxy_ERC1155_AMM, 2, lords_values, 2, resources_mint, 2, values)

    // let (sell_len: felt, sell_value: Uint256* ) = IAMM.get_all_sell_price(proxy_ERC1155_AMM, 2, resources_mint, 2, values)

    // %{ print(ids.sell_len) %}
    // %{ print(ids.sell_value.low) %}

    // let (buy_len: felt, buy_value: Uint256* ) = IAMM.get_all_buy_price(proxy_ERC1155_AMM, 2, resources_mint, 2, values)

    // %{ print(ids.buy_len) %}
    // %{ print(ids.buy_value.low) %}

    return ();
}
