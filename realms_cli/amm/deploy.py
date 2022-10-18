import time
from realms_cli.caller_invoker import wrapped_send, compile,  wrapped_declare
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
from realms_cli.utils import str_to_felt, uint


AMM_RESOURCES_URI = str_to_felt("AMMResources")


def run(nre):

    config = Config(nre.network)

    print(config.LORDS_PROXY_ADDRESS,
          config.RESOURCES_MINT_PROXY_ADDRESS,)

    compile(contract_alias="contracts/exchange/Exchange_ERC20_1155.cairo")

    logged_deploy(
        nre,
        "Exchange_ERC20_1155",
        alias="Exchange_ERC20_1155",
        arguments=[],
    )

    time.sleep(30)

    class_hash = wrapped_declare(
        config.ADMIN_ALIAS, "exchange/Exchange_ERC20_1155", nre.network, "Exchange_ERC20_1155")

    time.sleep(60)

    logged_deploy(
        nre,
        "PROXY_Logic",
        alias="proxy_Exchange_ERC20_1155",
        arguments=[class_hash]
    )

    print('🕒 Waiting for deploy before invoking... 1 minutes for testnet')

    time.sleep(30)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias=config.Exchange_ERC20_1155_alias,
        function="initializer",
        arguments=[
            AMM_RESOURCES_URI,
            config.LORDS_PROXY_ADDRESS,
            config.RESOURCES_MINT_PROXY_ADDRESS,
            *uint(100),
            *uint(100),
            config.ADMIN_ADDRESS,
            config.ADMIN_ADDRESS
        ],
    )

    module, _ = safe_load_deployment('proxy_Exchange_ERC20_1155', 'goerli')

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias=config.Resources_ERC1155_Mintable_Burnable_alias,
        function="setApprovalForAll",
        arguments=[module, 1],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias=config.Lords_ERC20_Mintable_alias,
        function="increaseAllowance",
        arguments=[module, *uint(50000000 * (10 ** 18))],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias=config.Resources_ERC1155_Mintable_Burnable_alias,
        function="setApprovalForAll",
        arguments=[module, 1],
    )

    # ----------- MINT RESOURCES -------------------#

    uints = []
    amounts = []

    n_resources = len(config.RESOURCES)

    for i in range(n_resources - 2):
        uints.append(str(i+1))
        uints.append("0")

    # WHEAT
    uints.append("10000")
    uints.append("0")

    # FISH
    uints.append("10001")
    uints.append("0")

    for i in range(n_resources):
        amounts.append(100000000 * 10 ** 18)
        amounts.append(0)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias=config.Resources_ERC1155_Mintable_Burnable_alias,
        function="mintBatch",
        arguments=[config.ADMIN_ADDRESS, n_resources,
                   *uints, n_resources, *amounts, 1, 1],
    )

    # ----------- INIT LP -------------------#

    n_resources = 24
    price = [37.356,
             29.356,
             28.551,
             19.687,
             16.507,
             12.968,
             8.782,
             7.128,
             6.808,
             4.425,
             2.235,
             1.840,
             1.780,
             1.780,
             1.281,
             1.207,
             1.035,
             0.827,
             0.693,
             0.410,
             0.276,
             0.171,
             2000,
             2000]

    resource_ids = []
    for i in range(n_resources - 2):
        resource_ids.append(str(i+1))
        resource_ids.append("0")

    # WHEAT
    resource_ids.append("10000")
    resource_ids.append("0")

    # FISH
    resource_ids.append("10001")
    resource_ids.append("0")

    resource_values = []
    for i, resource in enumerate(price):
        resource_values.append(int((resource * 10000) * 10 ** 18))
        resource_values.append("0")

    currency_values = []
    for i in range(n_resources):
        currency_values.append(str(10000 * 10 ** 18))
        currency_values.append("0")

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias=config.Exchange_ERC20_1155_alias,
        function="initial_liquidity",
        arguments=[
            n_resources,
            *currency_values,
            n_resources,
            *resource_ids,
            n_resources,
            *resource_values
        ],
    )
