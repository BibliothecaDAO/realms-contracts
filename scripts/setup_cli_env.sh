#!/bin/bash

## Run Modes ##
# Import account from argentx (currently disabled)
OPTION1_IMPORT_ARGENTX_ACCOUNT=1;
# Generate new Account
OPTION2_GENERATE_ACCOUNT=2;
# Exit
OPTION3_EXIT=3;

#Example Argentx PK: 1738894601847262057947312354369785682447196114282863931776046095852523510768
VALID_ARGENTX_PK_REGEX='^[0-9]*$';

#Example Argentx Account: 0x02a35361e0aF1CEaC7ab383a7F0476fC2e864018661F14D5C6FaeE1C9eF40984
VALID_ARGENTX_ACCOUNT_REGEX='0x[a-fA-F0-9]*$';

# import_argentx_account prompts user for an ArgentX Private Key and Account and validates input
import_argentx_account() {
    while true; do
        read -p "Enter Private Key from ArgentX: " STARKNET_PRIVATE_KEY;
        if [[ $STARKNET_PRIVATE_KEY =~ $VALID_ARGENTX_PK_REGEX ]]; then
            break;
        fi
        echo "Provided input is not a valid PK";
    done
    # Get and validate Argentx account
    while true; do
        read -p "Enter Account Address from ArgentX: " STARKNET_ACCOUNT_ADDRESS
        if [[ $STARKNET_ACCOUNT_ADDRESS =~ $VALID_ARGENTX_ACCOUNT_REGEX ]] ; then
            break;
        fi
        echo "Provided input is not a valid account";
    done
    run_setup
}

#generate_account generates a PK and Account using nile
generate_account() {
    # Use nile to create new PK
    STARKNET_PRIVATE_KEY=$(nile create_pk);
    # Use nile to deploy new account using PK
    STARKNET_NETWORK=alpha-goerli STARKNET_PRIVATE_KEY=$STARKNET_PRIVATE_KEY nile setup STARKNET_PRIVATE_KEY > account_details.txt 2>&1;
    # Get Account
    STARKNET_ACCOUNT_ADDRESS=$(grep -i Account account_details.txt | grep -Eo "0x[a-fA-F0-9]{64}");

    # Output account info
    echo "Created new account";
    echo "PK: $STARKNET_PRIVATE_KEY";
    echo "Account: $STARKNET_ACCOUNT_ADDRESS";
    run_setup
}

# mode_selection allows user to select between importing an account or generating an account
mode_selection() {

    # temporarily carry out only account generation until ArgentX is fixed
    generate_account;

    # Re-prompt user if they enter invalid option
    while false; do
        echo "Please enter setup type";
        echo "1: Import account from ArgentX (recommended)";
        echo "2: Create new account";
        echo "3: Exit";
        read -p 'Setup Type: ' script_mode;
        case $script_mode in

            # For ArgentX import
            $OPTION1_IMPORT_ARGENTX_ACCOUNT)
                import_argentx_account;
                break;
            ;;

            # For New Account Generation
            $OPTION2_GENERATE_ACCOUNT)
                generate_account;
                break;
            ;;

            # Allow user to cleanly exit script
            $OPTION3_EXIT)
                exit 0;
            ;;
            *)
                echo 'Invalid option, please enter 1 or 2' >&2;
        esac
    done
}

update_bashrc() {
    # if starknet private key env var isn't in bashrc
    is_starknet_pk_in_bashrc=$(grep -c "export STARKNET_PRIVATE_KEY=" ~/.bashrc);
    if [ $is_starknet_pk_in_bashrc -eq 0 ]; then
        # add it
        echo "export STARKNET_PRIVATE_KEY=$STARKNET_PRIVATE_KEY" >> ~/.bashrc;
    fi

    # if starknet network env var isn't in bashrc
    is_starknet_network_in_bashrc=$(grep -c "export STARKNET_NETWORK=" ~/.bashrc);
    if [ $is_starknet_network_in_bashrc -eq 0 ]; then
        # add it
        echo "export STARKNET_NETWORK=$STARKNET_NETWORK" >> ~/.bashrc;
    fi

    # if starknet account env var isn't in bashrc
    is_starknet_account_in_bashrc=$(grep -c "export STARKNET_ACCOUNT_ADDRESS=" ~/.bashrc);
    if [ $is_starknet_account_in_bashrc -eq 0 ]; then
        # add it
        echo "export STARKNET_ACCOUNT_ADDRESS=$STARKNET_ACCOUNT_ADDRESS" >> ~/.bashrc;
    fi

    # if starknet public key env var isn't in bashrc
    is_starknet_pubkey_in_bashrc=$(grep -c "export STARKNET_PUBLIC_KEY=" ~/.bashrc);
    if [ $is_starknet_pubkey_in_bashrc -eq 0 ]; then
        # add it
        echo "export STARKNET_PUBLIC_KEY=$STARKNET_PUBLIC_KEY" >> ~/.bashrc;
    fi

    # if cairo path env var isn't in bashrc
    is_cairo_path_in_bashrc=$(grep -c "export CAIRO_PATH=" ~/.bashrc);
    if [ $is_cairo_path_in_bashrc -eq 0 ]; then
        # add it
        echo "export CAIRO_PATH=$CAIRO_PATH" >> ~/.bashrc;
    fi
}

