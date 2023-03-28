// a exchange that can exchange erc20 token to erc1155 token
#[contract]
mod Exchange_ERC20_ERC1155 {
    use zeroable::Zeroable;
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    use starknet::ContractAddress;
    use starknet::ContractAddressZeroable;
    use array::ArrayTrait;
    use exchange::ERC1155Contract;

    struct Storage {
        currency_address: ContractAddress,
        token_address: ContractAddress,
        currency_reserves: LegacyMap::<u256, u256>,
        lp_reserves: LegacyMap::<u256, u256>,
        lp_fee_thousands: u256,
        royalty_fee_thousands: u256,
        royalty_fee_address: ContractAddress,
    }

    //TODO: Remove when u256 literals are supported.
    fn as_u256(high: u128, low: u128) -> u256 {
        u256 { low, high }
    }

    #[abi]
    trait IERC20 {
        fn transfer_from(
            from: ContractAddress,
            to: ContractAddress,
            value: u256,
        );
    }

    #[abi]
    trait IERC1155 {
        fn safe_transfer_from(
            from: ContractAddress,
            to: ContractAddress,
            id: u256,
            value: u256,
            data: Array<u256>,
        );
    }

//##############
// CONSTRUCTOR #
//##############

    #[external]
    fn initializer(
        uri: felt252,
        currency_address_: ContractAddress,
        token_address_: ContractAddress,
        lp_fee_thousands_: u256,
        royalty_fee_thousands_: u256,
        royalty_fee_address_: ContractAddress,
        proxy_admin: ContractAddress,
    ) {
        currency_address::write(currency_address_);
        token_address::write(token_address_);
        lp_fee_thousands::write(lp_fee_thousands_);
        // set_royalty_info(royalty_fee_thousands_, royalty_fee_address_);
        //TODO proxy logic
        //TODO ownable initializer
        //TODO ERC1155 initializer
        //TODO ERC165 interface register
    }

    #[external]
    fn upgrade() {

    }

//#####
// LP #
//#####
    #[external]
    fn initial_liquidity(
        currency_amounts: Array<u256>,
        token_ids: Array<u256>,
        token_amounts: Array<u256>,
    ) {

        assert(currency_amounts.len() == token_ids.len(), 'not same length 1');
        assert(currency_amounts.len() == token_amounts.len(), 'not same length 2');
        let caller = starknet::get_caller_address();
        let contract = starknet::get_contract_address();
        let currency_address_ = currency_address::read();
        let token_address_ = token_address::read();
        let reserve_ = currency_reserves::read(*token_ids.at(0_usize));
        assert(reserve_ == as_u256(0_u128, 0_u128), 'reserve must be 0');

        IERC20Dispatcher { contract_address: currency_address_ }.transfer_from(caller, contract, *currency_amounts.at(0_usize));
        
        let mut data_ = ArrayTrait::new();
        data_.append(as_u256(0_u128, 0_u128));

        IERC1155Dispatcher { contract_address: token_address_ }.safe_transfer_from(caller, contract, *token_ids.at(0_usize), *token_amounts.at(0_usize), data_);

        assert(as_u256(1000_u128, 0_u128) < *currency_amounts.at(0_usize), 'amount too small');
        currency_reserves::write(*token_ids.at(0_usize), *currency_amounts.at(0_usize));
        lp_reserves::write(*token_ids.at(0_usize), *currency_amounts.at(0_usize));
        //TODO: remove when openzeppelin ERC1155 library is supported
        ERC1155._mint(caller, *token_ids.at(0_usize), *currency_amounts.at(0_usize), 1, data_);
        //TODO emit event
        
        currency_amounts.pop_front();
        token_ids.pop_front();
        token_amounts.pop_front();

        initial_liquidity(
            currency_amounts,
            token_ids,
            token_amounts,
        )
    }

    #[external]
    fn add_liquidity() {

    }

    fn add_liquidity_loop() {

    }

    #[external]
    fn remove_liquidity() {

    }

    fn remove_liquidity_loop() {

    }

//#############
// BUY TOKENS #
//#############
    #[external]
    fn buy_tokens() {

    }

    fn buy_tokens_loop() {

    }

//##############
// SELL TOKENS #
//##############
    #[external]
    fn sell_tokens() {

    }

    fn sell_tokens_loop() {

    }

//################
// PRICING CALCS #
//################

    #[view]
    fn get_royalty_for_price() {

    }

    #[view]
    fn get_buy_price_with_royalty() {

    }

    #[view]
    fn get_sell_price_with_royalty() {

    }

//############
// RECEIVERS #
//############

    //TODO: the receiver name is not correct
    #[external]
    fn onERC1155Received() {

    }

//##########
// Getters #
//##########

    #[view]
    fn get_currency_address() {

    }

    #[view]
    fn get_token_address() {

    }

    #[view]
    fn get_currency_reserves() {

    }

    #[view]
    fn get_lp_fee_thousands() {

    }

    #[view]
    fn get_all_sell_price() {

    }

    fn get_all_sell_price_loop() {

    }

    #[view]
    fn get_all_buy_price() {

    }

    fn get_all_buy_price_loop() {

    }
    
    #[view]
    fn get_all_rates() {

    }

    fn get_all_rates_loop() {

    }

    #[view]
    fn get_all_currency_reserves() {

    }

    fn get_all_currency_reserves_loop() {

    }

//########################
// ERC1155 for LP tokens #
//########################

    #[view]
    fn supportsInterface() {

    }

    #[view]
    fn balanceOf() {

    }

    #[view]
    fn balanceOfBatch() {

    }

    #[view]
    fn isApprovedForAll() {

    }

//
// Externals
//
    #[external]
    fn setApprovalForAll() {

    }

    #[external]
    fn safeTransferFrom() {

    }

    #[external]
    fn safeBatchTransferFrom() {

    }

//########
// ADMIN #
//########
    #[external]
    fn set_royalty_info() {

    }

    #[external]
    fn set_lp_info() {

    }

    #[view]
    fn get_owed_currency_tokens() {

    }

    fn get_owed_currency_tokens_loop() {

    }



}