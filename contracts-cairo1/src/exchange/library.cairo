use realms::utils::helper::as_u256;

trait AMM {
    fn get_buy_price(
        token_amount: u256,
        currency_reserve: u256,
        token_reserve: u256,
        lp_fee_thousand: u256,
    ) -> u256;

    fn get_sell_price(
        token_amount: u256,
        currency_reserve: u256,
        token_reserve: u256,
        lp_fee_thousand: u256,
    ) -> u256;
}

impl AMMimpl of AMM {
    fn get_buy_price(
        token_amount: u256,
        currency_reserve: u256,
        token_reserve: u256,
        lp_fee_thousand: u256,
    ) -> u256 {
        return as_u256(0_u128, 0_u128);
    }
    fn get_sell_price(
        token_amount: u256,
        currency_reserve: u256,
        token_reserve: u256,
        lp_fee_thousand: u256,
    ) -> u256 {
        return as_u256(0_u128, 0_u128);
    }
}