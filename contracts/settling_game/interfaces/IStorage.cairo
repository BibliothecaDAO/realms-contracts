# TODO: Add Contract Title
#   TODO: Add Contract Description
#
# MIT License

%lang starknet

# TODO: delete the whole storage module

@contract_interface
namespace IStorage:
    func get_resource_upgrade_value(resource : felt) -> (level : felt):
    end

    func get_building_cost_ids(building_id : felt) -> (cost : felt):
    end

    func get_building_cost_values(building_id : felt) -> (cost : felt):
    end
end
