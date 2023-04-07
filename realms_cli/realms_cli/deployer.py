"""Helper functions for repeating nre patterns."""
from realms_cli.caller_invoker import get_tx_status, _process_arguments, execute_call, _get_transaction_hash, status
from realms_cli.config import Config
import time
import logging
from nile import deployments
from nile.core.types.account import Account
from nile.core.types.udc_helpers import create_udc_deploy_transaction
from nile.common import UNIVERSAL_DEPLOYER_ADDRESS, ABIS_DIRECTORY, BUILD_DIRECTORY
from nile.utils import hex_address, normalize_number, hex_class_hash




async def logged_deploy(network, account, contract_name, alias, calldata):
    print(f"deploying {alias} contract")

    account = await Account(account, network)

    current_time = time.time()

    # If devnet we need to write the call and check declerations manually
    if network == "devnet":
        print(f"🚀 Deploying {contract_name}")

        config = Config(nile_network=network)
        
        max_fee, nonce, _ = await _process_arguments(account, config.MAX_FEE, None)

        deployer_address = normalize_number(
            UNIVERSAL_DEPLOYER_ADDRESS
        )

        base_path = (BUILD_DIRECTORY, ABIS_DIRECTORY)

        register_abi = f"{base_path[1]}/{contract_name}.json"
        
        transaction, predicted_address = await create_udc_deploy_transaction(
            account=account,
            contract_name=contract_name,
            salt=int(current_time),
            unique=False,
            calldata=calldata,
            max_fee=max_fee or 0,
            deployer_address=deployer_address,
            nonce=nonce,
        )

        sig_r, sig_s = account.signer.sign(message_hash=transaction._get_tx_hash())

        type_specific_args = transaction._get_execute_call_args()

        output = await execute_call(
            "invoke",
            network,
            signature=[sig_r, sig_s],
            max_fee=config.MAX_FEE,
            query_flag=None,
            **type_specific_args
        )
        transaction_hash = _get_transaction_hash(output)
        tx_status = await status(normalize_number(transaction_hash), network, None)
        deployments.register(predicted_address, register_abi, network, alias)
        print(
            f"⏳ ️Deployment of {contract_name} "
            + f"successfully sent at {hex_address(predicted_address)}"
        )
        print(f"🧾 Transaction hash: {hex(tx_status.tx_hash)}")
    else:
        tx_wrapper = await account.deploy_contract(
            contract_name=contract_name,
            salt=int(current_time),
            unique=False,
            calldata=calldata,
            alias=alias,
            max_fee=config.MAX_FEE
        )

        await tx_wrapper.execute(watch_mode='track')

        get_tx_status(network, str(tx_wrapper.hash),)
