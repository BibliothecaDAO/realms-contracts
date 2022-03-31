# Requirements

Create a contract account, if you haven't already, which can programmatically execute the following scripts.

Run `npx ts-node ./tasks/deploy_account.ts` and view the resulting file. The private key is output in the file and also logged. Save that key and set an environment variable in the `.env` local file.

`OWNER_PRIVATE_KEY=0x123345....`

# How to start game

Run `npx ts-node ./tasks/desiege/create_game.ts`

# Settling Deployment Sequence

1. `npx ts-node ./tasks/settling/deploy_arbiter.ts`
2. `npx ts-node ./tasks/settling/deploy_module_controller.ts`

# Tokens Deployment - This only has to be done once. These are non-upgradable

1. `npx ts-node ./tasks/settling/deploy_realms.ts`
2. `npx ts-node ./tasks/settling/deploy_resources.ts`
3. `npx ts-node ./tasks/settling/deploy_lords.ts`
