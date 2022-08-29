# SPDX-License-Identifier: AGPL-3.0-or-later

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.security.safemath import SafeUint256
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from openzeppelin.upgrades.library import Proxy

@storage_var
func nexus() -> (address : felt):
end

@storage_var
func treasury() -> (address : felt):
end

@storage_var
func asset() -> (address : felt):
end

# -----------------------------------
# Initialize & upgrade
# -----------------------------------

# @notice Module initializer
# @param address_of_controller: Controller/arbiter address
# @return proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    proxy_admin : felt, nexus_ : felt, treasury_ : felt, asset_ : felt
):
    Proxy.initializer(proxy_admin)

    nexus.write(nexus_)
    treasury.write(treasury_)
    asset.write(asset_)
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

    let (nexus_) = nexus.read()
    let (treasury_) = treasury.read()
    let (asset_) = asset.read()

    let (splitter_balance) = IERC20.balanceOf(contract_address=asset_, account=contract_address)

    # ignore remainder 50/50 for now
    let (split_amount, _) = SafeUint256.div_rem(splitter_balance, Uint256(2, 0))

    # tranfer to nexus
    IERC20.transferFrom(
        contract_address=asset_, sender=contract_address, recipient=nexus_, amount=split_amount
    )

    # transfer to treasury
    IERC20.transferFrom(
        contract_address=asset_, sender=contract_address, recipient=treasury_, amount=split_amount
    )

    return ()
end

@external
func update{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    nexus_ : felt, treasury_ : felt, asset_ : felt
):
    Proxy.assert_only_admin()
    # call split
    split()
    # update values
    nexus.write(nexus_)
    treasury.write(treasury_)
    asset.write(asset_)
    return ()
end
