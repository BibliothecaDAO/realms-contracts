// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRealmsBridgeLockbox {
    function depositToL2(uint256[] memory _realmsId, uint256 _l2AccountAddress) external;
    // function withdrawFromL2(uint256 _realmsId) external;
}