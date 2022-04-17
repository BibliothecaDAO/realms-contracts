import { Provider, ec } from "starknet";
import fs from "fs";
import { getPathBase } from "./helpers";

const DEPLOYMENT_PATH_BASE = getPathBase();

export default async function deployAccount() {
  if (!fs.existsSync(DEPLOYMENT_PATH_BASE)) {
    await fs.promises.mkdir(DEPLOYMENT_PATH_BASE, { recursive: true })
  }

  if (fs.existsSync(`${DEPLOYMENT_PATH_BASE}/OwnerAccount.json`)) {
    console.log("Deployment already exists")
    return
  }

  const keyPair = ec.genKeyPair()
  const starkKey = ec.getStarkKey(keyPair)

  const network = process.env.NETWORK || "georli-alpha"

  const provider = new Provider({ network: network as any })

  const contract = (await fs.promises.readFile("./artifacts/Account.json")).toString()

  const result = await provider.deployContract({
    contract,
    constructorCalldata: [
      starkKey
    ]
  })

  fs.writeFileSync(`${DEPLOYMENT_PATH_BASE}/OwnerAccount.json`, JSON.stringify({
    ...result,
    public_key: starkKey
  }))

  console.log(`Deployed at ${result.address}`)
  console.log(`TX: ${result.transaction_hash}`)
  console.log(`Public Key ${starkKey}`)
  console.log(`Private Key ${keyPair.getPrivate()}`)
  console.log("waiting for transaction...")
  try {
    await provider.waitForTransaction(result.transaction_hash)
    const res = await provider.getTransactionStatus(result.transaction_hash)
    console.log(res);
  } catch (e) {
    console.error("Error deploying account: ", e)
  }

}

deployAccount()