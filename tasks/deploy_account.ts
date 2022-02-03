import { Provider, ec, encode, number } from 'starknet'
import fs from 'fs'

const DEPLOYMENT_PATH_BASE = "./tasks/deployments/starknet-goerli"

async function main() {
  if (!fs.existsSync(DEPLOYMENT_PATH_BASE)) {
    await fs.promises.mkdir(DEPLOYMENT_PATH_BASE, { recursive: true })
  }

  if (fs.existsSync(`${DEPLOYMENT_PATH_BASE}/OwnerAccount.json`)) {
    console.log("Deployment already exists")
    return
  }

  const keyPair = ec.genKeyPair()
  const starkKey = ec.getStarkKey(keyPair)
  const starkKeyInt = number.toBN(encode.removeHexPrefix(starkKey), 16)

  const network = process.env.NETWORK || "georli-alpha"
  
  const provider = new Provider({ network: network as any })

  const contract = (await fs.promises.readFile("./artifacts/Account.json")).toString()

  const result = await provider.deployContract(contract, [starkKeyInt.toString()]) // no 0x0 here, just int form

  fs.writeFileSync(`${DEPLOYMENT_PATH_BASE}/OwnerAccount.json`, JSON.stringify({
    ...result,
    stark_key_hex: starkKeyInt,
    private_key: keyPair.getPrivate("hex"),
  }))

  console.log(`Deployed at ${result.address}`)
  console.log(`TX: ${result.transaction_hash}`)
  console.log(`Stark Key ${starkKeyInt}`)
  console.log(`Private Key ${keyPair.getPrivate("hex")}`)
}

main()