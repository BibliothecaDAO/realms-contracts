# SPDX-License-Identifier: AGPL-3.0-or-later

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.security.safemath import SafeUint256
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from openzeppelin.upgrades.library import Proxy

@storage_var
func splitter_nexus_address() -> (address : felt):
end

@storage_var
func splitter_treasury_address() -> (address : felt):
end

@storage_var
func splitter_asset_address() -> (address : felt):
end

# -----------------------------------
# Initialize & upgrade
# -----------------------------------

# @notice Module initializer
# @param address_of_controller: Controller/arbiter address
# @return proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    proxy_admin : felt, nexus_address : felt, treasury_address : felt, asset_address : felt
):
    Proxy.initializer(proxy_admin)

    splitter_nexus_address.write(nexus_address)
    splitter_treasury_address.write(treasury_address)
    splitter_asset_address.write(asset_address)
    return ()
end

# @notice Set new proxy implementation
# @dev Can only be set by the arbiter
# @param new_implementation: New implementation contract address
@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_implementation : felt
):
    Proxy.assert_only_admin()
    Proxy._set_implementation_hash(new_implementation)
    return ()
end

@external
func split{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (contract_address) = get_contract_address()
    let (nexus_address) = splitter_nexus_address.read()
    let (treasury_address) = splitter_treasury_address.read()
    let (asset_address) = splitter_asset_address.read()

    let (splitter_balance) = IERC20.balanceOf(contract_address=asset_address, account=contract_address)

    # ignore remainder 50/50 for now
    let (split_amount, _) = SafeUint256.div_rem(splitter_balance, Uint256(2, 0))

    # tranfer to nexus
    IERC20.transferFrom(
        contract_address=asset_address, sender=contract_address, recipient=nexus_address, amount=split_amount
    )

    # transfer to treasury
    IERC20.transferFrom(
        contract_address=asset_address, sender=contract_address, recipient=treasury_address, amount=split_amount
    )

    return ()
end

@external
func update{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    nexus_address : felt, treasury_address : felt, asset_address : felt
):
    Proxy.assert_only_admin()
    # call split
    split()
    # update values
    nexus.write(nexus_address)
    treasury.write(treasury_address)
    asset.write(asset_address)

    return ()
end
