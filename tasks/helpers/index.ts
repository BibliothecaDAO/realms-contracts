import { Provider, ec, Signer } from 'starknet'
import fs from 'fs'
import { toBN } from 'starknet/dist/utils/number'
import { config as dotenvConfig } from "dotenv";
import { resolve } from "path";

dotenvConfig({ path: resolve(__dirname, "../../.env") });

export const DEPLOYMENT_PATH_BASE = "./minigame-deployments/starknet";

export function getPathBase() {
  if (process.env.NETWORK && process.env.NETWORK !== "goerli") {
    return `${DEPLOYMENT_PATH_BASE}-${process.env.NETWORK}`;
  }

  return `${DEPLOYMENT_PATH_BASE}-goerli`;
}

export function setupDeploymentDir() {
  const path_base = getPathBase()

  if (!fs.existsSync(path_base)) {
    fs.mkdirSync(path_base, { recursive: true })
  }
}

export function checkDeployment(contractName: string) {
  const path_base = getPathBase()

  if (fs.existsSync(`${path_base}/${contractName}.json`)) {
    throw new Error("Deployment already exists")
  }
}

export function getOwnerAccountInt(): string {
  const path_base = getPathBase()

  if (process.env.OWNER_ACCOUNT) {
    return BigInt(process.env.OWNER_ACCOUNT).toString()
  }

  try {  
    const file = fs.readFileSync(`${path_base}/OwnerAccount.json`)

    const parsed = JSON.parse(file.toString())

    return BigInt(parsed.address).toString()
  } catch (error) {
    console.log(`No OWNER_ACCOUNT env variable nor "${path_base}/OwnerAccount.json" provided.`)
    throw error
  }
}

export function writeDeployment(contractAlias: string, result: any) {
  const path_base = getPathBase()

  fs.writeFileSync(`${path_base}/${contractAlias}.json`, JSON.stringify({
    ...result,
  }, null, 4))
}

export function writeNileDeploymentFile(contractName: string, contractAlias: string, result: any) {
  if (fs.existsSync(`./goerli.deployments.txt`)) {
    fs.appendFileSync(`./goerli.deployments.txt`, `\n${result.address}:artifacts/abis/${contractName}.json:${contractAlias}`)
  } else {
    fs.writeFileSync(`./goerli.deployments.txt`, `${result.address}:artifacts/abis/${contractName}.json:${contractAlias}`)
  }
}

export function logDeployment(result: any) {
  console.log(`Deployed at ${result.address}`)
  console.log(`TX: ${result.transaction_hash}`)
}

export function getDeployedAddressInt(contractName: string) {
  const path_base = getPathBase()

  try {
    const file = fs.readFileSync(`${path_base}/${contractName}.json`)

    const parsed = JSON.parse(file.toString())

    return BigInt(parsed.address).toString()
  } catch (error) {
    console.log(`Deployment ${contractName} doesn't exist`)
  }
}

export async function deployContract(contractName: string, contractAlias: string, args: string[]) {
  const network: any = process.env.NETWORK || "georli-alpha"
  const provider = new Provider({ network })

  console.log("Deploying..." + contractName)

  const contract = (await fs.promises.readFile(`./artifacts/${contractName}.json`)).toString()

  const result = await provider.deployContract(contract, args) // no 0x0 here, just int form

  console.log("Waiting for transaction...")
  logDeployment(result)

  try {
    await provider.waitForTx(result.transaction_hash)
    const res = await provider.getTransactionStatus(result.transaction_hash)
    writeDeployment(contractAlias, result)
    writeNileDeploymentFile(contractName, contractAlias, result)
    console.log(res);
  } catch(e){
    console.error("Error Deploying Contract: ", e )
  }

  return result
}

export function getSigner() {
  const path_base = getPathBase()
  try {  
    const file = fs.readFileSync(`${path_base}/OwnerAccount.json`)

    const parsed = JSON.parse(file.toString())

    const privKey = process.env.MINIGAME_ARBITER_PRIVATE_KEY;

    if(privKey == undefined){
      throw new Error("Attempted to call getSigner() with MINIGAME_ARBITER_PRIVATE_KEY being undefined. Set env value in .env or execution environment.")
    }

    const kp = ec.getKeyPair(toBN(privKey, 16))
    const p = new Provider({
      network: "georli-alpha"
    })
    const s = new Signer(p, parsed.address, kp )
    return s;

  } catch( e ) {
    console.error("Signing error: ", e)
  }
}