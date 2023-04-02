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

        // formula: (x - (1 + r)delta_x) * (y + delta_y) = k
        // compute: delta_x = x * delta_y / (y - delta_y) / (1 - r)
        let fee_multiplier_ = as_u256(1000_u128, 0_u128) - lp_fee_thousand;
        let (numerator, mul_overflow) = u256_overflow_mul(token_amount, currency_reserve);
        assert(!mul_overflow, 'mul overflow');
        let (numerator, mul_overflow) = u256_overflow_mul(numerator, as_u256(1000_u128, 0_u128));
        assert(!mul_overflow, 'mul overflow');
        let (denominator, sub_overflow) = u256_overflow_sub(token_reserve, token_amount);
        assert(!sub_overflow, 'sub overflow');
        let (denominator, mul_overflow) = u256_overflow_mul(denominator, fee_multiplier_);
        assert(!mul_overflow, 'mul overflow');

        // need to round up the result
        // TODO: div not support yet
        // let (amount, rem) = u256_overflowing_div(numerator, denominator);
        // if (rem > 0) {
        //     let (amount, add_overflow) = u256_overflowing_add(amount, 1);
        //     assert(!add_overflow, 'add overflow');
        // }

        let amount = as_u256(0_u128, 0_u128);

        return amount;
    }

    
    fn get_currency_amount_when_sell(
        token_amount: u256,
        currency_reserve: u256,
        token_reserve: u256,
        lp_fee_thousand: u256,
    ) -> u256 {
        // r means the fee rate, not in thousand and below method is the same. When actually computing, we need to take that into account: r * 1000 = lp_fee_thousand 
        // formula: ( x - delta_x) * (y + (1 - r) * delta_y) = k
        // compute: delta_x = (1 - r) * delta_y * x / (y + (1 - r) * delta_y)
        // Why is it different from buying? Because we need to charge a fee on the source token that the user provides. When buying, the source token is the currency, while when selling, the source token is the token.
        let fee_multiplier_ = as_u256(1000_u128, 0_u128) - lp_fee_thousand;
        
        let (numerator, mul_overflow) = u256_overflow_mul(token_amount, currency_reserve);
        assert(!mul_overflow, 'mul overflow');
        let (numerator, mul_overflow) = u256_overflow_mul(numerator, fee_multiplier_);
        assert(!mul_overflow, 'mul overflow');

        let (denominator1, mul_overflow) = u256_overflow_mul(token_amount, fee_multiplier_);
        assert(!mul_overflow, 'mul overflow');
        let (denominator2, mul_overflow) = u256_overflow_mul(token_reserve, as_u256(1000_u128, 0_u128));
        assert(!mul_overflow, 'mul overflow');
        let (denominator, add_overflow) = u256_overflowing_add(denominator1, denominator2);
        assert(!add_overflow, 'add overflow');

        // let quotient = numerator / denominator; // TODO fix this
        let quotient = as_u256(0_u128, 0_u128);
        return quotient;
    }
}