%lang starknet

from starkware.cairo.common.uint256 import Uint256

#
# Structs
#

struct Token:
    member token_standard: felt
    member token: felt
    member token_id: Uint256
    member amount: Uint256
end


@contract_interface
namespace IGuildCertificate:

    func balanceOf(
            owner: felt
        ) -> (
            balance: Uint256
        ):
    end

    func get_certificate_id(
            owner: felt,
            guild: felt
        ) -> (
            certificate_id: Uint256
        ):
    end

    func get_role(
        certificate_id: Uint256
    ) -> (
        role: felt
    ):
    end

    func get_tokens(
        certificate_id: Uint256
    ) -> (
        tokens_len: felt,
        tokens: Token*
    ):
    end

    func get_token_amount(
        certificate_id: Uint256,
        token_standard: felt,
        token: felt,
        token_id: Uint256
    ) -> (
        amount: Uint256
    ):
    end

    func check_token_exists(
            certificate_id: Uint256,
            token_standard: felt,
            token: felt,
            token_id: Uint256
        ) -> (
            bool: felt
        ):
    end

    func check_tokens_exist(
            certificate_id: Uint256
        ) -> (
            bool: felt
        ):
    end

    func mint(
            to: felt,
            guild: felt,
            role: felt
        ):
    end

    func update_role(
            certificate_id: Uint256,
            role: felt
        ):
    end

    func burn(
            account: felt,
            guild: felt
        ):
    end

    func guild_burn(
            account: felt,
            guild: felt
        ):
    end

    func add_token_data(
            certificate_id: Uint256,
            token_standard: felt,
            token: felt,
            token_id: Uint256,
            amount: Uint256
        ):
    end

    func change_token_data(
            certificate_id: Uint256,
            token_standard: felt,
            token: felt,
            token_id: Uint256,
            new_amount: Uint256
        ):
    end
end