
import Lords from './deploy_lords'
import Resources  from './deploy_resources'
import Realms  from './deploy_realms'
import S_Realms  from './deploy_s_realms'

async function main() {
    await Lords
    await Resources
    await Realms
    await S_Realms
}

export default main()