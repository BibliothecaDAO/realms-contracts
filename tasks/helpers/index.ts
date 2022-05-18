import { Provider, ec, Account, encode } from 'starknet'
import fs from 'fs'
import { BigNumberish, toBN } from 'starknet/dist/utils/number'
import { config as dotenvConfig } from "dotenv";
import { resolve } from "path";

dotenvConfig({ path: resolve(__dirname, "../../.env") });

// Deployments for different applications can provide a separate base
// with an environment variable.
export const DEPLOYMENT_PATH_BASE = process.env.DEPLOY_BASE || "./deployments/starknet";

const network: any = process.env.NETWORK || "georli-alpha"
export const provider = new Provider(network === "local" ? { baseUrl: "http://127.0.0.1:5000/" } : { network })

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

type AccountShape = {
  transaction_hash: string;
  address: string;
  stark_key_hex: string;
}

export function getOwnerAccount(): AccountShape {
  const path_base = getPathBase()
  const accountName = process.env.ACCOUNT_NAME || `OwnerAccount`;

  console.log("Using account", accountName)

  try {
    const file = fs.readFileSync(`${path_base}/${accountName}.json`)

    const parsed = JSON.parse(file.toString())
    return parsed;
  } catch (error) {
    console.log(`No STARKNET_ACCOUNT_ADDRESS env variable nor "${path_base}/${accountName}.json" provided.`)
    throw error
  }
}

export function getOwnerAccountInt(): string {

  if (process.env.STARKNET_ACCOUNT_ADDRESS) {
    return BigInt(process.env.STARKNET_ACCOUNT_ADDRESS).toString()
  }

  return BigInt(getOwnerAccount().address).toString()
}

export function writeDeployment(contractAlias: string, result: any) {
  const path_base = getPathBase()

  fs.writeFileSync(`${path_base}/${contractAlias}.json`, JSON.stringify({
    ...result,
  }, null, 4))
}

export function writeNileDeploymentFile(contractName: string, contractAlias: string, result: any) {

  const deploymentFilename = `./${getPathBase()}/${network}.deployments.txt`;

  if (fs.existsSync(deploymentFilename)) {
    fs.appendFileSync(deploymentFilename, `\n${result.address}:artifacts/abis/${contractName}.json:${contractAlias}`)
  } else {
    fs.writeFileSync(deploymentFilename, `${result.address}:artifacts/abis/${contractName}.json:${contractAlias}`)
  }
}

export function logDeployment(result: any) {
  console.log(`Deployed at ${result.address}`)
  console.log(`TX: https://goerli.voyager.online/tx/${result.transaction_hash}`)
}

export function getDeployedAddressInt(contractName: string): string {
  return toBN(getDeployment(contractName).address).toString()
}

export function getDeployment(contractName: string): { address: string } {
  const path_base = getPathBase()

  try {
    const file = fs.readFileSync(`${path_base}/${contractName}.json`)

    const parsed = JSON.parse(file.toString())

    return parsed;
  } catch (error) {
    console.log(`Deployment ${contractName} doesn't exist`)
  }
}

export async function deployContract(contractName: string, contractAlias: string, args: BigNumberish[]) {

  console.log("Deploying..." + contractName)

  const contract = (await fs.promises.readFile(`./artifacts/${contractName}.json`)).toString()

  const signer = getSigner()

  const result = await signer.deployContract({
    contract,
    constructorCalldata: args
  })

  console.log("Waiting for transaction...")
  logDeployment(result)

  try {
    await provider.waitForTransaction(result.transaction_hash)
    const res = await provider.getTransactionStatus(result.transaction_hash)
    writeDeployment(contractAlias, result)
    writeNileDeploymentFile(contractName, contractAlias, result)
    console.log(res);
  } catch (e) {
    console.error("Error Deploying Contract: ", e)
  }

  return result
}

export function getNetwork() {
  if (process.env.NETWORK) { return process.env.NETWORK } // TODO: improve for mainnet

  return "goerli"
}

export function getSigner() {
  try {
    const accountAddress = getOwnerAccount().address;
    const privKey = process.env.STARKNET_PRIVATE_KEY;

    if (accountAddress == undefined || accountAddress == "") {
      throw new Error("Attempted to call getSigner() with STARKNET_ACCOUNT_ADDRESS being undefined. Set env value in .env or execution environment.")
    }

    if (privKey == undefined || privKey == "") {
      throw new Error("Attempted to call getSigner() with STARKNET_PRIVATE_KEY being undefined. Set env value in .env or execution environment.")
    }
 
    const kp = ec.getKeyPair( encode.addHexPrefix(privKey))
    const s = new Account(provider, accountAddress, kp)
    console.log(s)
    return s;

  } catch (e) {
    console.error("Signing error: ", e)
  }
}

export async function sendtx(data: any) {
  try {
    const res = await getSigner().execute(data, undefined, {
            maxFee: 0
        })

    console.log(res)

    console.log(`Waiting for Tx to be Accepted on Starknet - Transfer...`);
    await provider.waitForTransaction(res.transaction_hash);

  } catch (e) {
    console.log(e)
  }
}

export function getVersionSuffix() {
  const now = new Date()
  return `${now.getFullYear()}${now.getMonth() + 1}${now.getDate()}`
}