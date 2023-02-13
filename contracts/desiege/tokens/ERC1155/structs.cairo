%lang starknet

struct BlockchainNamespace {
    a: felt,
}

// ChainID. Chain Agnostic specifies that the length can go up to 32 nines (i.e. 9999999....) but we will only support 31 nines.
struct BlockchainReference {
    a: felt,
}

struct AssetNamespace {
    a: felt,
}

// Contract Address on L1. An address is represented using 20 bytes. Those bytes are written in the `felt`.
struct AssetReference {
    a: felt,
}

// ERC1155 returns the same URI for all token types.
// TokenId will be represented by the substring '{id}' and so stored in a felt
// Client calling the function must replace the '{id}' substring with the actual token type ID
struct TokenId {
    a: felt,
}

// As defined by Chain Agnostics (CAIP-29 and CAIP-19):
// {blockchain_namespace}:{blockchain_reference}/{asset_namespace}:{asset_reference}/{token_id}
// tokenId will be represented by the substring '{id}'
struct TokenUri {
    blockchain_namespace: BlockchainNamespace,
    blockchain_reference: BlockchainReference,
    asset_namespace: AssetNamespace,
    asset_reference: AssetReference,
    token_id: TokenId,
}
