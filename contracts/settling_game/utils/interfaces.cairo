%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_eq
# These are interfaces that can be imported by other contracts for convenience.
# All of the functions in an interface must be @view or @external.

# Interface for the ModuleController.
@contract_interface
namespace IModuleController:
    func get_module_address(module_id : felt) -> (address : felt):
    end

    func get_lords_address() -> (address : felt):
    end

    func get_realms_address() -> (address : felt):
    end

    func get_s_realms_address() -> (address : felt):
    end

    func get_resources_address() -> (address : felt):
    end

    func get_treasury_address() -> (address : felt):
    end

    func has_write_access(address_attempting_to_write : felt):
    end

    func appoint_new_arbiter(new_arbiter : felt):
    end

    func set_address_for_module_id(module_id : felt, module_address : felt):
    end

    func set_write_access(module_id_doing_writing : felt, module_id_being_written_to : felt):
    end

    func set_initial_module_addresses(
            module_01_addr : felt, module_02_addr : felt, module_03_addr : felt,
            module_04_addr : felt):
    end
end
@contract_interface
namespace I01B_Settling:
    func set_time_staked(token_id : Uint256):
    end
end

@contract_interface
namespace I02B_Resources:
    func get_resource_level(token_id : Uint256, resource : felt) -> (level : felt):
    end
    func get_resource_upgrade_cost(token_id : Uint256, resource : felt) -> (level : felt):
    end
    func get_resource_upgrade_ids(resource : felt) -> (level : felt):
    end
    func set_resource_level(token_id : Uint256, resource_id : felt, level : felt) -> ():
    end
end
