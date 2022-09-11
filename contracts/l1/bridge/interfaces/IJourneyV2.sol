// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJourneyV2 {
  function ownership(uint256 _tokenId) external returns (address);

  function bridgeWithdraw(address _player, uint256[] memory _tokenIds) external;
}
