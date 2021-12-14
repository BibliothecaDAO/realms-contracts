// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IJourney {
    function bridgeWithdraw(address _player, uint256[] memory _tokenIds)
        external;
}
