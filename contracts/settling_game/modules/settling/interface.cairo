%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace ISettling:
    func settle(token_id : Uint256) -> (success : felt):
    end
    func unsettle(token_id : Uint256) -> (success : felt):
    end
    func set_time_staked(token_id : Uint256, time_left : felt):
    end
    func set_time_vault_staked(token_id : Uint256, time_left : felt):
    end
    func get_time_staked(token_id : Uint256) -> (time : felt):
    end
    func get_time_vault_staked(token_id : Uint256) -> (time : felt):
    end
    func get_total_realms_settled() -> (amount : felt):
    end
end
