// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRealmsL1Bridge {
    function depositToL2(uint256 _l2AccountAddress, uint256[] memory _realmsId, uint256 journeyVersion) external;
    function withdrawFromL2(address to, uint256[] memory _realmsId, uint256 journeyVersion) external;
}