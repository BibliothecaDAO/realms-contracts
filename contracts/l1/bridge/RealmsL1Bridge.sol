// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/IRealmsL1Bridge.sol";
import "./interfaces/IStarknetCore.sol";
import "./interfaces/IJourneyV1.sol";
import "./interfaces/IJourneyV2.sol";

contract RealmsL1Bridge is
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  IERC721Receiver,
  IRealmsL1Bridge
{
  IJourneyV1 public journeyV1Address;
  IJourneyV2 public journeyV2Address;

  // The StarkNet core contract.
  uint256 public l2BridgeAddress;
  IStarknetCore starknetCore;

  /* Starknet */
  // The selector of the "depositFromL1" @l1_handler at StarkNet contract
  uint256 private constant DEPOSIT_SELECTOR =
    512408049450392852989582095984328044240489742106100269794433337059943365139;

  function initialize() public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
  }

  function setL2BridgeAddress(uint256 _newAddress) external onlyOwner {
    l2BridgeAddress = _newAddress;
  }

  function setStarknetCore(address _starknetCoreAddress) external onlyOwner {
    starknetCore = IStarknetCore(_starknetCoreAddress);
  }

  function setJourneyV1Address(address _newAddress) external onlyOwner {
    journeyV1Address = IJourneyV1(_newAddress);
  }

  function setJourneyV2Address(address _newAddress) external onlyOwner {
    journeyV2Address = IJourneyV2(_newAddress);
  }

  /*
        @notice This claims your Realm in L2
    */
  function depositToL2(
    uint256 _l2AccountAddress,
    uint256[] memory _realmIds,
    uint256[] memory journeyVersions
  ) external payable nonReentrant {
    require(msg.value > 0, "FEE_NOT_PROVIDED");
    require(l2BridgeAddress != 0, "L2_CONTRACT_ADDRESS_REQUIRED");

    for (uint256 i = 0; i < _realmIds.length; i++) {
      if (journeyVersions[i] == 1) {
        address owner = journeyV1Address.checkOwner(_realmIds[i]);
        require(owner == msg.sender, "SENDER_NOT_REALM_OWNER");
      }

      if (journeyVersions[i] == 2) {
        address owner = journeyV2Address.ownership(_realmIds[i]);
        require(owner == msg.sender, "SENDER_NOT_REALM_OWNER");
      }
    }

    uint256[] memory payload = new uint256[](2 + (_realmIds.length * 3));
    payload[0] = _l2AccountAddress;
    payload[1] = _realmIds.length * 3; // multiplying because: 2 low/high values + 1 journey version

    for (uint256 i = 0; i < _realmIds.length; i++) {
      (uint256 low, uint256 high) = splitUint256(_realmIds[i]);
      payload[2 + (i * 2)] = low; // save low bits
      payload[2 + (i * 2) + 1] = high; // save high bits
      payload[2 + (i * 2) + 2] = journeyVersions[i];
    }

    // Send the message to the StarkNet core contract.
    starknetCore.sendMessageToL2{ value: msg.value }(
      l2BridgeAddress,
      DEPOSIT_SELECTOR,
      payload
    );
  }

  function withdrawFromL2(
    address _to,
    uint256[] memory _realmIds,
    uint256[] memory _journeyVersions
  ) public {
    require(l2BridgeAddress != 0, "L2_CONTRACT_ADDRESS_REQUIRED");

    // Construct the withdrawal message's payload.
    uint256[] memory payload = new uint256[](1 + (_realmIds.length * 2));

    // Address to send Realms to
    payload[0] = uint256(uint160(address(_to))); // TODO: needs to be tested

    for (uint256 i = 0; i < _realmIds.length; i++) {
      (uint256 low, uint256 high) = splitUint256(_realmIds[i]);
      payload[2 + (i * 2)] = low; // save low bits
      payload[2 + (i * 2) + 1] = high; // save high bits
      payload[2 + (i * 2) + 2] = _journeyVersions[i];
    }

    // Consume the message from the StarkNet core contract.
    // This will revert the (Ethereum) transaction if the message does not exist.
    starknetCore.consumeMessageFromL2(l2BridgeAddress, payload);

    for (uint256 i = 0; i < _realmIds.length; i++) {
      if (_journeyVersions[i] == 1) {
        journeyV1Address.bridgeWithdraw(_to, _realmIds);
      }

      if (_journeyVersions[i] == 2) {
        journeyV2Address.bridgeWithdraw(_to, _realmIds);
      }
    }
  }

  function splitUint256(uint256 value)
    internal
    pure
    returns (uint256, uint256)
  {
    uint256 low = value & ((1 << 128) - 1);
    uint256 high = value >> 128;
    return (low, high);
  }

  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes memory _data
  ) public override returns (bytes4) {
    return 0x150b7a02;
  }
}
