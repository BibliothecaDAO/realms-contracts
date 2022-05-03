# Requirements

Create a contract account, if you haven't already, which can programmatically execute the following scripts.

Run `npx ts-node ./tasks/deploy_account.ts` and view the resulting file and logs. The private key is logged one time. Save that key and set an environment variable in the `.env` local file.

Your .env file should look like:

```
DEPLOY_BASE=./minigame-deployments/starknet
ACCOUNT_NAME=OwnerAccountDesiege
STARKNET_ACCOUNT_ADDRESS=deployed_address
STARKNET_PRIVATE_KEY=<private_key>
```
replacing `deployed_address` and `private_key` with the respective vallues after running

# How to start game

Run `npx ts-node ./tasks/desiege/create_game.ts`

# Desiege Deployment Sequence

1. `npx ts-node ./tasks/desiege/deploy_arbiter.ts`
2. `npx ts-node ./tasks/desiege/deploy_module_controller.ts`
3. `npx ts-node ./tasks/desiege/deploy_elements_token.ts`
4. `npx ts-node ./tasks/desiege/deploy_tower_defence.ts`
5. `npx ts-node ./tasks/desiege/deploy_tower_defence_storage.ts`
6. `npx ts-node ./tasks/desiege/setup_controller_modules.ts`
7. `npx ts-node ./tasks/desiege/deploy_element_balancer.ts`
8. `npx ts-node ./tasks/desiege/deploy_divine_eclipse_storage.ts`
