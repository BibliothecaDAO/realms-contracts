# Exchange ERC20 ERC1155

The exchange contract allows trades between pairs of ERC20 and ERC1155 contract tokens.
The contract is based on the [NiftyswapExchange20.sol contract](https://github.com/0xsequence/niftyswap/blob/master/src/contracts/exchange/NiftyswapExchange20.sol) and its [specifications](https://github.com/0xsequence/niftyswap/blob/master/SPECIFICATIONS.md).

One deployed contract will handle pairs between the ERC20 currency and all the tokens on a ERC1155.
Each pair has it's price curve tracked individually.
Price changes on one token pair will not affect another.

The exchange contract itself is ERC1155 compliant and will issue LP tokens with a token type id corresponding to the token type id in the pair.
These tokens can be freely traded or used in other DeFi applications.

## Terminology and Naming Conventions

The ERC20 token is defined as the *currency*.

The ERC1155 token is defined as the *token*.

Some variables have a trailing underscore `_` to prevent collisions.

*Pair* is used to describe a price curve between the currency and a single token type on the token contract.

Functions named with `_loop` are used for recursive processing of lists of items.

## Contract Interactions

The contract can be broken into a number of sections:

* Initialisation
* Liquidity
* Swaps

### Initialisation

The exchange is initialised through the constructor and initial liquidity pool addition.

#### Constructor

Each deployment of the contract will work with pairs between an ERC20 contract and all the tokens on an ERC1155 contract. This means one contract can manage multiple exchange pairs. 

The constructor takes the address for the ERC20 and ERC1155 token contracts, and the liquidity provider fee.

The liquidity provider fee is provided in the thousandths. e.g. A value of 15 would equate to a 1.5% fee on trades.

#### Initial Liquidity

Use this method to provide the initial liquidity to a pair.

This method is only available for the first time liquidty is added to a pair. If you are creating pairs between multiple tokens on the ERC1155 contract, this method will need to be called for each pair.

When calling this method you provide the currency amount, ERC1155 token type id and the token amount.
This sets the initial price of the pair. We expect any large enough variation in pricing to be corrected via arbitrage.

The exchange issues liquidity pool tokens equivalent to the supplied currency.

### Liquidity

After initialisation, liquidity can be freely added or removed from the pools using the methods below.

Note, fees are recovered during swaps and so there is no reference to fees during liquidity pool interactions.

#### Add Liquidity

Use this method to add subsequent liquidity to an existing pair.

This method is called with:

* The maximum amount of currency the caller is willing to spend when adding liquidity
* The token type id they are supplying liquidity for
* The exact amount of tokens the caller will spend when adding liquidity
* A maximum timestamp which the transaction must be accepted by

Liquidty is supplied at the current price point in the `x * y = k` curve.

Due to the fluctations in price as swaps are made, the caller may not know the exact amount of currency that will be required to supply the liquidity pool until the transaction is accepted. 
The caller instead supplies the maximum amount of currency they are willing to spend. This acts a measure of slippage.

The exchange issues liquidity pool tokens equivalent to the supplied currency.

#### Remove Liquidity

Use this method to redeem tokens supplied to the liquidty pool, by burning liquidity pool tokens.

This method is called with:

* The minimum amount of currency the caller is willing to receive when removing liquidity
* The token type id they are removing liquidity for
* The minimum amount of tokens the caller is willing to receive when removing liquidity
* The exact amount of liquidity pool tokens to spend
* A maximum timestamp which the transaction must be accepted by

Liquidty is remove at the current price point in the `x * y = k` curve.

Due to the fluctations in price as swaps are made, the caller may not know the exact amount of currency or tokens that will be recieved when removing liquidity from the pool until the transaction is accepted.
The caller instead supplies the minimum amount of currency and tokens they are willing to receive. This acts a measure of slippage.

The exchange burns liquidity pool tokens supplied in the call.

### Swaps

Swaps are performed as either buy or sell actions.

When making a swap, the exchange will calculate the price according to the `x * y = k` curve.
Fees are collected against the currency in both buy and sell actions.
Due to this, `k` will steadly increase as a measure to collect rewards for the liquidity providers.
When liquidity is removed from the pools, as `k` has increased, their proportional share in the pool will have increased as well.

#### Buy Tokens

Use this method to purchase tokens with currency.

This method is called with:

* The maximum amount of currency the caller is willing to spend when swapping
* The token type id they are swapping
* The exact amount of tokens the caller will receive when swapping
* A maximum timestamp which the transaction must be accepted by

See the above Swap section for information about the pricing curve.

Due to the fluctations in price as swaps are made, the caller may not know the exact amount of currency that will be required to swap until the transaction is accepted. 
The caller instead supplies the maximum amount of currency they are willing to spend. This acts a measure of slippage.

#### Sell Tokens

Use this method to sell tokens for currency.

This method is called with:

* The minimum amount of currency the caller is willing to receive when swapping
* The token type id they are swapping
* The exact amount of tokens the caller will spend when swapping
* A maximum timestamp which the transaction must be accepted by

See the above Swap section for information about the pricing curve.

Due to the fluctations in price as swaps are made, the caller may not know the exact amount of currency that will be required to swap until the transaction is accepted. 
The caller instead supplies the minimum amount of currency they are willing to receive. This acts a measure of slippage.

#### Get Buy / Sell Price

The `get_buy_price` and `get_sell_price` functions are read only functions used to get the current price according to the `x * y = k` curve, and take into considering the exchange fee.
These methods are separated from the buy and sell methods so that they can be used for price display on frontends.

The liquidity provider fee is stored in the thousandths. e.g. A value of `15` would equate to a 1.5% fee on trades. Thus `1000` is used as a static value in these calculations.

### Misc Getters

There are additional getters for the following stored values:

* Currency contract address
* Token contract address
* Currency reserves (for the given token type id)
* LP fee (in thousandths)

The contract does not store a value for the ERC1155 token reserves and instead relies on the `balanceOf` ERC1155 function.

### LP ERC 1155 Compliance

There are additional method to support the ERC1155 compliance of LP tokens provided by this contract.
