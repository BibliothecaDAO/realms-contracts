// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface LordsToken is IERC20 {
    function mint(address to, uint256 amount) external;

    function getAgeDistribution(uint256 _age) external view returns (uint256);
}
