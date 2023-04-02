
use realms::exchange::exchange::Exchange_ERC20_ERC1155;
use starknet::contract_address_const;
use starknet::ContractAddress;
use starknet::testing::set_caller_address;
use integer::u256;
use integer::u256_from_felt252;
use array::ArrayTrait;

//
// Constants
//

const NAME: felt252 = 111;
const SYMBOL: felt252 = 222;

fn MAX_U256() -> u256 {
    u256 {
        low: 0xffffffffffffffffffffffffffffffff_u128, high: 0xffffffffffffffffffffffffffffffff_u128
    }
}

//
// Helper functions
//

fn setup() -> (ContractAddress, u256) {

    let initial_supply: u256 = u256_from_felt252(2000);
    let account: ContractAddress = contract_address_const::<1>();
    // Set account as default caller
    set_caller_address(account);

    // ERC20::constructor(NAME, SYMBOL, initial_supply, account);
    Exchange_ERC20_ERC1155::initializer(
        NAME,
        contract_address_const::<2>(), // TODO remove
        contract_address_const::<3>(), // TODO remove
        u256_from_felt252(1),
        u256_from_felt252(1),
        contract_address_const::<3>(), // TODO remove
        account,
    );
    (account, initial_supply)
}

fn set_caller_as_zero() {
    set_caller_address(contract_address_const::<0>());
}

//
// Tests
//


#[test]
#[available_gas(2000000)]
fn test_Initialize() {
    setup();


}