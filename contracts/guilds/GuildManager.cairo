%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import deploy, get_caller_address
from contracts.guilds.lib.math_utils import array_product

from starkware.cairo.common.bool import TRUE, FALSE

#
# Constants
#

const INITIALIZE_SELECTOR = 215307247182100370520050591091822763712463273430149262739280891880522753123

#
# Structs
#

struct ProxyDeployData:
    member implementation : felt
    member selector : felt
    member calldata_len : felt
    member calldata : felt*
end

#
# Storage variables
#

@storage_var
func salt() -> (value : felt):
end

@storage_var
func guild_proxy_class_hash() -> (value : felt):
end

@storage_var
func guild_class_hash() -> (value : felt):
end

@storage_var
func guild_contract_count() -> (res : felt):
end

@storage_var
func guild_contracts(index : felt) -> (value : felt):
end

#
# Events
#

@event
func guild_contract_deployed(name : felt, master : felt, contract_address : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    guild_proxy_class_hash_ : felt, guild_class_hash_ : felt
):
    guild_proxy_class_hash.write(value=guild_proxy_class_hash_)
    guild_class_hash.write(value=guild_class_hash_)
    return ()
end

@external
func deploy_guild_proxy_contract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name : felt, guild_certificate : felt
):
    let (current_salt) = salt.read()
    let (proxy_class_hash) = guild_proxy_class_hash.read()
    let (class_hash) = guild_class_hash.read()
    let (caller_address) = get_caller_address()
    let (calldata : felt*) = alloc()
    assert calldata[0] = class_hash
    assert calldata[1] = INITIALIZE_SELECTOR
    assert calldata[2] = 3
    assert calldata[3] = name
    assert calldata[4] = caller_address
    assert calldata[5] = guild_certificate
    let (contract_address) = deploy(
        class_hash=proxy_class_hash,
        contract_address_salt=current_salt,
        constructor_calldata_size=6,
        constructor_calldata=calldata,
    )
    salt.write(value=current_salt + 1)

    guild_contract_deployed.emit(
        name=name, master=caller_address, contract_address=contract_address
    )

    let (contract_count) = guild_contract_count.read()
    guild_contracts.write(contract_count, contract_address)
    guild_contract_count.write(contract_count + 1)

    return ()
end

@external
func check_valid_contract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
) -> (value : felt):
    alloc_locals
    let (checks : felt*) = alloc()
    let (guilds_len) = guild_contract_count.read()

    _check_valid_contract(guilds_index=0, guilds_len=guilds_len, address=address, checks=checks)

    let (check_product) = array_product(guilds_len, checks)

    with_attr error_message("Guild Manager: Contract is not valid"):
        assert check_product = 0
    end
    return (value=TRUE)
end

func _check_valid_contract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    guilds_index : felt, guilds_len : felt, address : felt, checks : felt*
):
    if guilds_index == guilds_len:
        return ()
    end

    let (guild_contract) = guild_contracts.read(guilds_index)
    let check = address - guild_contract
    assert checks[guilds_index] = check

    _check_valid_contract(
        guilds_index=guilds_index + 1, guilds_len=guilds_len, address=address, checks=checks
    )
    return ()
end

@view
func get_guild_contracts{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    guilds_len : felt, guilds : felt*
):
    alloc_locals
    let (guilds : felt*) = alloc()
    let (guilds_len) = guild_contract_count.read()

    _get_guild_contracts(guilds_index=0, guilds_len=guilds_len, guilds=guilds)
    return (guilds_len, guilds)
end

func _get_guild_contracts{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    guilds_index : felt, guilds_len : felt, guilds : felt*
):
    if guilds_index == guilds_len:
        return ()
    end

    let (guild_contract) = guild_contracts.read(guilds_index)
    assert guilds[guilds_index] = guild_contract

    _get_guild_contracts(guilds_index=guilds_index + 1, guilds_len=guilds_len, guilds=guilds)
    return ()
end
