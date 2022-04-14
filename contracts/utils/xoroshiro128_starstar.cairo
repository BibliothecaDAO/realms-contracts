%lang starknet

from starkware.cairo.common.bitwise import ALL_ONES, bitwise_and, bitwise_or, bitwise_xor
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.math import assert_le, split_felt, unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_mul,
    uint256_xor,
    uint256_shr,
)

struct State:
    member s0 : felt
    member s1 : felt
end

@storage_var
func state() -> (s : State):
end

@constructor
func constructor{
    syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(seed : felt):
    alloc_locals
    let (s0) = splitmix64(seed)
    let (s1) = splitmix64(s0)
    let s = State(s0=s0, s1=s1)

    state.write(s)
    return ()
end

@external
func next{
    syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> (rnd : felt):
    alloc_locals

    let (s) = state.read()

    # result = rotl(s0 * 5, 7) * 9;
    let (rotated) = rotl(s.s0 * 5, 7)
    let (result) = and64(rotated * 9)

    # s1 ^= s0;
    # s[0] = rotl(s0, 24) ^ s1 ^ (s1 << 16)
    # s[1] = rotl(s1, 37); // c

    let (s1_xor) = bitwise_xor(s.s1, s.s0)  # s1 ^= s0
    let (s1_xor_64) = and64(s1_xor)
    let (s0_rotated) = rotl(s.s0, 24)  # rotl(s0, 24)
    let s1_shifted = s1_xor_64 * 65536  # s1 << 16
    let (xor_1) = bitwise_xor(s0_rotated, s1_xor_64)
    let (s0_xor) = bitwise_xor(xor_1, s1_shifted)
    let (s0) = and64(s0_xor)
    let (s1) = rotl(s1_xor_64, 37)

    let new_s : State = State(s0=s0, s1=s1)
    state.write(new_s)

    return (result)
end

# calculates (x << k) | (x >> (64 - k))
func rotl{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(x : felt, k : felt) -> (out : felt):
    alloc_locals
    assert_le(k, 64)

    let (k_shift) = pow2(k)
    tempvar left = x * k_shift
    let (right) = rshift(x, 64 - k)

    let (res) = bitwise_or(left, right)
    return (res)
end

const U64 = 0xffffffffffffffff  # 2**64-1

# https://xoshiro.di.unimi.it/splitmix64.c
# uint64_t z = (x += 0x9e3779b97f4a7c15);
# z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9;
# z = (z ^ (z >> 27)) * 0x94d049bb133111eb;
# return z ^ (z >> 31);
func splitmix64{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(x : felt) -> (z : felt):
    alloc_locals

    let t1 = x + 0x9e3779b97f4a7c15
    let (t1_64) = and64(t1)
    let (t1_shift30) = rshift(t1_64, 30)
    let (t1_xor) = bitwise_xor(t1_64, t1_shift30)
    let (t1_xor_64) = and64(t1_xor)

    let t2 = t1_xor_64 * 0xbf58476d1ce4e5b9
    let (t2_64) = and64(t2)
    let (t2_shift27) = rshift(t2_64, 27)
    let (t2_xor) = bitwise_xor(t2_64, t2_shift27)
    let (t2_xor_64) = and64(t2_xor)

    let t3 = t2_xor_64 * 0x94d049bb133111eb
    let (t3_64) = and64(t3)
    let (t3_shift31) = rshift(t3_64, 31)
    let (t3_xor) = bitwise_xor(t3_64, t3_shift31)
    let (z) = and64(t3_xor)

    return (z)
end

func and64{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(n : felt) -> (u : felt):
    let (u) = bitwise_and(n, U64)
    return (u)
end

# in Starknet, the "standard" method of rshifting by using unsigned_div_rem
# doesn't work on values greater than 2**128; this function overcomes that limitation
# however the max shift value of `b` is 123
func rshift{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(v : felt, b : felt) -> (out : felt):
    alloc_locals
    # assert_le(b, 123) # commented out to save computation steps, assert is not necessary in this contract

    let (high, low) = split_felt(v)
    let (shift) = pow2(b)
    let (low_shifted, _) = unsigned_div_rem(low, shift)

    let (high_q, high_r) = unsigned_div_rem(high, shift)
    let (bump) = pow2(128 - b)
    tempvar out = high_q * 0x100000000000000000000000000000000 + high_r * bump + low_shifted
    return (out)
end

# taken from Warp's src
# https://github.com/NethermindEth/warp/blob/develop/src/warp/cairo-src/evm/pow2.cairo
func pow2(i : felt) -> (res : felt):
    let (data_address) = get_label_location(data)
    return ([data_address + i])

    data:
    dw 1
    dw 2
    dw 4
    dw 8
    dw 16
    dw 32
    dw 64
    dw 128
    dw 256
    dw 512
    dw 1024
    dw 2048
    dw 4096
    dw 8192
    dw 16384
    dw 32768
    dw 65536
    dw 131072
    dw 262144
    dw 524288
    dw 1048576
    dw 2097152
    dw 4194304
    dw 8388608
    dw 16777216
    dw 33554432
    dw 67108864
    dw 134217728
    dw 268435456
    dw 536870912
    dw 1073741824
    dw 2147483648
    dw 4294967296
    dw 8589934592
    dw 17179869184
    dw 34359738368
    dw 68719476736
    dw 137438953472
    dw 274877906944
    dw 549755813888
    dw 1099511627776
    dw 2199023255552
    dw 4398046511104
    dw 8796093022208
    dw 17592186044416
    dw 35184372088832
    dw 70368744177664
    dw 140737488355328
    dw 281474976710656
    dw 562949953421312
    dw 1125899906842624
    dw 2251799813685248
    dw 4503599627370496
    dw 9007199254740992
    dw 18014398509481984
    dw 36028797018963968
    dw 72057594037927936
    dw 144115188075855872
    dw 288230376151711744
    dw 576460752303423488
    dw 1152921504606846976
    dw 2305843009213693952
    dw 4611686018427387904
    dw 9223372036854775808
    dw 18446744073709551616
    dw 36893488147419103232
    dw 73786976294838206464
    dw 147573952589676412928
    dw 295147905179352825856
    dw 590295810358705651712
    dw 1180591620717411303424
    dw 2361183241434822606848
    dw 4722366482869645213696
    dw 9444732965739290427392
    dw 18889465931478580854784
    dw 37778931862957161709568
    dw 75557863725914323419136
    dw 151115727451828646838272
    dw 302231454903657293676544
    dw 604462909807314587353088
    dw 1208925819614629174706176
    dw 2417851639229258349412352
    dw 4835703278458516698824704
    dw 9671406556917033397649408
    dw 19342813113834066795298816
    dw 38685626227668133590597632
    dw 77371252455336267181195264
    dw 154742504910672534362390528
    dw 309485009821345068724781056
    dw 618970019642690137449562112
    dw 1237940039285380274899124224
    dw 2475880078570760549798248448
    dw 4951760157141521099596496896
    dw 9903520314283042199192993792
    dw 19807040628566084398385987584
    dw 39614081257132168796771975168
    dw 79228162514264337593543950336
    dw 158456325028528675187087900672
    dw 316912650057057350374175801344
    dw 633825300114114700748351602688
    dw 1267650600228229401496703205376
    dw 2535301200456458802993406410752
    dw 5070602400912917605986812821504
    dw 10141204801825835211973625643008
    dw 20282409603651670423947251286016
    dw 40564819207303340847894502572032
    dw 81129638414606681695789005144064
    dw 162259276829213363391578010288128
    dw 324518553658426726783156020576256
    dw 649037107316853453566312041152512
    dw 1298074214633706907132624082305024
    dw 2596148429267413814265248164610048
    dw 5192296858534827628530496329220096
    dw 10384593717069655257060992658440192
    dw 20769187434139310514121985316880384
    dw 41538374868278621028243970633760768
    dw 83076749736557242056487941267521536
    dw 166153499473114484112975882535043072
    dw 332306998946228968225951765070086144
    dw 664613997892457936451903530140172288
    dw 1329227995784915872903807060280344576
    dw 2658455991569831745807614120560689152
    dw 5316911983139663491615228241121378304
    dw 10633823966279326983230456482242756608
    dw 21267647932558653966460912964485513216
    dw 42535295865117307932921825928971026432
    dw 85070591730234615865843651857942052864
    dw 170141183460469231731687303715884105728
    dw 340282366920938463463374607431768211456
end
