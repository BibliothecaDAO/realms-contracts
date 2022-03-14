# Requirements

Create a contract account, if you haven't already, which can programmatically execute the following scripts.

Run `npx ts-node ./tasks/deploy_account.ts` and view the resulting file. The private key is output in the file and also logged. Save that key and set an environment variable in the `.env` local file.

`ARBITER_PRIVATE_KEY=0x123345....`

# How to start game

Run `npx ts-node ./tasks/desiege/create_game.ts`

# Desiege Deployment Sequence

1. `npx ts-node ./tasks/desiege/deploy_arbiter.ts`
2. `npx ts-node ./tasks/desiege/deploy_module_controller.ts`
3. `npx ts-node ./tasks/desiege/deploy_elements_token.ts`
4. `npx ts-node ./tasks/desiege/deploy_tower_defence.ts`
5. `npx ts-node ./tasks/desiege/deploy_tower_defence_storage.ts`
6. `npx ts-node ./tasks/desiege/setup_controller_modules.ts`
