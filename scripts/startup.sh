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
    read -p "Enter your wallet address of the private key (You get this from Argent): " address

    # Call the Python script and pass the private key and address as arguments
    json=$(python3 scripts/get_public_key_from_private_key.py "$private_key" "$address")

    echo "$json" > "goerli.accounts.json"

    # Write the JSON output to a file
    echo "export MAX_FEE=8989832783197500" > "realms_cli/.env.nile"
    echo "export STARKNET_NETWORK=goerli" > "realms_cli/.env.nile"
    echo "export STARKNET_PRIVATE_KEY=${private_key}" > "realms_cli/.env.nile"

    echo "${address}:/usr/local/lib/python3.9/site-packages/nile/artifacts/abis/Account.json:STARKNET_PRIVATE_KEY
0x0069969ff7e92c67d57927d1aca0b114cf2e1d1ff61440e9dc1f36f2b3241179:artifacts/abis/PROXY_Logic.json:proxy_Arbiter_Loot
0x044bf83de260761cc82442fe7cca9b6cc769749aa171ce04443f5f93e6d74b03:artifacts/abis/PROXY_Logic.json:proxy_ModuleController_Loot
0x02043e0a1f5dea8a5d22cccbae31738ee139e56e8b43b9bde5b095bc20a1cb36:artifacts/abis/xoroshiro128_starstar.json:xoroshiro128_starstar
0x047ce016a470b9fb3fd212ac0ce8e7cf035919a715e3381cfff9624eec1a3815:artifacts/abis/PROXY_Logic.json:proxy_Adventurer
0x01b73f18ffe0364d5634ddebdd6a428110a183861e4bf962b7e6f69bb9ddc1e5:artifacts/abis/PROXY_Logic.json:proxy_LootMarketArcade
0x0372dc195187c789a4f97487911fb3db895d180b2fc53bfa69f85f933e8424e6:artifacts/abis/PROXY_Logic.json:proxy_Beast
0x0012c7b2514421e3c7c215287b7338fd6c59ae64d7b0be64a7887b9641f78c8f:artifacts/abis/Lords_ERC20_Mintable.json:Lords_ERC20_Mintable" > goerli.deployments.txt

    # Print success message to console
    echo "File 'goerli.deployments.txt' created successfully."

    curl -L https://raw.githubusercontent.com/software-mansion/protostar/master/install.sh | bash

    # Activate protostar path in mac
    source ~/.bashrc

    protostar install

    current_dir=$(pwd)

    export CAIRO_PATH="$CAIRO_PATH:$current_dir/lib/cairo_graphs/src:$current_dir/lib/cairo_contracts/src:$current_dir/lib/cairo_math_64x61/contracts:$current_dir/lib/guild_contracts"

    nile compile --directory contracts/loot
    nile compile contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo
    nile compile contracts/settling_game/tokens/Realms_ERC721_Mintable.cairo
    nile compile contracts/settling_game/proxy/PROXY_Logic.cairo

    source realms_cli/.env.nile
else
    # print user already has file
    read "You already have goerli.accounts.json file"

    source realms_cli/.env.nile        
fi


