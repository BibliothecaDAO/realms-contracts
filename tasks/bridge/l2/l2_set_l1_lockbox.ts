import { getNetwork, getSigner } from '../../helpers'

async function main() {
  const network = getNetwork()
  const signer = getSigner()

  const res = await signer.execute({
    contractAddress: process.env[`L2_BRIDGE_ADDRESS_${network.toUpperCase()}`],
    entrypoint: "set_l1_lockbox_contract_address",
    calldata: [BigInt(process.env[`L1_REALMS_BRIDGE_LOCKBOX_ADDRESS_${network.toUpperCase()}`]).toString()]
  })

  console.log(res)
}

main();