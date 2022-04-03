# from dotenv import load_dotenv
import asyncio
import json
from openzeppelin.tests.utils import Signer, uint, str_to_felt, felt_to_str
from scripts.binary_converter import map_realm
# load_dotenv()
from starkware.cairo.common.hash_state import compute_hash_on_elements
from starkware.crypto.signature.signature import private_to_stark_key, sign
from starkware.starknet.definitions.error_codes import StarknetErrorCode
from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.business_logic.transaction_execution_objects import Event
from starkware.starknet.testing.starknet import Starknet, StarknetContract
from starkware.starknet.wallets.account import Account

json_realms = json.load(open('data/realms.json'))

signer = Signer(
    0x065abfa492a31efe92b3784206de3fa14627322952fb96840e67b82838a5253f)


async def mint_realm():

    set_realm = await signer.send_transaction(
        signer, '0x43b557ed70520b547f9631abec08b52df1e2b5b0037473c1cc348820b0063b9', 'set_realm_data', [
            *uint(1), map_realm(json_realms['1'])]
    )
    return set_realm


async def main():
    realm = await mint_realm()
    print(realm)

asyncio.run(main())
