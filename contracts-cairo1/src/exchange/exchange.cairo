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
    use realms::utils::helper::check_gas;
    use integer::u256_overflow_mul;
    use integer::u256_overflowing_add;
    use integer::u256_overflow_sub;
    use realms::utils::helper::as_u256;

    use openzeppelin::token::erc1155::ERC1155;  // TODO: remove when openzeppelin ERC1155 library is supported
    use openzeppelin::introspection::erc165::ERC165Contract; // TODO: remove when openzeppelin ERC165 library is supported

    use realms::exchange::library::AMM;

    struct Storage {
        currency_address: ContractAddress,
        token_address: ContractAddress,
        currency_reserves: LegacyMap::<u256, u256>,
        token_reserves: LegacyMap::<u256, u256>,
        lp_fee_thousand: u256,
        royalty_fee_thousand: u256,
        royalty_fee_address: ContractAddress,
    }


    #[abi]
    trait IERC20 {
        fn name() -> felt252;
        fn symbol() -> felt252;
        fn decimals() -> u8;
        fn total_supply() -> u256;
        fn balance_of(account: ContractAddress) -> u256;
        fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256;
        fn transfer(recipient: ContractAddress, amount: u256) -> bool;
        fn transfer_from(sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
        fn approve(spender: ContractAddress, amount: u256) -> bool;
    }

    #[abi]
    trait IERC1155 {
        // IERC1155
        fn balance_of(account: ContractAddress, id: u256) -> u256;
        fn balance_of_batch(accounts: Array<ContractAddress>, ids: Array<u256>) -> Array<u256>;
        fn is_approved_for_all(account: ContractAddress, operator: ContractAddress) -> bool;
        fn set_approval_for_all(operator: ContractAddress, approved: bool);
        fn safe_transfer_from(
            from: ContractAddress, to: ContractAddress, id: u256, amount: u256, data: Array<felt252>
        );
        fn safe_batch_transfer_from(
            from: ContractAddress,
            to: ContractAddress,
            ids: Array<u256>,
            amounts: Array<u256>,
            data: Array<felt252>
        );
        // IERC1155MetadataURI
        fn uri(id: u256) -> felt252;
    }

//##############
// CONSTRUCTOR #
//##############

    #[external]
    fn initializer(
        uri: felt252,
        currency_address_: ContractAddress,
        token_address_: ContractAddress,
        lp_fee_thousand_: u256,
        royalty_fee_thousand_: u256,
        royalty_fee_address_: ContractAddress,
        proxy_admin: ContractAddress,
    ) {
        currency_address::write(currency_address_);
        token_address::write(token_address_);
        lp_fee_thousand::write(lp_fee_thousand_);
        // set_royalty_info(royalty_fee_thousand_, royalty_fee_address_);
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
        
        //TODO:  add if ERC1155 do not support totalSupply
        // lp_reserves::write(*token_ids.at(0_usize), *currency_amounts.at(0_usize));

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
        let lp_total_supply_ = get_lp_supply(*token_ids.at(0_usize));
        let token_reserve_ = IERC1155Dispatcher { contract_address: token_address_ }.balance_of(contract, *token_ids.at(0_usize));

        // Ensure this method is only called for subsequent liquidity adds
        assert(lp_total_supply_ > as_u256(0_u128, 0_u128), 'lp reserve must be > 0');
        
        // Required price calc
        // X/Y = dx/dy
        // dx = X*dy/Y
        let (numerator, mul_overflow) = u256_overflow_mul(currency_reserve_, *token_amounts.at(0_usize));
        assert(!mul_overflow, 'mul overflow');

        // let currency_amount_ = u256_div(numerator, token_reserve_); //TODO: not support yet
        let currency_amount_ = as_u256(0_u128, 0_u128);  // TODO: remove when div is supported
        assert(currency_amount_ <= *max_currency_amounts.at(0_usize), 'amount too high');

        // Transfer currency to contract
        IERC20Dispatcher { contract_address: currency_address_ }.transfer_from(caller, contract, currency_amount_);

        IERC1155Dispatcher { contract_address: token_address_ }.safe_transfer_from(caller, contract, *token_ids.at(0_usize), *token_amounts.at(0_usize), ArrayTrait::new());

        let (numerator, mul_overflow) = u256_overflow_mul(lp_total_supply_, currency_amount_);
        assert(!mul_overflow, 'mul overflow');
        // let lp_amount_ = u256_div(numerator, currency_reserve_); //TODO: not support yet
        let lp_amount_ = as_u256(0_u128, 0_u128); // TODO: remove when div is supported

        //TODO:  add if ERC1155 do not support totalSupply
        // lp_reserves::write(*token_ids.at(0_usize), *currency_amounts.at(0_usize));
        
        // Mint LP tokens to caller
        ERC1155::_mint(caller, *token_ids.at(0_usize), lp_amount_, ArrayTrait::new());

        let (new_currency_reserve, add_overflow) = u256_overflowing_add(currency_reserve_, currency_amount_);
        assert(!add_overflow, 'add overflow');
        currency_reserves::write(*token_ids.at(0_usize), new_currency_reserve);

        let (new_token_reserve, add_overflow) = u256_overflowing_add(token_reserve_, *token_amounts.at(0_usize));
        assert(!add_overflow, 'add overflow');
        token_reserves::write(*token_ids.at(0_usize), new_token_reserve);

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
    fn remove_liquidity(
        mut min_currency_amounts: Array<u256>,
        mut token_ids: Array<u256>,
        mut min_token_amounts: Array<u256>,
        mut lp_amounts: Array<u256>,
        deadline: felt252,
    ) {
        assert(min_currency_amounts.len() == token_ids.len(), 'not same length 1');
        assert(min_currency_amounts.len() == min_token_amounts.len(), 'not same length 2');
        assert(min_currency_amounts.len() == lp_amounts.len(), 'not same length 3');
        let info = starknet::get_block_info().unbox();
        assert(info.block_timestamp < deadline.try_into().unwrap(), 'deadline passed');
        return remove_liquidity_loop(
            min_currency_amounts,
            token_ids,
            min_token_amounts,
            lp_amounts,
        );
    }

    fn remove_liquidity_loop(
        mut min_currency_amounts: Array<u256>,
        mut token_ids: Array<u256>,
        mut min_token_amounts: Array<u256>,
        mut lp_amounts: Array<u256>,
    ) {
        check_gas();
        if (min_currency_amounts.len() == 0_usize) {
            return ();
        }
        let caller = starknet::get_caller_address();
        let contract = starknet::get_contract_address();
        let currency_address_ = currency_address::read();
        let token_address_ = token_address::read();

        let currency_reserve_ = currency_reserves::read(*token_ids.at(0_usize));
        let lp_total_supply_ = get_lp_supply(*token_ids.at(0_usize));
        let token_reserve_ = IERC1155Dispatcher { contract_address: token_address_ }.balance_of(contract, *token_ids.at(0_usize));

        assert(lp_total_supply_ > *lp_amounts.at(0_usize), 'insufficient lp supply');


        let (numerator, mul_overflow) = u256_overflow_mul(currency_reserve_, *lp_amounts.at(0_usize));
        assert(!mul_overflow, 'mul overflow');
        // let currency_amount_ = u256_div(numerator, lp_total_supply_); //TODO: not support yet
        let currency_amount_ = as_u256(0_u128, 0_u128); // TODO: remove when div is supported
        assert(currency_amount_ >= *min_currency_amounts.at(0_usize), 'amount too low');

        let (numerator, mul_overflow) = u256_overflow_mul(token_reserve_, *lp_amounts.at(0_usize));
        assert(!mul_overflow, 'mul overflow');
        // let token_amount_ = u256_div(numerator, lp_total_supply_); //TODO: not support yet
        let token_amount_ = as_u256(0_u128, 0_u128); // TODO: remove when div is supported
        assert(token_amount_ >= *min_token_amounts.at(0_usize), 'amount too low');

        // Burn LP tokens from caller
        ERC1155::_burn(caller, *token_ids.at(0_usize), *lp_amounts.at(0_usize));

        let (new_currency_reserve, sub_overflow) = u256_overflow_sub(currency_reserve_, currency_amount_);
        assert(!sub_overflow, 'sub overflow');
        currency_reserves::write(*token_ids.at(0_usize), new_currency_reserve);

        let (new_token_reserve, sub_overflow) = u256_overflow_sub(token_reserve_, token_amount_);
        assert(!sub_overflow, 'sub overflow');
        token_reserves::write(*token_ids.at(0_usize), new_token_reserve);

        //TODO: remove if ERC1155 not support totalSupply
        // lp_reserves::write(*token_ids.at(0_usize), lp_total_supply_ - *lp_amounts.at(0_usize));

        // Transfer currency to caller
        IERC20Dispatcher { contract_address: currency_address_ }.transfer(caller, currency_amount_);
        IERC1155Dispatcher { contract_address: token_address_ }.safe_transfer_from(contract, caller, *token_ids.at(0_usize), token_amount_, ArrayTrait::new());

        // TODO Emit Event

        min_currency_amounts.pop_front();
        token_ids.pop_front();
        min_token_amounts.pop_front();
        lp_amounts.pop_front();

        return remove_liquidity_loop(
            min_currency_amounts,
            token_ids,
            min_token_amounts,
            lp_amounts,
        );

        
    }

//#############
// BUY TOKENS #
//#############
    #[external]
    fn buy_tokens(
        mut max_currency_amounts: Array<u256>,
        mut token_ids: Array<u256>,
        mut token_amounts: Array<u256>,
        deadline: felt252,
    ) -> u256 {
        assert(max_currency_amounts.len() == token_ids.len(), 'not same length 1');
        assert(max_currency_amounts.len() == token_amounts.len(), 'not same length 2');
        let info = starknet::get_block_info().unbox();
        assert(info.block_timestamp < deadline.try_into().unwrap(), 'deadline passed');
        
        let currency_amount = buy_tokens_loop(
            token_ids,
            token_amounts,
        );
        assert(currency_amount <= *max_currency_amounts.at(0_usize), 'amount too high');

        return currency_amount;

    }

    fn buy_tokens_loop(
        mut token_ids: Array<u256>,
        mut token_amounts: Array<u256>,
    ) -> u256 {
        check_gas();
        if (token_ids.len() == 0_usize) {
            return as_u256(0_u128, 0_u128);
        }
        let caller = starknet::get_caller_address();
        let contract = starknet::get_contract_address();
        let currency_address_ = currency_address::read();
        let token_address_ = token_address::read();

        let currency_reserve_ = currency_reserves::read(*token_ids.at(0_usize));
        let token_reserve_ = token_reserves::read(*token_ids.at(0_usize));

        let lp_fee_thousand_ = lp_fee_thousand::read();

        let currency_amount_sans_royal_ = AMM::get_currency_amount_when_buy(
            *token_amounts.at(0_usize),
            currency_reserve_,
            token_reserve_,
            lp_fee_thousand_,
        );

        let royalty_ = get_royalty_with_amount(
            currency_amount_sans_royal_,
        );

        let currency_amount_ = currency_amount_sans_royal_ + royalty_;

        // Update reserve 
        let (new_currency_reserve, add_overflow) = u256_overflowing_add(currency_reserve_, currency_amount_);
        assert(!add_overflow, 'add overflow');
        currency_reserves::write(*token_ids.at(0_usize), new_currency_reserve);

        // Transfer currency from caller
        IERC20Dispatcher { contract_address: currency_address_ }.transfer_from(caller, contract, currency_amount_);
        // Royalty transfer
        IERC20Dispatcher { contract_address: currency_address_ }.transfer_from(caller, royalty_fee_address::read(), royalty_);

        // Transfer token to caller
        IERC1155Dispatcher { contract_address: token_address_ }.safe_transfer_from(contract, caller, *token_ids.at(0_usize), *token_amounts.at(0_usize), ArrayTrait::new());

        // TODO Emit Event

        token_ids.pop_front();
        token_amounts.pop_front();

        let mut currency_total_ = buy_tokens_loop(
            token_ids,
            token_amounts,
        );
        let (new_currency_total, add_overflow) = u256_overflowing_add(currency_total_, currency_amount_);
        assert(!add_overflow, 'add overflow');
        return new_currency_total;
    }

//##############
// SELL TOKENS #
//##############
    #[external]
    fn sell_tokens(
        mut min_currency_amounts: Array<u256>,
        mut token_ids: Array<u256>,
        mut token_amounts: Array<u256>,
        deadline: felt252,
    ) -> u256 {
        assert(min_currency_amounts.len() == token_ids.len(), 'not same length 1');
        assert(min_currency_amounts.len() == token_amounts.len(), 'not same length 2');
        let info = starknet::get_block_info().unbox();
        assert(info.block_timestamp < deadline.try_into().unwrap(), 'deadline passed');

        let currency_amount = sell_tokens_loop(
            token_ids,
            token_amounts,
        );
        assert(currency_amount >= *min_currency_amounts.at(0_usize), 'amount too low');

        return currency_amount;
    }

    fn sell_tokens_loop(
        mut token_ids: Array<u256>,
        mut token_amounts: Array<u256>,
    ) -> u256 {
        check_gas();
        if (token_ids.len() == 0_usize) {
            return as_u256(0_u128, 0_u128);
        }
        let caller = starknet::get_caller_address();
        let contract = starknet::get_contract_address();
        let currency_address_ = currency_address::read();
        let token_address_ = token_address::read();

        let currency_reserve_ = currency_reserves::read(*token_ids.at(0_usize));
        let token_reserve_ = token_reserves::read(*token_ids.at(0_usize));

        let lp_fee_thousand_ = lp_fee_thousand::read();

        let currency_amount_sans_royal_ = AMM::get_currency_amount_when_sell(
            *token_amounts.at(0_usize),
            currency_reserve_,
            token_reserve_,
            lp_fee_thousand_,
        );

        let royalty_ = get_royalty_with_amount(
            currency_amount_sans_royal_,
        );

        let currency_amount_ = currency_amount_sans_royal_ - royalty_;

        // Update reserve
        let (new_currency_reserve, sub_overflow) = u256_overflow_sub(currency_reserve_, currency_amount_);
        assert(!sub_overflow, 'sub overflow');
        currency_reserves::write(*token_ids.at(0_usize), new_currency_reserve);

        // Transfer currency to caller
        IERC20Dispatcher { contract_address: currency_address_ }.transfer(caller, currency_amount_);
        // Royalty transfer
        IERC20Dispatcher { contract_address: currency_address_ }.transfer(royalty_fee_address::read(), royalty_);

        // Transfer token from caller
        IERC1155Dispatcher { contract_address: token_address_ }.safe_transfer_from(caller, contract, *token_ids.at(0_usize), *token_amounts.at(0_usize), ArrayTrait::new());

        // TODO Emit Event

        token_ids.pop_front();
        token_amounts.pop_front();

        let mut currency_total_ = sell_tokens_loop(
            token_ids,
            token_amounts,
        );
        let (new_currency_total, add_overflow) = u256_overflowing_add(currency_total_, currency_amount_);
        assert(!add_overflow, 'add overflow');
        return new_currency_total;

    }

//################
// PRICING CALCS #
//################

    #[view]
    fn get_royalty_with_amount(amount_sans_royalty: u256) -> u256 {
        let royalty_fee_thousand_ = royalty_fee_thousand::read();
        let (royalty, mul_overflow) = u256_overflow_mul(amount_sans_royalty, royalty_fee_thousand_);
        assert(!mul_overflow, 'mul overflow');

        // let (royalty, div_overflow) = u256_overflowing_div(royalty, as_u256(1000_u128, 0_u128)); // TODO: not support yet
        let royalty = as_u256(0_u128, 0_u128); // TODO: remove this line
        return royalty;
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

    #[external]
    fn onERC1155Received(
        operator: ContractAddress,
        from: ContractAddress,
        id: u256,
        value: u256,
        data: Array<felt252>
    ) -> u32 {
        return 0_u32; // TODO: return value
    }

    #[external]
    fn onERC1155BatchReceived(
    operator: ContractAddress,
    from: ContractAddress,
    ids: Array<u256>,
    values: Array<u256>,
    data: Array<felt252>
    ) -> u32 {
        return 0_u32; // TODO: return value
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
    fn get_token_reserves(token_id: u256) -> u256 {
        return token_reserves::read(token_id);
    }

    #[view]
    fn get_lp_fee_thousand() -> u256 {
        return lp_fee_thousand::read();
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
    fn supportsInterface(interface_id: u32) -> bool {
        ERC165Contract::supports_interface(interface_id)
    }



    #[view]
    fn balanceOf(
        account: ContractAddress,
        token_id: u256,
    ) -> u256 {
        ERC1155::balance_of(account, token_id)
    }

    #[view]
    fn balanceOfBatch(
        accounts: Array<ContractAddress>,
        token_ids: Array<u256>,
    ) -> Array<u256> {
        ERC1155::balance_of_batch(accounts, token_ids)
    }

    #[view]
    fn isApprovedForAll(
        account: ContractAddress,
        operator: ContractAddress,
    ) -> bool {
        ERC1155::is_approved_for_all(account, operator)
    }

    #[view]
    fn uri(token_id: u256) -> felt252 {
        return ERC1155::uri(token_id);
    }

    #[view]
    fn owner() -> felt252 {
        return 0; // TODO: need implement base on Ownable library
    }

    #[view]
    fn get_lp_supply(token_id: u256) -> u256 {
        return as_u256(1_u128, 0_u128); // TODO: need implement base on ERC1155 library
    }

//
// Externals
//
    #[external]
    fn setApprovalForAll(
        operator: ContractAddress,
        approved: bool,
    ) {
        ERC1155::set_approval_for_all(
            operator,
            approved,
        );
    }

    #[external]
    fn safeTransferFrom(
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        amount: u256,
        data: Array<felt252>,
    ) {
        ERC1155::safe_transfer_from(
            from,
            to,
            token_id,
            amount,
            data,
        );
    }

    #[external]
    fn safeBatchTransferFrom(
        from: ContractAddress,
        to: ContractAddress,
        token_ids: Array<u256>,
        amounts: Array<u256>,
        data: Array<felt252>,
    ) {
        ERC1155::safe_batch_transfer_from(
            from,
            to,
            token_ids,
            amounts,
            data,
        );
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