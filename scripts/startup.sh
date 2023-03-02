#!/bin/bash

file_does_not_exist() {
    if [ -f "$1" ]; then
        return 1
    else
        return 0 
    fi
}

if file_does_not_exist "goerli.accounts.json"; then
    # Prompt the user for the private key
    read -p "Enter your private key (You get this from Argent): " private_key

    # Prompt the user for the address
    read -p "Enter the address (You get this from Argent): " address

    # Call the Python script and pass the private key and address as arguments
    json=$(python3 scripts/get_public_key_from_private_key.py "$private_key" "$address")

    echo "$json" > "goerli.accounts.json"

    # Write the JSON output to a file
    echo "export MAX_FEE=8989832783197500" > "realms_cli/.env.nile"
    echo "export STARKNET_NETWORK=goerli" > "realms_cli/.env.nile"
    echo "export STARKNET_PRIVATE_KEY=${private_key}" > "realms_cli/.env.nile"

    echo "${address}:/usr/local/lib/python3.9/site-packages/nile/artifacts/abis/Account.json:STARKNET_PRIVATE_KEY" > goerli.deployments.txt
    echo "0x047bccb3bb7707224431efdb5b24d0f5051569a858b4bef3ec5f145f5bddd741:artifacts/abis/Arbiter.json:Arbiter_Loot" >> goerli.deployments.txt
    echo "0x04bf33f5750cf91b274e454aee797bd6cc9a45f51cb2b83c206ab85a66182fdc:artifacts/abis/PROXY_Logic.json:proxy_Arbiter_Loot" >> goerli.deployments.txt
    echo "0x0584c995814e70bae0cf23972d72458d7ac748c2c890e1860e2b9ec44f76f6a4:artifacts/abis/ModuleController.json:ModuleController_Loot" >> goerli.deployments.txt
    echo "0x066213a37197a8ffee97c66696ed7eb9ec89fe80ef984e02df456224b2fbf436:artifacts/abis/PROXY_Logic.json:proxy_ModuleController_Loot" >> goerli.deployments.txt
    echo "0x03ff460370753891a18e13662d22f1849859a552291cea3d72efd3807065ae53:artifacts/abis/PROXY_Logic.json:proxy_Adventurer" >> goerli.deployments.txt
    echo "0x05b1e584fc5da3bbee9d260761521604142e9b5b1cda2fa533b4fdfbc038cfb6:artifacts/abis/PROXY_Logic.json:proxy_LootMarketArcade" >> goerli.deployments.txt
    echo "0x07f50583c7e4f9b56eff393f5b5136fc45c21b48eef3408aaca7983d654de109:artifacts/abis/PROXY_Logic.json:proxy_Beast" >> goerli.deployments.txt
    echo "0x0371e76cc9dc2cf151201e3fff62dc816636fe918e4c90604e9ed1369b7d1d5e:artifacts/abis/Lords_ERC20_Mintable.json:proxy_Lords_ERC20_Mintable" >> goerli.deployments.txt

    # Print success message to console
    echo "File 'goerli.deployments.txt' created successfully."

    curl -L https://raw.githubusercontent.com/software-mansion/protostar/master/install.sh | bash

    current_dir=$(pwd)

    export CAIRO_PATH="$CAIRO_PATH:$current_dir/lib/cairo_graphs/src:$current_dir/lib/cairo_contracts/src:$current_dir/lib/cairo_math_64x61/contracts:$current_dir/lib/guild_contracts"

    nile compile --directory contracts/loot
    nile compile contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo

    source realms_cli/.env.nile
else
    source realms_cli/.env.nile        
fi


