%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace ITravel:
    func assert_traveller_is_at_location(
        traveller_contract_id : felt,
        traveller_token_id : Uint256,
        destination_contract_id : felt,
        destination_token_id : Uint256,
    ):
    end
end
