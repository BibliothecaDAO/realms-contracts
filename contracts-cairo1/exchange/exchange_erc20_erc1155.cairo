// a exchange that can exchange erc20 token to erc1155 token
#[contract]
mod Exchange_ERC20_ERC1155 {
    use zeroable::Zeroable;
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    use starknet::ContractAddress;
    use starknet::ContractAddressZeroable;

    struct Storage {
        currency_address: ContractAddress,
        token_address: ContractAddress,
        currency_reserves: LegacyMap::<u256, u256>,
        lp_reserves: u256,
        lp_fee_thousands: u256,
        royalty_fee_thousands: u256,
        royalty_fee_address: ContractAddress,
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

        assert(currency_amounts.len() == token_ids.len(), 'currency_amounts and token_ids must be same length');
        assert(currency_amounts.len() == token_amounts.len(), 'currency_amounts and token_amounts must be same length');
        let caller = starknet::get_caller_address();
        let contract = starknet::get_contract_address();
        let currency_address_ = currency_address::read();
        let token_address_ = token_address::read();
        let reserve_ = currency_reserves::read(token_id.at(0));
        assert(reserve_ == 0, 'initial liquidity can only be added once');

        IERC20.transfer_from(currency_address_, caller, contract, currency_amounts.at(0));
        
        let mut data_ = ArrayTrait::new();
        data_.append(0);

        IERC1155.safe_transfer_from(token_address_, caller, contract, token_ids.at(0), token_amounts.at(0), data_);

        assert(1000_u256 < currency_amounts.at(0), 'currency_amounts must be greater than 1000');
        currency_reserves::write(token_id.at(0), currency_amounts.at(0));
        lp_reserves::write(token_id.at(0), currency_amounts.at(0));
        ERC1155._mint(caller, token_id.at(0), currency_amounts.at(0), 1, data_);
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