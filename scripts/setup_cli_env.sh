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
    nile compile
    nile compile lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo --account_contract

cat <<EOT > goerli.deployments.txt
0x00155e87abe207e81645c236df829448268f636d41bf5851e5e39e27af5324ed:artifacts/abis/Lords_ERC20_Mintable.json:lords
0x0448549cccff35dc6d5df90efceda3123e4cec9fa2faff21d392c4a92e95493c:artifacts/abis/Lords_ERC20_Mintable.json:proxy_lords
0x076bb5a142fa1d9c5d3a46eefaec38cc32b44e093432b1eb46466ea124f848a5:artifacts/abis/Realms_ERC721_Mintable.json:proxy_realms
0x06f798682fc548e98a9556b624eb110f1bc37eeadd16bc2f49056f8ede7993c5:artifacts/abis/S_Realms_ERC721_Mintable.json:proxy_s_realms
0x07144f39e676656e81d482dc2cc9f68c98d768fe1beaad28438b43142cc9ff9e:artifacts/abis/Resources_ERC1155_Mintable_Burnable.json:proxy_resources
0x062b452dda20b2429162be78c523f19eb0184d7cdaef629d589e8a810247e5e1:artifacts/abis/Arbiter.json:arbiter
0x0492ce976d4553fee0254c06e18071e5d46774fe5019974fd3f216ee6b16f3a7:artifacts/abis/xoroshiro128_starstar.json:xoroshiro128_starstar
0x03f0525eabae93b3be2ad366deae88d40dab132c23d7602de47600810f0b985f:artifacts/abis/ModuleController.json:moduleController
0x00221468878ebce900098b0ae1fc4f5d717985f84a206267acca37a6de8f6638:artifacts/abis/L05_Wonders.json:L05_Wonders
0x02b4b514e756a7f505711383261214873fe44ba19974f0e0352dce3b5c890d76:artifacts/abis/L01_Settling.json:proxy_L01_Settling
0x06f0e13b23b610534484e8347f78312af6c11cced04e34bd124956a915e5c881:artifacts/abis/L02_Resources.json:proxy_L02_Resources
0x07e6ef6eae7a6d03baaace2fe8b5747ed52fa6c7ae615f3e3bd3311ac98d139a:artifacts/abis/L03_Buildings.json:proxy_L03_Buildings
0x05a74143789f2b8d2a95234318d7072062e449d37f9e882af68af663f9078ef7:artifacts/abis/L04_Calculator.json:proxy_L04_Calculator
0x0096cae38dd01a1e381c9e57db09669298fa079cfdb45e1a429c4020a6515549:artifacts/abis/L05_Wonders.json:proxy_L05_Wonders
0x0139bad2b0b220d71ea1fc48fa2858e993b3d471a3b03be609c54ff0c9795d71:artifacts/abis/L06_Combat.json:proxy_L06_Combat
0x071ef6edce183a06e5593dfe569fc2c0b2115f75cbe5c393b4f3ef16f8f91546:artifacts/abis/Realms_ERC721_Mintable.json:realms
0x05374cb211bed8a19365768356775f03bbff87cd2351b26958ada6e4b2f86783:artifacts/abis/S_Realms_ERC721_Mintable.json:s_realms
0x010d1d81cc63b38bdd4bb2d14a46794e27adbd5b25eb50ee680997dcb15eb035:artifacts/abis/Resources_ERC1155_Mintable_Burnable.json:resources
0x027d0dd8dbe02f8dec5ff64b873eb78993c520f7c6f10b95f86cb061857769d0:artifacts/abis/Relics.json:proxy_Relics
0x03a34ef38f402d6b66b681db7905edfc48676288a7b08cd79910737c45431093:artifacts/abis/Food.json:proxy_Food
0x0082593b45f86b7659f885604872e8ee63efea22d14fad6504a4dc2a4f74d8f1:artifacts/abis/L04_Calculator.json:L04_Calculator
0x015eba242880374267dc54900b7d569a964fcd8d251a2edfb66a4ec9a78eaedc:artifacts/abis/Exchange_ERC20_1155.json:proxy_Exchange_ERC20_1155
0x07220e609523f50a89a8070358a2d512c5c68dcca8afa5c41d7ac2406d8a5db8:artifacts/abis/Exchange_ERC20_1155.json:Exchange_ERC20_1155
0x04dd3bb52964c9c57e8d1fd2144604a993cc5cb517182573a03b038666ab5705:artifacts/abis/SingleSidedStaking.json:SingleSidedStaking
0x0259f9adda2c8a7e651d03472cb603ef2c69ae9a64fd3a553415d082ddbb3061:artifacts/abis/SingleSidedStaking.json:proxy_SingleSidedStaking
0x020255b2f2079308299821c57437b17bd4a65183b3d4ac9b7532af9aebb976c0:artifacts/abis/Splitter.json:Splitter
0x06a60b479e9fe080fd8e0a8c4965040a25e276889c2de0cf105c410d0ac81436:artifacts/abis/Splitter.json:proxy_Splitter
0x04926f7b30bc33eb800e64992a669d4dcea96aa1fc9c1673cd9e1853487bc422:artifacts/abis/Relics.json:Relics
0x03f233b0c1aa84b4a05ff55c7a3a0c1f6ba876030b06200ac27e80f338f59120:artifacts/abis/GoblinTown.json:proxy_GoblinTown
0x02d8ae390c432eecc12f18d1c7c0e0283fee8abe6c4eecdae03753ec75cee3d8:artifacts/abis/L01_Settling.json:L01_Settling
0x05983a41fad00287a3aa4dac3c385c1df7ba7af543fe3e7f3dfe4feb380b9fc4:artifacts/abis/L02_Resources.json:L02_Resources
0x015586088996583d7dfa0cbe081aec0761275cd88be19eff8a61e652cca32bde:artifacts/abis/L03_Buildings.json:L03_Buildings
0x07a0f46622f20fdd2bc1c212acb8412f66e48ee6b076b0bdf13f5640b61042f9:artifacts/abis/Food.json:Food
0x0139de3bb4fc551b4c30f73256b822bb130208ad27d3cdbede7a8af706ef2ddf:artifacts/abis/GoblinTown.json:GoblinTown
0x026ae695e80142822f5bbff3d58c5763d5de6cef1e67433ad5e5efd425ece250:artifacts/abis/Loot.json:proxy_Loot
0x07c5ad28e6ce3aee36a72b065fa4bd8a2afa29a9dbd37e642f6965497e88c380:artifacts/abis/Adventurer.json:proxy_Adventurer
0x02f850d76b3011d67ca4828785838d1ad4930124f7369e4983afe0ce9b638eae:artifacts/abis/Adventurer.json:Adventurer
0x0426af93209f44ae0e5d27ab93b9180af32baa95502811df8ae6892d9874bfdf:artifacts/abis/Loot.json:Loot
0x047024ede6449b6a980ca46faaa8180d48ca0b0f31fb8a42c51e45a9e84e0e57:artifacts/abis/L06_Combat.json:L06_Combat
0x04d4e010850d0df3c6fd9672a72328514acc5e1285935104a29d215184903582:artifacts/abis/Combat.json:proxy_Combat
0x05f273c4a45dab6e8112e2370bd84f58cfd2f1ff83752c2582241c0c0acba9be:artifacts/abis/Travel.json:proxy_Travel
0x0045e9349f703c44e32f9851d5b9409f0d1bd55ca2f061a894a29397c9c1ea9a:artifacts/abis/Travel.json:Travel
0x063431c98f0a5b9f4187b8c5616c8063d37e8e2d7b02ff9796c777bf5922205a:artifacts/abis/Combat.json:Combat
$STARKNET_ACCOUNT_ADDRESS:/usr/local/lib/python3.9/site-packages/nile/artifacts/abis/Account.json:account-0
EOT

cat <<EOT > goerli.accounts.json
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
