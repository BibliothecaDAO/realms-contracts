// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/finance/VestingWallet.sol";

contract Vesting is VestingWallet {
    // in UNIX days

    uint64 vestingTime;

    constructor(
        address _beneficiary,
        uint64 _start,
        uint64 _duration,
        uint64 _vestingTime
    ) VestingWallet(_beneficiary, _start, _duration) {
        vestingTime = _vestingTime;
    }

    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp)
        internal
        view
        virtual
        override(VestingWallet)
        returns (uint256)
    {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp > start() + duration()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start())) / duration();
        }
    }
}
