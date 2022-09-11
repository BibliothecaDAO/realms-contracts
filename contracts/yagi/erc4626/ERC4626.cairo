# SPDX-License-Identifier: AGPL-3.0-or-later

%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.uint256 import ALL_ONES, Uint256, uint256_check, uint256_eq

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc20.library import ERC20

from contracts.yagi.erc4626.library import ERC4626, ERC4626_asset, Deposit, Withdraw
from contracts.yagi.utils.fixedpointmathlib import mul_div_down, mul_div_up

# @title Generic ERC4626 vault (copy this to build your own).
# @description An ERC4626-style vault implementation.
#              Adapted from the solmate implementation: https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol
# @dev When extending this contract, don't forget to incorporate the ERC20 implementation.
# @author Peteris <github.com/Pet3ris>

#############################################
#                CONSTRUCTOR                #
#############################################

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    asset : felt, name : felt, symbol : felt
):
    ERC4626.initializer(asset, name, symbol)
    return ()
end

#############################################
#                 GETTERS                   #
#############################################

@view
func asset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (asset : felt):
    return ERC4626_asset.read()
end

#############################################
#                 STORAGE                   #
#############################################

#############################################
#                  ACTIONS                  #
#############################################

@external
func deposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    assets : Uint256, receiver : felt
) -> (shares : Uint256):
    alloc_locals
    # Check for rounding error since we round down in previewDeposit.
    let (local shares) = previewDeposit(assets)
    with_attr error_message("ERC4626: cannot deposit 0 shares"):
        let ZERO = Uint256(0, 0)
        let (shares_is_zero) = uint256_eq(shares, ZERO)
        assert shares_is_zero = FALSE
    end

    # Need to transfer before minting or ERC777s could reenter.
    let (asset) = ERC4626_asset.read()
    let (local msg_sender) = get_caller_address()
    let (local this) = get_contract_address()
    IERC20.transferFrom(contract_address=asset, sender=msg_sender, recipient=this, amount=assets)

    ERC20._mint(receiver, shares)

    Deposit.emit(msg_sender, receiver, assets, shares)

    _after_deposit(assets, shares)

    return (shares)
end

@external
func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    shares : Uint256, receiver : felt
) -> (assets : Uint256):
    alloc_locals
    # No need to check for rounding error, previewMint rounds up.
    let (local assets) = previewMint(shares)

    # Need to transfer before minting or ERC777s could reenter.
    let (asset) = ERC4626_asset.read()
    let (local msg_sender) = get_caller_address()
    let (local this) = get_contract_address()
    IERC20.transferFrom(contract_address=asset, sender=msg_sender, recipient=this, amount=assets)

    ERC20._mint(receiver, shares)

    Deposit.emit(msg_sender, receiver, assets, shares)

    _after_deposit(assets, shares)

    return (assets)
end

@external
func withdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    assets : Uint256, receiver : felt, owner : felt
) -> (shares : Uint256):
    alloc_locals
    # No need to check for rounding error, previewWithdraw rounds up.
    let (local shares) = previewWithdraw(assets)

    let (local msg_sender) = get_caller_address()
    ERC4626.ERC20_decrease_allowance_manual(owner, msg_sender, shares)

    _before_withdraw(assets, shares)

    ERC20._burn(owner, shares)

    Withdraw.emit(owner, receiver, assets, shares)

    let (asset) = ERC4626_asset.read()
    IERC20.transfer(contract_address=asset, recipient=receiver, amount=assets)

    return (shares)
end

@external
func redeem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    shares : Uint256, receiver : felt, owner : felt
) -> (assets : Uint256):
    alloc_locals
    let (local msg_sender) = get_caller_address()
    ERC4626.ERC20_decrease_allowance_manual(owner, msg_sender, shares)

    # Check for rounding error since we round down in previewRedeem.
    let (local assets) = previewRedeem(shares)
    let ZERO = Uint256(0, 0)
    let (assets_is_zero) = uint256_eq(assets, ZERO)
    with_attr error_message("ERC4626: cannot redeem 0 assets"):
        assert assets_is_zero = FALSE
    end

    _before_withdraw(assets, shares)

    ERC20._burn(owner, shares)

    Withdraw.emit(owner, receiver, assets, shares)

    let (asset) = ERC4626_asset.read()
    IERC20.transfer(contract_address=asset, recipient=receiver, amount=assets)

    return (assets)
