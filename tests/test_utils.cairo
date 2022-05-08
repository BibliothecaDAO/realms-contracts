%lang starknet

from src.utils import sum_func

@external
func test_sum{syscall_ptr : felt*, range_check_ptr}():
    let (r) = sum_func(4,3)
    assert r = 7
    return ()
end