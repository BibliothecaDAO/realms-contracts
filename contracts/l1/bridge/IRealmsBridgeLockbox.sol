// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRealmsBridgeLockbox {
    function depositToL2(uint256 _realmsId) external;
    function withdrawFromL2(uint256 _realmsId) external;
}