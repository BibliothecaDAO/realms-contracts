from ast import arguments
from email.headerregistry import Address
from nile import deployments

# TODO: ADD TO ENV ON LOAD
NETWORK = "goerli"

def run(nre):
    admin = '0x00b8675fba812edd0f69fcb917616162cbe785490aeabfb693fb3a0f489a21a5'
    lords, abi = next(deployments.load("lords", NETWORK))
    realms, abi = next(deployments.load("realms", NETWORK))
    resources, abi = next(deployments.load("resources", NETWORK))
    s_realms, abi = next(deployments.load("s_realms", NETWORK))

    storage, abi = nre.deploy(
        "Storage", alias="storage", arguments=[admin])


    arbiter, abi = nre.deploy(
        "Arbiter",
        alias="arbiter",
        arguments=[admin]
    )

    controller, abi = nre.deploy(
        "ModuleController",
        alias="moduleController",
            arguments=[
            arbiter,
            lords,
            resources,
            realms,
            admin,
            s_realms,
            storage,
        ],
    )
    print(controller)

    # Set address of controller
    nre.invoke(
        arbiter,
        'set_address_of_controller',
        params=[controller],
    )

    # Settling Logic
    L01_Settling, abi = nre.deploy(
        "L01_Settling",
        alias="L01_Settling",
        arguments=[controller],
    )

    print(L01_Settling)

    # Settling Proxy
    # proxy_settling_logic, abi = nre.deploy(
    #     "PROXY_L01_Settling",
    #     alias="PROXY_L01_Settling",
    #     arguments=[L01_Settling],
    # )

    # Settling Init
    # nre.invoke(
    #     proxy_settling_logic,
    #     'initializer',
    #     params=[admin, controller],
    # )

    settling_state, abi  = nre.deploy(
        "S01_Settling",
        alias="S01_Settling",
        arguments=[controller],
    )
    resources_logic, abi  = nre.deploy(
        "L02_Resources",alias="L02_Resources",
        arguments=[controller],
    )
    resources_state, abi  = nre.deploy(
        "S02_Resources",alias="S02_Resources",
        arguments=[controller],
    )
    buildings_logic, abi  = nre.deploy(
        "L03_Buildings",alias="L03_Buildings",
        arguments=[controller],
    )
    buildings_state, abi  = nre.deploy(
        "S03_Buildings",alias="S03_Buildings",
        arguments=[controller],
    )
    calculator_logic, abi  = nre.deploy(
        "L04_Calculator",alias="L04_Calculator",
        arguments=[controller],
    )
    wonders_logic, abi  = nre.deploy(
        "L05_Wonders",alias="L05_Wonders",
        arguments=[controller],
    )
    wonders_state, abi  = nre.deploy(
        "S05_Wonders",alias="S05_Wonders",
        arguments=[controller],
    )