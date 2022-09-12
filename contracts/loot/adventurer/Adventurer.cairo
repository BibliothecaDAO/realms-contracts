# SPDX-License-Identifier: MIT
# OpenZeppelin Contracts for Cairo v0.3.2 (token/erc721/enumerable/presets/ERC721EnumerableMintableBurnable.cairo)

%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.math import unsigned_div_rem
from starkware.starknet.common.syscalls import get_block_timestamp

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.upgrades.library import Proxy

from contracts.loot.adventurer.library import AdventurerLib
from contracts.loot.constants.adventurer import Adventurer, AdventurerState, PackedAdventurerState
from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro

# const MINT_COST = 5000000000000000000

# -----------------------------------
# Storage
# -----------------------------------

@storage_var
func xoroshiro_address() -> (address : felt):
end

@storage_var
func item_address() -> (address : felt):
end

@storage_var
func bag_address() -> (address : felt):
end

@storage_var
func lords_address() -> (address : felt):
end

# -----------------------------------
# Initialize & upgrade
# -----------------------------------

# @notice Module initializer
# @param address_of_controller: Controller/arbiter address
# @return proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name : felt,
    symbol : felt,
    proxy_admin : felt,
    xoroshiro_address_ : felt,
    item_address_ : felt,
    bag_address_ : felt,
    lords_address_ : felt,
):
    ERC721.initializer(name, symbol)
    ERC721Enumerable.initializer()
    Proxy.initializer(proxy_admin)

    # contracts
    xoroshiro_address.write(xoroshiro_address_)
    item_address.write(item_address_)
    bag_address.write(bag_address_)
    lords_address.write(lords_address_)
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

#
# Getters
#

@view
func totalSupply{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    totalSupply : Uint256
):
    let (totalSupply : Uint256) = ERC721Enumerable.total_supply()
    return (totalSupply)
end

@view
func tokenByIndex{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    index : Uint256
) -> (tokenId : Uint256):
    let (tokenId : Uint256) = ERC721Enumerable.token_by_index(index)
    return (tokenId)
end

@view
func tokenOfOwnerByIndex{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    owner : felt, index : Uint256
) -> (tokenId : Uint256):
    let (tokenId : Uint256) = ERC721Enumerable.token_of_owner_by_index(owner, index)
    return (tokenId)
end

@view
func supportsInterface{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    interfaceId : felt
) -> (success : felt):
    let (success) = ERC165.supports_interface(interfaceId)
    return (success)
end

@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt):
    let (name) = ERC721.name()
    return (name)
end

@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (symbol : felt):
    let (symbol) = ERC721.symbol()
    return (symbol)
end

@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt) -> (
    balance : Uint256
):
    let (balance : Uint256) = ERC721.balance_of(owner)
    return (balance)
end

@view
func ownerOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (owner : felt):
    let (owner : felt) = ERC721.owner_of(tokenId)
    return (owner)
end

@view
func getApproved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (approved : felt):
    let (approved : felt) = ERC721.get_approved(tokenId)
    return (approved)
end

@view
func isApprovedForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    owner : felt, operator : felt
) -> (isApproved : felt):
    let (isApproved : felt) = ERC721.is_approved_for_all(owner, operator)
    return (isApproved)
end

@view
func tokenURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (tokenURI : felt):
    let (tokenURI : felt) = ERC721.token_uri(tokenId)
    return (tokenURI)
end

@view
func owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (owner : felt):
    let (owner : felt) = Ownable.owner()
    return (owner)
end

#
# Externals
#

@external
func approve{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    to : felt, tokenId : Uint256
):
    ERC721.approve(to, tokenId)
    return ()
end

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    operator : felt, approved : felt
):
    ERC721.set_approval_for_all(operator, approved)
    return ()
end

# @external
# func transferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
#     from_ : felt, to : felt, tokenId : Uint256
# ):
#     ERC721Enumerable.transfer_from(from_, to, tokenId)
#     return ()
# end

# @external
# func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
#     from_ : felt, to : felt, tokenId : Uint256, data_len : felt, data : felt*
# ):
#     ERC721Enumerable.safe_transfer_from(from_, to, tokenId, data_len, data)
#     return ()
# end

@external
func burn{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(tokenId : Uint256):
    ERC721.assert_only_token_owner(tokenId)
    ERC721Enumerable._burn(tokenId)
    return ()
end

@external
func setTokenURI{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    tokenId : Uint256, tokenURI : felt
):
    Ownable.assert_only_owner()
    ERC721._set_token_uri(tokenId, tokenURI)
    return ()
end

@external
func transferOwnership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    newOwner : felt
):
    Ownable.transfer_ownership(newOwner)
    return ()
end

@external
func renounceOwnership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    Ownable.renounce_ownership()
    return ()
end

# ------------ADVENTURERS

@storage_var
func adventurer(tokenId : Uint256) -> (adventurer : PackedAdventurerState):
end

@external
func mint{
    pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(to : felt, race : felt, home_realm : felt, name : felt, order : felt):
    alloc_locals

    # birth
    let (birth_time) = get_block_timestamp()
    let (new_adventurer : AdventurerState) = AdventurerLib.birth(
        race, home_realm, name, birth_time, order
    )

    # pack
    let (packed_new_adventurer : PackedAdventurerState) = AdventurerLib.pack(new_adventurer)

    # get current ID and add 1
    let (current_id : Uint256) = totalSupply()
    let (next_adventurer_id, _) = uint256_add(current_id, Uint256(1, 0))

    # store
    adventurer.write(next_adventurer_id, packed_new_adventurer)

    ERC721Enumerable._mint(to, next_adventurer_id)

    return ()
end

@external
func set_xoroshiro{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    xoroshiro : felt
):
    Proxy.assert_only_admin()
    xoroshiro_address.write(xoroshiro)
    return ()
end

@view
func get_xoroshiro{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    address : felt
):
    return xoroshiro_address.read()
end

@external
func set_lords{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(lords : felt):
    Proxy.assert_only_admin()
    lords_address.write(lords)
    return ()
end

@view
func get_lords{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    address : felt
):
    return lords_address.read()
end

@external
func getAdventurerById{
    pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(tokenId : Uint256) -> (adventurer : AdventurerState):
    alloc_locals

    let (packed_adventurer) = adventurer.read(tokenId)

    # unpack
    let (unpacked_adventurer : AdventurerState) = AdventurerLib.unpack(packed_adventurer)

    return (unpacked_adventurer)
end
