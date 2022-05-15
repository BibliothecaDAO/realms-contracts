// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IRealmsBridgeLockbox.sol";
import "./IStarknetCore.sol";
import "./IJourney.sol";

contract RealmsL1Bridge is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721Receiver,
    IRealmsBridgeLockbox
{
    IJourney public journeyV1Address;
    IJourney public journeyV2Address;

    // The StarkNet core contract.
    uint256 public l2BridgeAddress;
    IStarknetCore starknetCore;

    /* Starknet */
    // The selector of the "depositFromL1" @l1_handler at StarkNet contract
    uint256 constant private DEPOSIT_SELECTOR =
        512408049450392852989582095984328044240489742106100269794433337059943365139;

    function initialize(
        address _l1RealmsAddress,
        address _starknetCoreAddress
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        l1RealmsContract = IERC721(_l1RealmsAddress);
        starknetCore = IStarknetCore(_starknetCoreAddress);
    }

    function setL2BridgeAddress(uint256 _newAddress) external onlyOwner {
        l2BridgeAddress = _newAddress;
    }

    function setL1RealmsContract(address _newRealmsAddress) external onlyOwner {
        l1RealmsContract = IERC721(_newRealmsAddress);
    }

    function setStarknetCore(address _starknetCoreAddress) external onlyOwner {
        starknetCore = IStarknetCore(_starknetCoreAddress);
    }

    function setJourneyV1Address(address _newAddress) external onlyOwner {
        journeyV1Address = IJourney(_newAddress);
    }

    function setJourneyV2Address(address _newAddress) external onlyOwner {
        journeyV1Address = IJourney(_newAddress);
    }

    /*
        @notice This claims your Realm in L2
    */
    function depositToL2(
        uint256 _l2AccountAddress,
        uint256[] memory _realmIds,
        uint256 journeyVersion
    ) external nonReentrant {
        require(l2BridgeAddress != 0, "L2_CONTRACT_ADDRESS_REQUIRED");
        require(journeyVersion > 0 && journeyVersion <= 2, "INCORRECT_JOURNEY_VERSION");
        
        for (uint256 i = 0; i < _realmIds.length; i++) {
            // address owner = l1RealmsContract.ownerOf(_realmIds[i]);

            if (journeyVersion == 1) {
                address owner = journeyV1Address.checkOwner(_realmIds[i]);
                require(owner == msg.sender, "SENDER_NOT_REALM_OWNER");
            }

            // TODO: l1RealmsContract.setApprovalForAll ???
            // l1RealmsContract.safeTransferFrom(owner, address(this), _realmIds[i]);
        }

        uint256[] memory payload = new uint256[](3 + (_realmIds.length * 2));
        // payload[0] = uint256(uint160(address(msg.sender))); // address should be converted to uint256 first
        payload[0] = _l2AccountAddress;
        payload[1] = journeyVersion;
        payload[2] = _realmIds.length * 2; // multiplying because there are low/high values for each uint256
        for (uint256 i = 0; i < _realmIds.length; i++) {
          (uint256 low, uint256 high) = splitUint256(_realmIds[i]);
          payload[3 + (i * 2)] = low; // save low bits
          payload[3 + (i * 2) + 1] = high; // save high bits
        }

        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(l2BridgeAddress, DEPOSIT_SELECTOR, payload);
    }

    function withdrawFromL2(
        address _to,
        uint256[] memory _realmIds,
        uint256 journeyVersion
    ) public override {
        require(l2BridgeAddress != 0, "L2_CONTRACT_ADDRESS_REQUIRED");
        
        // Construct the withdrawal message's payload.
        uint256[] memory payload = new uint256[](1 + (_realmIds.length * 2));

        payload[0] = uint256(uint160(address(_to))); // TODO: needs to be tested 
        
        for (uint256 i = 0; i < _realmIds.length; i++) {
          (uint256 low, uint256 high) = splitUint256(_realmIds[i]);
          payload[1 + (i * 2)] = low; // save low bits
          payload[1 + (i * 2) + 1] = high; // save high bits
        }

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2BridgeAddress, payload);

        for (uint256 i = 0; i < _realmIds.length; i++) {
            if (journeyVersion == 1) {
                journeyV1Address.bridgeWithdraw(_to, _realmIds);
            }

            // TODO: V2?
        }
    }

    function splitUint256(uint256 value) internal pure returns (uint256, uint256) {
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