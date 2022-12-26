%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IUtils {
    func __callback__(realm_id: Uint256) {
    }
}