end

#############################################
#               MAX ACTIONS                 #
#############################################

@view
func maxDeposit(to : felt) -> (maxAssets : Uint256):
    let (max_deposit) = ERC4626.max_deposit(to)
    return (max_deposit)
end

@view
func maxMint(to : felt) -> (maxShares : Uint256):
    let (max_mint) = ERC4626.max_mint(to)
    return (max_mint)
end

@view
func maxWithdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    from_ : felt
) -> (maxAssets : Uint256):
    let (balance) = ERC20.balance_of(from_)
    let (max_assets) = convertToAssets(balance)
    return (max_assets)
end

@view
func maxRedeem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    caller : felt
) -> (maxShares : Uint256):
    let (max_redeem) = ERC4626.max_redeem(caller)
    return (max_redeem)
end

#############################################
#             PREVIEW ACTIONS               #
#############################################

@view
func previewDeposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    assets : Uint256
) -> (shares : Uint256):
    return convertToShares(assets)
end

@view
func previewMint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    shares : Uint256
) -> (assets : Uint256):
    alloc_locals
    # Probably not needed
    with_attr error_message("ERC4626: shares is not a valid Uint256"):
        uint256_check(shares)
    end

    let (local supply) = ERC20.total_supply()
    let (local all_assets) = totalAssets()
    let ZERO = Uint256(0, 0)
    let (supply_is_zero) = uint256_eq(supply, ZERO)
    if supply_is_zero == TRUE:
        return (shares)
    end
    let (local z) = mul_div_up(shares, all_assets, supply)
    return (z)
end

@view
func previewWithdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    assets : Uint256
) -> (shares : Uint256):
    alloc_locals
    # Probably not needed
    with_attr error_message("ERC4626: assets is not a valid Uint256"):
        uint256_check(assets)
    end

    let (local supply) = ERC20.total_supply()
    let (local all_assets) = totalAssets()
    let ZERO = Uint256(0, 0)
    let (supply_is_zero) = uint256_eq(supply, ZERO)
    if supply_is_zero == TRUE:
        return (assets)
    end
    let (local z) = mul_div_up(assets, supply, all_assets)
    return (z)
end

@view
func previewRedeem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    shares : Uint256
) -> (assets : Uint256):
    return convertToAssets(shares)
end

#############################################
#             CONVERT ACTIONS               #
#############################################

@view
func convertToShares{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    assets : Uint256
) -> (shares : Uint256):
    alloc_locals
    with_attr error_message("ERC4626: assets is not a valid Uint256"):
        uint256_check(assets)
    end

    let (local supply) = ERC20.total_supply()
    let (local all_assets) = totalAssets()
    let ZERO = Uint256(0, 0)
    let (supply_is_zero) = uint256_eq(supply, ZERO)
    if supply_is_zero == TRUE:
        return (assets)
    end
    let (local z) = mul_div_down(assets, supply, all_assets)
    return (z)
end

@view
func convertToAssets{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    shares : Uint256
) -> (assets : Uint256):
    alloc_locals
    with_attr error_message("ERC4626: shares is not a valid Uint256"):
        uint256_check(shares)
    end

    let (local supply) = ERC20.total_supply()
    let (local all_assets) = totalAssets()
    let ZERO = Uint256(0, 0)
    let (supply_is_zero) = uint256_eq(supply, ZERO)
    if supply_is_zero == TRUE:
        return (shares)
    end
    let (local z) = mul_div_down(shares, all_assets, supply)
    return (z)
end

#############################################
#           HOOKS TO OVERRIDE               #
#############################################

@view
func totalAssets() -> (totalManagedAssets : Uint256):
    return (Uint256(0, 0))
end

func _before_withdraw(assets : Uint256, shares : Uint256):
    return ()
end

func _after_deposit(assets : Uint256, shares : Uint256):
    return ()
end

#############################################
#                  ERC20                    #
#############################################

# Don't forget to add your favorite ERC20 implementation here.
