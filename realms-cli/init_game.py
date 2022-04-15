from ast import arguments
from email.headerregistry import Address
from utils import Signer, uint, str_to_felt
from nile import deployments

# TODO: ADD TO ENV ON LOAD
NETWORK = "goerli"

def run(nre):
    admin, abi = next(deployments.load("admin", NETWORK))

    arbiter, abi = next(deployments.load("arbiter", NETWORK))
    controller, abi = next(deployments.load("moduleController", NETWORK))

    admin, abi = next(deployments.load("admin", NETWORK))
    lords, abi = next(deployments.load("lords", NETWORK))
    realms, abi = next(deployments.load("realms", NETWORK))
    resources, abi = next(deployments.load("resources", NETWORK))
    s_realms, abi = next(deployments.load("s_realms", NETWORK))

    L01_Settling, abi = next(deployments.load("L01_Settling", NETWORK))
    S01_Settling, abi = next(deployments.load("S01_Settling", NETWORK))
    L02_Resources, abi = next(deployments.load("L02_Resources", NETWORK))
    S02_Resources, abi = next(deployments.load("S02_Resources", NETWORK))
    L03_Buildings, abi = next(deployments.load("L03_Buildings", NETWORK))
    S03_Buildings, abi = next(deployments.load("S03_Buildings", NETWORK))
    L04_Calculator, abi = next(deployments.load("L04_Calculator", NETWORK))
    L05_Wonders, abi = next(deployments.load("L05_Wonders", NETWORK))
    S05_Wonders, abi = next(deployments.load("S05_Wonders", NETWORK))

    print(admin, controller)

    # Settling Init TODO: PROXY CALLS
    # nre.invoke(
    #     proxy_settling_logic,
    #     'initializer',
    #     params=[admin, controller],
    # )

    nre.invoke(
        arbiter,
        'batch_set_controller_addresses',
        params=[
            L01_Settling,
            S01_Settling,
            L02_Resources,
            S02_Resources,
            L03_Buildings,
            S03_Buildings,
            L04_Calculator,
            L05_Wonders,
            S05_Wonders,
        ],
    )

    # set module access within realms access
    nre.invoke(
        s_realms,
        'Set_module_access',
        params=[L01_Settling],
    )

    # set module access within resources contract
    nre.invoke(
        resources,
        'Set_module_access',
        params=[L02_Resources],
    )