# main setup code
run_setup () {
    # set CAIRO_PATH if not already set (e.g. from Dockerfile)
    export CAIRO_PATH=${CAIRO_PATH:-/loot/realms-contracts/lib/cairo_contracts/src}
    export STARKNET_NETWORK=alpha-goerli
    export STARKNET_PRIVATE_KEY=$STARKNET_PRIVATE_KEY
    export STARKNET_PUBLIC_KEY=`python -c 'import os; from nile.signer import Signer; private_key = int(os.environ["STARKNET_PRIVATE_KEY"]); signer = Signer(private_key); print(signer.public_key)'`

    # add above env vars to bashrc
    update_bashrc

    # compile contracts
    # nile compile
    nile compile lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo --account_contract

    GOERLI_DEPLOYMENTS_FILE=goerli.deployments.txt
    # If the system already has a goerli deployments file
    if [ -f "$GOERLI_DEPLOYMENTS_FILE" ]; then
        # back it up before we overwrite it just in case
        cp $GOERLI_DEPLOYMENTS_FILE $GOERLI_DEPLOYMENTS_FILE.backup
    fi

cat <<EOT > $GOERLI_DEPLOYMENTS_FILE
0x003ca62a639a4e3821eb02f6ac0101f0877b925ef718b5e1a6f5d51b59b5d3d0:artifacts/abis/Arbiter.json:Arbiter
0x0221d3881e8f136838bc6cbd9d425e800ea584fb019cd566ac05a4c5fb7befa1:artifacts/abis/Arbiter.json:proxy_Arbiter
0x0648e8fd66cde815636c62e2e97d761c4f56a6c041c22568e8fab8466021fc57:artifacts/abis/ModuleController.json:ModuleController
0x032d7b20d1e0455cf9cd40784d8a5fe1e02acb6f7278179c6c2011bb98bed154:artifacts/abis/ModuleController.json:proxy_ModuleController
0x014b32c7def1977cf85d9ac4e90c040249dfe61a71e090890f69a4d7a01dba89:artifacts/abis/xoroshiro128_starstar.json:xoroshiro128_starstar
0x007a29730cfaed96839660577c3b3019038862187b0865280b79e944c66ac215:artifacts/abis/Settling.json:proxy_Settling
0x058d3a1a5fe490cdbfbb14c7a648142b3b7debb65747450b76f604c3c39f4cfe:artifacts/abis/Resources.json:proxy_Resources
0x01c7a86cea8febe69d688dd5ffa361e7924f851db730f4256ed67fd805ea8aa7:artifacts/abis/Buildings.json:proxy_Buildings
0x04354c123f60faf3507aa9c9abf0e7fddfcac40a322df88e06d18de6dad61988:artifacts/abis/Calculator.json:Calculator
0x04f65c9451f333e0fbe33f912f470da360cf959ea0cefb85f0abef54fd3bb76c:artifacts/abis/Calculator.json:proxy_Calculator
0x039f40b33de4d22b2c140fccbcf2092ccc24ebdb7ed985716b93f763ae5607e8:artifacts/abis/Combat.json:proxy_Combat
0x0415bda0925437cee1cd70c5782c65a5b1f5c72945c5204dbba71c6d69c8575a:artifacts/abis/Travel.json:proxy_Travel
0x02d73a83afeaf5927c2dfb51b2412ea9dfe1fb6cd41b1b702607e7345ce47d09:artifacts/abis/Food.json:proxy_Food
0x06052bf4631585f7074a118543121561d12cc910e0ab95b48039eab587e078d2:artifacts/abis/Relics.json:proxy_Relics
0x04de5e1a2aaf2f577618f17f9c1ff4b73ab26e1b85df4742ab314e1e5337874b:artifacts/abis/Lords_ERC20_Mintable.json:Lords_ERC20_Mintable
0x0371e76cc9dc2cf151201e3fff62dc816636fe918e4c90604e9ed1369b7d1d5e:artifacts/abis/Lords_ERC20_Mintable.json:proxy_Lords_ERC20_Mintable
0x02ab849a3eaf4fd54f80e6dbe7a8d182646ec41684d1f1a4f718623bd8cb0695:artifacts/abis/Realms_ERC721_Mintable.json:proxy_Realms_ERC721_Mintable
0x016a1b978c62be5c30faa565f2086336126db3f120fbe61f368d8e07f289ef03:artifacts/abis/S_Realms_ERC721_Mintable.json:proxy_S_Realms_ERC721_Mintable
0x07080e87497f82ac814c6eaf91d66ac93672927a8c019014f05eb6d688ebd0fc:artifacts/abis/Resources_ERC1155_Mintable_Burnable.json:proxy_Resources_ERC1155_Mintable_Burnable
0x0441181da8e4d3ca2add537dff9d80b4ac1300cc67b0ceffd75147c4f1915048:artifacts/abis/Settling.json:Settling
0x06454ecb367df2d47f557dc5ff130ecde1b66dd98119881ae327b4b3c8ff9944:artifacts/abis/Buildings.json:Buildings
0x0285a8061f3114997f5e479b6985fa4e51a71d68cc910d4eb0f1fe5422dfdd0e:artifacts/abis/Relics.json:Relics
0x079155beb3187926dc87cf3c42bb4729f73cbf56c5e19e32bec702650bf0c3ef:artifacts/abis/Exchange_ERC20_1155.json:Exchange_ERC20_1155
0x042bf805eb946855cc55b1321a86cd4ece9904b2d15f50c47439af3166c7c5e2:artifacts/abis/PROXY_Logic.json:proxy_Exchange_ERC20_1155
0x001bdf6e7049994c2f4bfb20111bd1e7957c9453f1d8d57b6cfe79e22ce647fd:artifacts/abis/Resources_ERC1155_Mintable_Burnable.json:Resources_ERC1155_Mintable_Burnable
0x0451cbe505243521da1fd9276b4cade0d3e1300ee4ee1a909d52e7b2fa3ee8e1:artifacts/abis/Realms_ERC721_Mintable.json:Realms_ERC721_Mintable
0x076a008edb23e45dc3e5e2cedaa2a6d6cfc848f0a435483aa8501e10f438667e:artifacts/abis/S_Realms_ERC721_Mintable.json:S_Realms_ERC721_Mintable
0x0442d96807d4bb464ecde88496f22e88dfa17ec227bc053cbf81f475507c1d15:artifacts/abis/Resources.json:Resources
0x04097d3c8c6cf53c874a8acbf0eb11c1caa6d48f895347c94229275f98028d5a:artifacts/abis/Food.json:Food
0x0191c8d38bbae6722ef6cd85a050b754a892df1aa0d90d5973df25ab3c99f01b:artifacts/abis/Travel.json:Travel
0x0545af632491bef458c5d389c787ab59b265d4c9f5c0323260a5d0e596572075:artifacts/abis/Combat.json:Combat
$STARKNET_ACCOUNT_ADDRESS:/usr/local/lib/python3.9/site-packages/nile/artifacts/abis/Account.json:account-0
EOT

GOERLI_ACCOUNTS_JSON_FILE=goerli.accounts.json
# if the system already has a goerli accoounts file
if [ -f "$GOERLI_ACCOUNTS_JSON_FILE" ]; then
    # back it up before we overwrite it just in case
    cp $GOERLI_ACCOUNTS_JSON_FILE $GOERLI_ACCOUNTS_JSON_FILE.backup
fi

cat <<EOT > $GOERLI_ACCOUNTS_JSON_FILE
{"$STARKNET_PUBLIC_KEY": {"address": "$STARKNET_ACCOUNT_ADDRESS", "index": 0, "alias": "STARKNET_PRIVATE_KEY"}}
EOT
    pip install realms_cli/
}

