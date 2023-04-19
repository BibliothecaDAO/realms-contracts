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
    echo "$json" > "devnet.accounts.json"

    # Write the JSON output to a file
    echo "export MAX_FEE=8989832783197500" > "realms_cli/.env.nile"
    echo "export STARKNET_NETWORK=goerli" > "realms_cli/.env.nile"
    echo "export STARKNET_PRIVATE_KEY=${private_key}" > "realms_cli/.env.nile"

    current_dir=$(pwd)
    base_dir=$(cd .. "$current_dir")

    echo "${address}:/usr/local/lib/python3.9/site-packages/nile/artifacts/abis/Account.json:STARKNET_PRIVATE_KEY
0x07895e3320c1f1c62a73d465c8f4a412ae2042c55d0f274e8992518509c3cd1f:artifacts/abis/PROXY_Logic.json:proxy_Arbiter_Loot
0x05cd498ac61b8b8fd72c9225cfff4b14a35486dd7727928f26d044996fc0824d:artifacts/abis/PROXY_Logic.json:proxy_ModuleController_Loot
0x0761b04b53668ee5098c0d1f3d1c380b9d524b602569638012a6d6eb45fb6d1f:artifacts/abis/xoroshiro128_starstar.json:xoroshiro128_starstar
0x035d755a23ec72df90819f584d9a1849bbc21fa77f96d25e03f1736883895248:artifacts/abis/PROXY_Logic.json:proxy_Adventurer
0x065669e15c8f1a7f17b7062e4eb1b709b922b931b93c59577f1848a85c30ab1f:artifacts/abis/PROXY_Logic.json:proxy_LootMarketArcade
0x000f4dbfe5d15792aa91025e42ee1d74c22bdeb1eef0b9bc19a37216377290c1:artifacts/abis/PROXY_Logic.json:proxy_Beast
0x077d8cc306aee2bcf765026b995e17245e2afa95a52e53dee42f83b683c9b6f6:artifacts/abis/PROXY_Logic.json:proxy_Realms_ERC721_Mintable
0x023b86be0b3da5c2fdbd80d1d57f1b54391588ba338acecdd014a208d47ba9ca:artifacts/abis/Lords_ERC20_Mintable.json:Lords_ERC20_Mintable" > goerli.deployments.txt

    echo "${address}:/usr/local/lib/python3.9/site-packages/nile/artifacts/abis/Account.json:STARKNET_PRIVATE_KEY
0x016686720bb4d2e837cd9117b6ebb332150f3d3b76f808392ec090abc8cabfd9:artifacts/abis/PROXY_Logic.json:proxy_Arbiter_Loot
0x00f673f85de2cfda348f7502d5cbf2fd7a11ad24cf8289d555f1d2d8bdcdfe5a:artifacts/abis/PROXY_Logic.json:proxy_ModuleController_Loot
0x03f56f66fe17639063cd64419fbac017b947e2e9b0101de10c241a436bdbce08:artifacts/abis/xoroshiro128_starstar.json:xoroshiro128_starstar
0x037e26f2adab0b4ac64ce408881457686a4fd97d07e7bd7459e5a519bc647811:artifacts/abis/PROXY_Logic.json:proxy_Adventurer
0x05b883f6b530da72886e128cfebd46fee77c583baf25279bdace1d2d4aa0d935:artifacts/abis/PROXY_Logic.json:proxy_LootMarketArcade
0x01adcc3cee58a8573e0d3568f01166f4099892d6fa51af27cd000297b15a2e7b:artifacts/abis/PROXY_Logic.json:proxy_Beast
0x01a4d3b1ab365e95a0192c95bc02333cd8d932df9c883cf95053181195232ada:artifacts/abis/PROXY_Logic.json:proxy_Realms_ERC721_Mintable
0x045991fbbb425e786ac9273bc5cad63a7a56aa23d3968d98a76a8d0f951c4e69:artifacts/abis/Lords_ERC20_Mintable.json:Lords_ERC20_Mintable" > devnet.deployments.txt

    # Print success message to console
    echo "File 'goerli.deployments.txt' created successfully."

    curl -L https://raw.githubusercontent.com/software-mansion/protostar/master/install.sh | bash -s -- -v 0.8.1

    case $SHELL in
    */zsh) 
        # assume Zsh
        source ~/.zshrc
        ;;
    */bash)
        # assume Bash
        source ~/.bashrc
        ;;
    *)
        # assume something else
    esac

    protostar install

    export CAIRO_PATH="$CAIRO_PATH:$current_dir/lib/cairo_graphs/src:$current_dir/lib/cairo_contracts/src:$current_dir/lib/cairo_math_64x61/contracts:$current_dir/lib/guild_contracts"

    nile compile contracts/loot/adventurer/Adventurer.cairo
    nile compile contracts/loot/beast/Beast.cairo
    nile compile contracts/loot/loot/LootMarketArcade.cairo
    nile compile contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo
    nile compile contracts/settling_game/tokens/Realms_ERC721_Mintable.cairo
    nile compile contracts/settling_game/proxy/PROXY_Logic.cairo

    source realms_cli/.env.nile
else
    # print user already has file
    read -p "You already have goerli.accounts.json file"

    source realms_cli/.env.nile        
fi


