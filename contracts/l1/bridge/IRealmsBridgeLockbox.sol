// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRealmsBridgeLockbox {
    function depositToL2(uint256 _l2AccountAddress, uint256[] memory _realmsId) external;
    function withdrawFromL2(address to, uint256[] memory _realmsId) external;
}