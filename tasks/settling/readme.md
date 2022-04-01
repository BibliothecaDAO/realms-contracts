# Requirements

Create a contract account, if you haven't already, which can programmatically execute the following scripts.

Run `npx ts-node ./tasks/deploy_account.ts` and view the resulting file. The private key is output in the file and also logged. Save that key and set an environment variable in the `.env` local file.

`OWNER_PRIVATE_KEY=0x123345....`

# How to start game

Run `npx ts-node ./tasks/desiege/create_game.ts`

# Tokens Deployment - This only has to be done once. These should be deployed first

1. `npx ts-node ./tasks/tokens/settling/deploy_realms.ts`
2. `npx ts-node ./tasks/tokens/settling/deploy_resources.ts`
3. `npx ts-node ./tasks/tokens/settling/deploy_lords.ts`
4. `npx ts-node ./tasks/tokens/settling/deploy_s_realms.ts`

# Settling Deployment Sequence

1. `npx ts-node ./tasks/settling/deploy_arbiter.ts`
2. `npx ts-node ./tasks/settling/deploy_module_controller.ts`
3. `npx ts-node ./tasks/settling/modules/01_deploy_settling.ts`
4. `npx ts-node ./tasks/settling/modules/02_deploy_resources.ts`
5. `npx ts-node ./tasks/settling/modules/03_deploy_buildings.ts`
6. `npx ts-node ./tasks/settling/modules/04_deploy_calculator.ts`
7. `npx ts-node ./tasks/settling/set_initial_module_addresses.ts` // do last

# Updating Module

1. `npx ts-node ./tasks/settling/modules/update_module_calculator.ts`