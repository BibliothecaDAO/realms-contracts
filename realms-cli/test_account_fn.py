import asyncio
import sys
from dataclasses import dataclass
sys.path.append("/workspaces/realms-contracts")
from openzeppelin.tests.utils import Signer

#
# starknet_py
#
from starknet_py.contract import Contract
from starknet_py.net import AccountClient, Client
from starkware.crypto.signature.signature import (
    private_to_stark_key,
    get_random_private_key,
)

ACCOUNT_ADDRESS  = 0x04e54defbbf05bc7a48b8a1a04e0ce585d56304c392d28ae63bd7085d55db529
ACCOUNT_PRIVATE  = 0x00ba477da23932720a13baf7d9a5999cfdd4df8e06637aa92c06863b11ad7235
ACCOUNT_PUBLIC   = 0x057c377338d99c433a99cb96609c63d5fd3f8e3ad0c657374f1cbd5fb6190347
LANPARTY_ADDRESS = 0x059966bd2a491a7202c0300ce40e1deb846caac87d9d3ad40dd9531a64012534

async def main():

    client = Client("testnet")

    print("_____check functions with client_____")
    account_contract = await Contract.from_address(ACCOUNT_ADDRESS, client)
    print(account_contract.functions)

    lanparty_contract = await Contract.from_address(LANPARTY_ADDRESS, client)
    print(lanparty_contract.functions)

    # ok wallets exist

    print("_____check if public keys match_____")
    invocation = await account_contract.functions["get_public_key"].call()
    print(invocation)
    print(hex(invocation.res))

    # checks out

    # now do everything, but from the account contract
    print("_____load account client_____")
    keypair = KeyPair.from_private_key(ACCOUNT_PRIVATE)
    assert keypair.public_key == ACCOUNT_PUBLIC
    account_client =  AccountClient(
        net="testnet",
        chain=None,
        address=ACCOUNT_ADDRESS,
        key_pair=KeyPair.from_private_key(ACCOUNT_PRIVATE),
    )

    lanparty_contract = await Contract.from_address(LANPARTY_ADDRESS, account_client)
    print(lanparty_contract.functions)

    #
    # call 1
    #
    print("_____calling lanparty contract for the first time_____")
    invocation = await lanparty_contract.functions["get_score"].call(ACCOUNT_ADDRESS)
    print(invocation)

    #
    # invoke 1
    #
    print("_____invoking_____")
    invocation = await lanparty_contract.functions["increase_score"].invoke(
        500,
        max_fee=int(1e14),
    )
    print(invocation)

    #
    # call 2
    #
    print("_____calling lanparty contract for the second time_____")
    invocation = await lanparty_contract.functions["get_score"].call(ACCOUNT_ADDRESS)
    print(invocation)

    return 0

@dataclass
class KeyPair:
    private_key: int
    public_key: int

    @staticmethod
    def from_private_key(key: int) -> "KeyPair":
        return KeyPair(private_key=key, public_key=private_to_stark_key(key))

if __name__=="__main__":
    asyncio.run(main())
