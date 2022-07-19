from realms_cli.config import Config


def run(nre):
    config = Config(nre.network)

    print("getting/deploying admin account")
    account = nre.get_or_deploy_account(
        signer=config.ADMIN_ALIAS
    )
    print(account.address)
