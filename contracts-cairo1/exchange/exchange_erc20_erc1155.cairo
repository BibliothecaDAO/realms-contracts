// a exchange that can exchange erc20 token to erc1155 token
#[contract]
mod Exchange_ERC20_ERC1155 {
    use zeroable::Zeroable;
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    use starknet::ContractAddress;
    use starknet::ContractAddressZeroable;

    struct Storage {

    }
//##############
// CONSTRUCTOR #
//##############

    #[external]
    fn initialize() {

    }

    #[external]
    fn upgrade() {

    }

//#####
// LP #
//#####
    #[external]
    fn initial_liquidity() {

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