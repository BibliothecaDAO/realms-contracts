import { getNetwork, getSigner } from '../../helpers'

async function main() {
  const network = getNetwork()
  const signer = getSigner()

  const res = await signer.invokeFunction({
    contractAddress: process.env[`L2_BRIDGE_ADDRESS_${network.toUpperCase()}`],
    entrypoint: "set_l2_realms_contract_address",
    calldata: [BigInt(process.env[`L2_REALMS_ADDRESS_${network.toUpperCase()}`]).toString()]
  })

  console.log(res)
}

main();