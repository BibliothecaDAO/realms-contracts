# Requirements

Create a contract account, if you haven't already, which can programmatically execute the following scripts.

Run `npx ts-node ./tasks/deploy_account.ts` and view the resulting file. The private key is output in the file and also logged. Save that key and set an environment variable in the `.env` local file.

`OWNER_PRIVATE_KEY=0x123345....`

# Tokens Deployment - This only has to be done once. These should be deployed first

### Deploy All
`npx ts-node ./tasks/settling/tokens/deploy_all_tokens.ts`

### Deploy specific
1. `npx ts-node ./tasks/settling/tokens/deploy_realms.ts`
2. `npx ts-node ./tasks/settling/tokens/deploy_resources.ts`
3. `npx ts-node ./tasks/settling/tokens/deploy_lords.ts`
4. `npx ts-node ./tasks/settling/tokens/deploy_s_realms.ts`

## DB
5. `npx ts-node ./tasks/settling/modules/deploy_storage.ts`

# Settling Deployment Sequence
1. `npx ts-node ./tasks/settling/modules/deploy_arbiter.ts`
2. `npx ts-node ./tasks/settling/modules/deploy_module_controller.ts`
3. `npx ts-node ./tasks/settling/modules/01_deploy_settling.ts`
4. `npx ts-node ./tasks/settling/modules/02_deploy_resources.ts`
5. `npx ts-node ./tasks/settling/modules/03_deploy_buildings.ts`
6. `npx ts-node ./tasks/settling/modules/04_deploy_calculator.ts`
6. `npx ts-node ./tasks/settling/modules/05_deploy_wonder_tax.ts`
7. `npx ts-node ./tasks/settling/modules/set_initial_module_addresses.ts` // do last

# Updating Module

1. `npx ts-node ./tasks/settling/modules/update_module_calculator.ts`

# Helpers

1. `npx ts-node ./tasks/settling/modules/update_s_realms_module_address.ts`
1. `npx ts-node ./tasks/settling/modules/set_initial_module_addresses.ts`

# Data Setters

1. `npx ts-node ./tasks/settling/data/set_realms_data.ts`

# Game actions

1. `npx ts-node ./tasks/settling/game_actions/mint_realm_stake.ts`
