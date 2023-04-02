use realms::utils::helper::as_u256;
use integer::u256_overflow_mul;
use integer::u256_overflowing_add;
use integer::u256_overflow_sub;

trait AMM {
    fn get_currency_amount_when_buy(
        token_amount: u256,
        currency_reserve: u256,
        token_reserve: u256,
        lp_fee_thousand: u256,
    ) -> u256;

    fn get_currency_amount_when_sell(
        token_amount: u256,
        currency_reserve: u256,
        token_reserve: u256,
        lp_fee_thousand: u256,
    ) -> u256;
}

impl AMMImpl of AMM {
    fn get_currency_amount_when_buy(
        token_amount: u256,
        currency_reserve: u256,
        token_reserve: u256,
        lp_fee_thousand: u256,
    ) -> u256 {
        let fee_multiplier_ = as_u256(1000_u128, 0_u128) - lp_fee_thousand;
        let (numerator, mul_overflow) = u256_overflow_mul(token_amount, currency_reserve);
        assert(!mul_overflow, 'mul overflow');
        let (numerator, mul_overflow) = u256_overflow_mul(numerator, as_u256(1000_u128, 0_u128));
        assert(!mul_overflow, 'mul overflow');
        let (denominator, sub_overflow) = u256_overflow_sub(token_reserve, token_amount);
        assert(!sub_overflow, 'sub overflow');
        let (denominator, mul_overflow) = u256_overflow_mul(denominator, fee_multiplier_);
        assert(!mul_overflow, 'mul overflow');

        // let quotient = numerator / denominator; // TODO fix this
        let quotient = as_u256(0_u128, 0_u128);
        return quotient;
    }
    fn get_currency_amount_when_sell(
        token_amount: u256,
        currency_reserve: u256,
        token_reserve: u256,
        lp_fee_thousand: u256,
    ) -> u256 {
        return as_u256(0_u128, 0_u128);
    }
}