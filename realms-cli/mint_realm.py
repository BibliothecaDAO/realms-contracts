from ast import arguments
from email.headerregistry import Address
from nile import deployments

# TODO: ADD TO ENV ON LOAD
NETWORK = "goerli"

def run(nre):
    admin = '0x01560853165c85c290dbe94980a1faa222b6469af53775a15f2fdc1542518af5'

    arbiter, abi = next(deployments.load("arbiter", NETWORK))
    controller, abi = next(deployments.load("moduleController", NETWORK))

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

    # set module access within realms access
    # nre.invoke(
    #     realms,
    #     'set_realm_data',
    #     params=["1", "0", '40564819207303341694527483217926'],
    # )

    # set module access within resources contract
    mint = nre.invoke(
        realms,
        'mint',
        params=[admin, "0", "0"],
    )

    print(mint)