# $LORDS Bridge

These two contracts serve as the Ethereum <-> StarkNet $LORDS bridge. They are built in a minimal fashion, without any external dependencies, immutable, non-upgradable, non-cancellable. There is no support for message cancellation.

For the high level overview of how StarkNet L1L2 messaging works, consult the [official documentation](https://docs.starknet.io/documentation/architecture_and_concepts/L1-L2_Communication/messaging-mechanism/).

## L1 -> L2 bridging

When you want to bridge your $LORDS from Ethereum to StarkNet, you need to call the `deposit` function with the amount of tokens to be bridged and the StarkNet address to which the $LORDS will be added to. The bridge calls `transferFrom` so you'll also have to `approve` it beforehand.

Once the StarkNet sequencer processes the message, your L2 address will see the increased $LORDS balance. The L1 bridge acts as an escrow for the tokens, locking them in until (if ever) they are withdrawn from L2.

<pre>

                             ┌────────────────┐
                             │   L1 $LORDS    │
                             │     token      │
                             │    contract    │
                             └────────────────┘
                                      ▲
                                      │
                                      │
                                transferFrom
                                      │
  ┌─────────────┐             ┌───────┴───────┐
  │  Ethereum   │             │               │
  │   $LORDS    │────deposit─▶│ lords_l1.sol  │────┐
  │    owner    │             │               │    │
  └─────────────┘             └───────────────┘    │
                                                   │
                                            sendMessageToL2
                                                   │
                                                   │
                              ┌─────────────────┐  │
                              │                 │  │
                           ┌──│  StarkNet Core  │◀─┘
                           │  │                 │
                           │  └─────────────────┘
                           │
                           │
                    handle_deposit
                           │
                           │   ┌────────────────┐
                           │   │                │
                           └──▶│ lords_l2.cairo │
                               │                │
                               └────────────────┘
                                        │
                                       mint
                                        │
                                        ▼
                               ┌────────────────┐           ┌───────────┐
                               │   L2 $LORDS    │           │ StarkNet  │
                               │     token      ├──────────▶│  $LORDS   │
                               │    contract    │           │   owner   │
                               └────────────────┘           └───────────┘</pre>

## L2 -> L1 bridging

When moving $LORDS back from L2 to L1, call the `initiate_withdrawal` function with the L1 address and the amount of tokens to bridge back over to L1. After the sequencer processes the transaction and settles back to L1, you will be able to reclaim your L1 $LORDS by calling `withdraw` on the L1 bridge contract. Note that you have to call `withdraw` with the same values as supplied to `initiate_withdraw` on L2, otherwise the L1 transaction will fail.

<pre>
                                                   ┌────────────────┐
                                                   │   L2 $LORDS    │
                                                   │     token      │
                                                   │    contract    │
                                                   └────────────────┘
                                                            ▲
                                                            │
                                                        burnFrom
                                                            │
                                                            │
          ┌───────────┐                            ┌────────────────┐
          │ StarkNet  │                            │                │
          │  $LORDS   │────initiate_withdrawal────▶│ lords_l2.cairo │───┐
          │   owner   │                            │                │   │
          └───────────┘                            └────────────────┘   │
                                                                        │
                                                                        │
                                                                        │
                                                               send_message_to_l1
                                                                        │
                                                                        │
                                                   ┌─────────────────┐  │
                                                   │                 │  │
                                            ┌─────▶│  StarkNet Core  │◀─┘
                                            │      │                 │
                                            │      └─────────────────┘
                                            │
                                  consumeMessageFromL2
                                            │
                                            │
           ┌─────────┐              ┌───────────────┐
           │Ethereum │              │               │
           │   EOA   │──withdraw───▶│ lords_l1.sol  │────────┐
           │         │              │               │        │
           └─────────┘              └───────────────┘        │
                                                         transfer
                                                             │
                                                             ▼
                                                    ┌────────────────┐
                                                    │   L1 $LORDS    │
                                                    │     token      │
                                                    │    contract    │
                                                    └────────────────┘              </pre>
