
import Settling  from './01_deploy_settling'
import Resources  from './02_deploy_resources'
import Buildings  from './03_deploy_buildings'
import Calculator  from './04_deploy_calculator'

async function main() {
 await Settling
 await Resources
 await Buildings
 await Calculator
}

export default main()