has_valid_env_vars() {
    # If the STARKNET_PRIVATE_KEY AND STARKNET_ACCOUNT_ADDRESS env vars are not empty
    if [ ! -z "$STARKNET_PRIVATE_KEY" ] && [ ! -z "$STARKNET_ACCOUNT_ADDRESS" ]; then

        # and env vars are valid
        if [[ $STARKNET_PRIVATE_KEY =~ $VALID_ARGENTX_PK_REGEX ]] && [[ $STARKNET_ACCOUNT_ADDRESS =~ $VALID_ARGENTX_ACCOUNT_REGEX ]]; then
            echo "Found starknet env vars, skipping account import/generation"
            # return true
            true
            return

        else
            # output invalid env vars to user
            echo "Found starknet env vars but one or both are invalid, proceeding to account import/generation";
            echo "STARKNET_PRIVATE_KEY: $STARKNET_PRIVATE_KEY";
            echo "STARKNET_ACCOUNT_ADDRESS: $STARKNET_ACCOUNT_ADDRESS";
            echo "Redirecting to setup wizard...";
            # and return false
            false
            return
        fi

    else #one or both of the env vars are empty
        echo "Did not find starknet env vars, proceeding to account import/generation";
        # so return false
        false
        return
    fi
}

main() {

    # source bashrc to pickup any preset starknet env vars
    source ~/.bashrc

    # if system has valid env vars already set
    if has_valid_env_vars; then
        # proceed to setup
        run_setup;
    # else system does not have valid env vars
    else
        # so proceed to mode selection
        mode_selection;
    fi
}

main
