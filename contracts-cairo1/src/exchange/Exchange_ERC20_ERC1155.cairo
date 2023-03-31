// a exchange that can exchange erc20 token to erc1155 token
#[contract]
mod Exchange_ERC20_ERC1155 {
    use zeroable::Zeroable;
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    use starknet::ContractAddress;
    use starknet::ContractAddressZeroable;
    use array::ArrayTrait;
    use array::SpanTrait;
    use dict::Felt252DictTrait;
    use option::OptionTrait;
    use option::OptionTraitImpl;
    use core::ec;
    use core::traits::TryInto;
    use core::traits::Into;
    use box::BoxTrait;
    use clone::Clone;
    use array::ArrayTCloneImpl;
    use realms::exchange::ERC1155::ERC1155;
    use realms::utils::helper::check_gas;
    use integer::u256_overflow_mul;
    use integer::u256_overflowing_add;

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
            data: Array<felt252>,
        );

        fn balance_of(
            account: ContractAddress,
            id: u256,
        ) -> u256;
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
        mut currency_amounts: Array<u256>,
        mut token_ids: Array<u256>,
        mut token_amounts: Array<u256>,
    ) {
        check_gas();

        if (currency_amounts.len() == 0_usize) {
            return ();
        }

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
        data_.append(0);

        IERC1155Dispatcher { contract_address: token_address_ }.safe_transfer_from(caller, contract, *token_ids.at(0_usize), *token_amounts.at(0_usize), (@data_).clone());

        assert(as_u256(1000_u128, 0_u128) < *currency_amounts.at(0_usize), 'amount too small');
        currency_reserves::write(*token_ids.at(0_usize), *currency_amounts.at(0_usize));
        lp_reserves::write(*token_ids.at(0_usize), *currency_amounts.at(0_usize));
        //TODO: remove when openzeppelin ERC1155 library is supported
        ERC1155::_mint(caller, *token_ids.at(0_usize), *currency_amounts.at(0_usize), (@data_).clone());
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
    fn add_liquidity(
        mut max_currency_amounts: Array<u256>,
        mut token_ids: Array<u256>,
        mut token_amounts: Array<u256>,
        deadline: felt252,
    ) {
        assert(max_currency_amounts.len() == token_ids.len(), 'not same length 1');
        assert(max_currency_amounts.len() == token_amounts.len(), 'not same length 2');
        let info = starknet::get_block_info().unbox();
        assert(info.block_timestamp < deadline.try_into().unwrap(), 'deadline passed');
        return add_liquidity_loop(
            max_currency_amounts,
            token_ids,
            token_amounts,
        );
        
    }

    fn add_liquidity_loop(
        mut max_currency_amounts: Array<u256>,
        mut token_ids: Array<u256>,
        mut token_amounts: Array<u256>,
    ) {
        check_gas();
        if (max_currency_amounts.len() == 0_usize) {
            return ();
        }
        let caller = starknet::get_caller_address();
        let contract = starknet::get_contract_address();
        let currency_address_ = currency_address::read();
        let token_address_ = token_address::read();

        let currency_reserve_ = currency_reserves::read(*token_ids.at(0_usize));
        let lp_reserve_ = lp_reserves::read(*token_ids.at(0_usize));
        let token_reserve_ = IERC1155Dispatcher { contract_address: token_address_ }.balance_of(contract, *token_ids.at(0_usize));

        // Ensure this method is only called for subsequent liquidity adds
        assert(lp_reserve_ > as_u256(0_u128, 0_u128), 'lp reserve must be > 0');
        
        // Required price calc
        // X/Y = dx/dy
        // dx = X*dy/Y
        let (numerator, mul_overflow) = u256_overflow_mul(currency_reserve_, *token_amounts.at(0_usize));
        assert(!mul_overflow, 'mul overflow');

        // let currency_amount_ = u256_div(numerator, token_reserve_); //TODO: check for div by 0
        let currency_amount_ = as_u256(0_u128, 0_u128);
        assert(currency_amount_ <= *max_currency_amounts.at(0_usize), 'amount too high');

        // Transfer currency to contract
        IERC20Dispatcher { contract_address: currency_address_ }.transfer_from(caller, contract, currency_amount_);

        IERC1155Dispatcher { contract_address: token_address_ }.safe_transfer_from(caller, contract, *token_ids.at(0_usize), *token_amounts.at(0_usize), ArrayTrait::new());

        // Update the new currency and LP reserves
        let (new_currency_reserve, add_overflow) = u256_overflowing_add(currency_reserve_, currency_amount_);
        assert(!add_overflow, 'add overflow');
        currency_reserves::write(*token_ids.at(0_usize), new_currency_reserve);

        let (new_lp_reserve, add_overflow) = u256_overflowing_add(lp_reserve_, currency_amount_);
        assert(!add_overflow, 'add overflow');
        lp_reserves::write(*token_ids.at(0_usize), new_lp_reserve);

        // Mint LP tokens to caller
        ERC1155::_mint(caller, *token_ids.at(0_usize), currency_amount_, ArrayTrait::new());

        // TODO Emit Event

        max_currency_amounts.pop_front();
        token_ids.pop_front();
        token_amounts.pop_front();

        return add_liquidity_loop(
            max_currency_amounts,
            token_ids,
            token_amounts,
        );        
        


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
    fn get_currency_address() -> ContractAddress {
        return currency_address::read();
    }

    #[view]
    fn get_token_address() -> ContractAddress {
        return token_address::read();
    }

    #[view]
    fn get_currency_reserves(token_id: u256) -> u256 {
        return currency_reserves::read(token_id);
    }

    #[view]
    fn get_lp_fee_thousands() -> u256 {
        return lp_fee_thousands::read();
    }

    #[view]
    fn get_all_sell_price() {

    }

    fn get_all_sell_price_loop() {
        check_gas();

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