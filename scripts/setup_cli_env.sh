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

# Checks if environment is already setup
setup_already_run() {

    # if bashrc does not contain the starknet private key
    is_starknet_pk_in_bashrc=$(grep -c "export STARKNET_PRIVATE_KEY=" ~/.bashrc);
    if [ $is_starknet_pk_in_bashrc -eq 0 ]; then
        # the setup script hasn't been run so return false
        false
        return
    fi

    # if bashrc is setup, setup script has already run
    true
    return
}

main() {

    # source bashrc to pickup any preset starknet env vars
    source ~/.bashrc

    # if system has valid env vars already set
    if has_valid_env_vars; then
        # and is not already setup
        if [ ! setup_already_run ]; then
            run_setup;
        else
            echo "System already setup, nothing to do";
        fi
    # else system does not have valid env vars
    else
        # so proceed to mode selection
        mode_selection;
    fi
}

main
