import { Provider, ec, Signer } from 'starknet'
import fs from 'fs'
import { toBN } from 'starknet/dist/utils/number'

export const GOERLI_DEPLOYMENT_PATH_BASE = "./deployments/starknet"

function getPathBase() {
  if (process.env.NETWORK && process.env.NETWORK !== "goerli") {
    return `${GOERLI_DEPLOYMENT_PATH_BASE}-${process.env.NETWORK}`
  }

  return `${GOERLI_DEPLOYMENT_PATH_BASE}-goerli`
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

  console.log("Deploying...")

  const contract = (await fs.promises.readFile(`./artifacts/${contractName}.json`)).toString()

  const result = await provider.deployContract(contract, args) // no 0x0 here, just int form

  writeDeployment(contractAlias, result)
  writeNileDeploymentFile(contractName, contractAlias, result)
  logDeployment(result)

  return result
}

export function getSigner() {
  const path_base = getPathBase()
  try {  
    const file = fs.readFileSync(`${path_base}/OwnerAccount.json`)

    const parsed = JSON.parse(file.toString())

    const kp = ec.getKeyPair(toBN(parsed.private_key, 16))
    const p = new Provider({
      network: "georli-alpha"
    })
    const s = new Signer(p, parsed.address, kp )
    return s;

  } catch( e ) {
    console.error("Signing error: ", e)
  }
}