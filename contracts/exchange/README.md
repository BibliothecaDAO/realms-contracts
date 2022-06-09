[![Discord](https://badgen.net/badge/icon/discord?icon=discord&label)](https://discord.gg/uQnjZhZPfu)
[![Twitter](https://badgen.net/badge/icon/twitter?icon=twitter&label)](https://twitter.com/LootRealms)

![This is an image](/static/Resource_Emporium.png)

# Token Emporium (AMM)

## What is the Emporium?

### The Emporium a traditional AMM with a slight variation. Users can trade up to `n` amount of ERC1155 tokens in one transaction with a ERC20 token!

<hr>

## History of the Emporium

The contract is heavily based on the [NiftyswapExchange20.sol contract](https://github.com/0xsequence/niftyswap/blob/master/src/contracts/exchange/NiftyswapExchange20.sol) and its [specifications](https://github.com/0xsequence/niftyswap/blob/master/SPECIFICATIONS.md). 

One deployed contract will handle pairs between the ERC20 currency and all the tokens on an ERC1155.
Each pair has its price curve tracked individually.

Price changes on one token pair will not affect another.

The exchange contract itself is ERC1155 compliant and will issue LP tokens with a token type id corresponding to the token type id in the pair.
These tokens can then be freely traded or used in other DeFi applications!

**This folder contains Exchange contracts. If you're looking for another contract, please see the [directory of our Realms Smart Contracts](https://github.com/BibliothecaForAdventurers/realms-contracts).**

<hr>

## Understanding the code
<details><summary> Terminology and naming conventions</summary>

---
The ERC20 token is defined as the *currency*.

The ERC1155 token is defined as the *token*.

Some variables have a trailing underscore `_` to prevent collisions.

*Pair* is used to describe a price curve between the currency and a single token type on the token contract.

Functions named with `_loop` are used for recursive processing of lists of items.
</details>

<details><summary> Contract Interactions</summary>

---

The contract can be broken into a number of sections:

* Initialisation
* Liquidity
* Swaps

---

# Initialisation

The exchange is initialised through the proxy pattern for now. You are welcome to just implement a set constructor if you prefer that.

## Setup

Each deployment of the contract will work with pairs between an ERC20 contract and all the tokens on an ERC1155 contract. This means one contract can manage multiple exchange pairs. 

The constructor takes the address for the ERC20 and ERC1155 token contracts, and the liquidity provider fee.

The liquidity provider fee is provided in the thousandths. e.g. A value of 15 would equate to a 1.5% fee on trades.

```
@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    currency_address_ : felt,
    token_address_ : felt,
    lp_fee_thousands_ : Uint256,
    royalty_fee_thousands_ : Uint256,
    royalty_fee_address_ : felt,
    proxy_admin : felt,
):
    currency_address.write(currency_address_) # ERC20 address of currency token
    token_address.write(token_address_) # ERC1155 address of tokens
    lp_fee_thousands.write(lp_fee_thousands_) # LP Fees
    set_royalty_info(royalty_fee_thousands_, royalty_fee_address_) # Currency Royalty
    Proxy_initializer(proxy_admin)
    return ()
end
```

## Initial Liquidity

Use this method to provide the initial liquidity to a pair.

This method is only available for the first time liquidity is added to a pair. If you are creating pairs between multiple tokens on the ERC1155 contract, this method will need to be called for each pair.

When calling this method you provide the currency amount, ERC1155 token type id and the token amount.
This sets the initial price of the pair. We expect any large enough variation in pricing to be corrected via arbitrage.

The exchange issues liquidity pool tokens equivalent to the supplied currency.

```
@external
func initial_liquidity{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    currency_amounts_len : felt,
    currency_amounts : Uint256*,
    token_ids_len : felt,
    token_ids : Uint256*,
    token_amounts_len : felt,
    token_amounts : Uint256*,
):
    alloc_locals

    # Recursive break
    if currency_amounts_len == 0:
        return ()
    end

    assert currency_amounts_len = token_ids_len
    assert currency_amounts_len = token_amounts_len

    let (caller) = get_caller_address()
    let (contract) = get_contract_address()

    let (token_address_) = token_address.read()
    let (currency_address_) = currency_address.read()

    # Only valid for first liquidity add to LP
    let (currency_reserves_ : Uint256) = currency_reserves.read([token_ids])
    with_attr error_message("Only valid for initial liquidity add"):
        assert currency_reserves_ = Uint256(0, 0)
    end

    # Transfer currency and token to exchange
    IERC20.transferFrom(currency_address_, caller, contract, [currency_amounts])
    tempvar syscall_ptr : felt* = syscall_ptr
    IERC1155.safeTransferFrom(token_address_, caller, contract, [token_ids], [token_amounts])

    # Assert otherwise rounding error could end up being significant on second deposit
    let (ok) = uint256_le(Uint256(1000, 0), [currency_amounts])
    with_attr error_message("Must supply larger currency for initial deposit"):
        assert_not_zero(ok)
    end

    # Update currency reserve size for token id before transfer
    currency_reserves.write([token_ids], [currency_amounts])

    # Initial liquidity is currency amount deposited
    lp_reserves.write([token_ids], [currency_amounts])

    # Mint LP tokens
    ERC1155_mint(caller, [token_ids], [currency_amounts])

    # Emit event
    liquidity_added.emit(caller, [currency_amounts], [token_ids], [token_amounts])

    # Recurse
    return initial_liquidity(
        currency_amounts_len - 1,
        currency_amounts + Uint256.SIZE,
        token_ids_len - 1,
        token_ids + Uint256.SIZE,
        token_amounts_len - 1,
        token_amounts + Uint256.SIZE,
    )
end
```

---

## Liquidity

After initialisation, liquidity can be freely added or removed from the pools using the methods below.

Note, fees are recovered during swaps and so there is no reference to fees during liquidity pool interactions.

### Add Liquidity

Use this method to add subsequent liquidity to an existing pair.

This method is called with:

* The maximum amount of currency the caller is willing to spend when adding liquidity
* The token type id they are supplying liquidity for
* The exact amount of tokens the caller will spend when adding liquidity
* A maximum timestamp which the transaction must be accepted by

Liquidity is supplied at the current price point in the `x * y = k` curve.

Due to the fluctuations in price as swaps are made, the caller may not know the exact amount of currency that will be required to supply the liquidity pool until the transaction is accepted. 
The caller instead supplies the maximum amount of currency they are willing to spend. This acts as a measure of slippage.

The exchange issues liquidity pool tokens equivalent to the supplied currency.

### Remove Liquidity

Use this method to redeem tokens supplied to the Liquidity pool, by burning liquidity pool tokens.

This method is called with:

* The minimum amount of currency the caller is willing to receive when removing liquidity
* The token type id they are removing liquidity for
* The minimum amount of tokens the caller is willing to receive when removing liquidity
* The exact amount of liquidity pool tokens to spend
* A maximum timestamp which the transaction must be accepted by

Liquidity is remove at the current price point in the `x * y = k` curve.

Due to the fluctuations in price as swaps are made, the caller may not know the exact amount of currency or tokens that will be received when removing liquidity from the pool until the transaction is accepted.
The caller instead supplies the minimum amount of currency and tokens they are willing to receive. This acts as a measure of slippage.

The exchange burns liquidity pool tokens supplied in the call.

---

## Swaps

Swaps are performed as either buy or sell actions.

When making a swap, the exchange will calculate the price according to the `x * y = k` curve.
Fees are collected against the currency in both buy and sell actions.
Due to this, `k` will steadily increase as a measure to collect rewards for the liquidity providers.
When liquidity is removed from the pools, as `k` has increased, their proportional share in the pool will have increased as well.

### Buy Tokens

Use this method to purchase tokens with currency.

This method is called with:

* The maximum amount of currency the caller is willing to spend when swapping
* The token type id they are swapping
* The exact amount of tokens the caller will receive when swapping
* A maximum timestamp which the transaction must be accepted by

See the above Swap section for information about the pricing curve.

Due to the fluctuations in price as swaps are made, the caller may not know the exact amount of currency that will be required to swap until the transaction is accepted. 
The caller instead supplies the maximum amount of currency they are willing to spend. This acts as a measure of slippage.

### Sell Tokens

Use this method to sell tokens for currency.

This method is called with:

* The minimum amount of currency the caller is willing to receive when swapping
* The token type id they are swapping
* The exact amount of tokens the caller will spend when swapping
* A maximum timestamp which the transaction must be accepted by

See the above Swap section for information about the pricing curve.

Due to the fluctuations in price as swaps are made, the caller may not know the exact amount of currency that will be required to swap until the transaction is accepted. 
The caller instead supplies the minimum amount of currency they are willing to receive. This acts as a measure of slippage.

### Get Buy / Sell Price

The `get_all_buy_price` and `get_all_sell_price` functions are read only functions used to get the current price according to the `x * y = k` curve, and take into consideration the exchange fee.

These methods are separated from the buy and sell methods so that they can be used for price display on frontends.

The liquidity provider fee is stored in the thousandths. e.g. A value of `15` would equate to a 1.5% fee on trades. Thus `1000` is used as a static value in these calculations.

---


## Misc Getters

There are additional getters for the following stored values:

* Currency contract address
* Token contract address
* Currency reserves (for the given token type id)
* LP fee (in thousandths)

The contract does not store a value for the ERC1155 token reserves and instead relies on the `balanceOf` ERC1155 function.

### LP ERC 1155 Compliance

There are additional method to support the ERC1155 compliance of LP tokens provided by this contract.

</details>

---


## Realms Repositories

The Realms Settling Game spans a number of repositories:

**[View the list of repositories in /README.md](/README.md#realms-repositories)**