// Interface for the Xoroshiro PRNG
//   Xoroshiro pseudo random number generator interface
//
// MIT License

%lang starknet

@contract_interface
namespace IXoroshiro {
    func next() -> (rnd: felt) {
    }
}
