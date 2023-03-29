mod ERC1155 {
    use zeroable::Zeroable;
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    use starknet::ContractAddress;
    use starknet::ContractAddressZeroable;
    use array::ArrayTrait;

    fn _mint(
        to: ContractAddress,
        id: u256,
        value: u256,
        data: Array<felt252>,
    ) {

    }
}
