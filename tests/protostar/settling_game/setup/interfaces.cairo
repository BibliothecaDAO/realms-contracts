
%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace Controller {
    func initializer(arbiter: felt, proxy_admin: felt) {
    }
}

@contract_interface
namespace Module {
    func initializer(controller_address: felt, proxy_admin: felt) {
    }
}

@contract_interface
namespace Crypts {
    func initializer(name: felt, symbol: felt, proxy_admin: felt) {
    }
}

@contract_interface
namespace Lords {
    func initializer(
        name: felt,
        symbol: felt,
        decimals: felt,
        initial_supply: Uint256,
        recipient: felt,
        proxy_admin: felt,
    ) {
    }
}

@contract_interface
namespace Realms {
    func initializer(name: felt, symbol: felt, proxy_admin: felt) {
    }
    func mint(to: felt, amount: Uint256) {
    }
    func approve(to: felt, tokenId: Uint256) {
    }
    func set_realm_data(tokenId: Uint256, realm_name: felt, realm_data: felt) {
    }
    func ownerOf(tokenId: Uint256) -> (owner: felt) {
    }
}

@contract_interface
namespace ResourcesToken {
    func initializer(uri: felt, proxy_admin: felt, controller_address: felt) {
    }
    func balanceOfBatch(accounts_len: felt, accounts: felt*, ids_len: felt, ids: Uint256*) -> (
        balances_len: felt, balances: Uint256*
    ) {
    }
}

@contract_interface
namespace S_Crypts {
    func initializer(name: felt, symbol: felt, proxy_admin: felt) {
    }
}

@contract_interface
namespace S_Realms {
    func initializer(name: felt, symbol: felt, proxy_admin: felt, controller_address: felt) {
    }
}

@contract_interface
namespace Relics {
    func initializer(address_of_controller: felt, proxy_admin: felt) {
    }

    func set_relic_holder(winner_token_id: Uint256, loser_token_id: Uint256) {
    }

    func return_relics(realm_token_id: Uint256) {
    }

    func get_current_relic_holder(relic_id: Uint256) -> (token_id: Uint256) {
    }
}
