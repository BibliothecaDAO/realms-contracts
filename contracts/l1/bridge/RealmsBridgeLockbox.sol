// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IRealmsBridgeLockbox.sol";
import "./IStarknetCore.sol";

contract RealmsBridgeLockbox is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721Receiver,
    IRealmsBridgeLockbox
{
    IERC721 public realmsContract;
    address public l2ContractAddress;
    // The StarkNet core contract.
    IStarknetCore starknetCore;

    /* Starknet */

    uint256 constant MESSAGE_WITHDRAW = 0;

    // The selector of the "depositFromL1" @l1_handler at StarkNet contract
    uint256 constant DEPOSIT_SELECTOR =
        512408049450392852989582095984328044240489742106100269794433337059943365139;

    // Loot ID to Ticket ID
    // mapping(uint256 => uint256) public realmsToTickets;
    mapping(uint256 => address) public tokensToOwners;

    function initialize(
        address _realmsAddress,
        address _l2ContractAddress,
        address _starknetCoreAddress
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        realmsContract = IERC721(_realmsAddress);
        l2ContractAddress = _l2ContractAddress;
        starknetCore = IStarknetCore(_starknetCoreAddress);
    }

    function setL2ContractAddress(address _newL2ContractAddress) external onlyOwner {
        l2ContractAddress = _newL2ContractAddress;
    }

    function setRealmsContract(address _newRealmsAddress) external onlyOwner {
        realmsContract = IERC721(_newRealmsAddress);
    }

    function setStarknetCore(address _starknetCoreAddress) external onlyOwner {
        starknetCore = IStarknetCore(_starknetCoreAddress);
    }

    /*
        @notice This claims your Realm in L2
    */
    function depositToL2(
        uint256[] _realmIds
    ) external payable nonReentrant returns (uint256) {
        require(l2ContractAddress != address(0x0), "L2_CONTRACT_ADDRESS_REQUIRED");
        // require(msg.value > 0, "MSG_VALUE_IS_REQUIRED");
        
        for (uint256 i = 0; i < _realmIds.length; i++) {
          require(realmsContract.ownerOf(_realmIds[i]) == msg.sender, "SENDER_NOT_REALM_OWNER");
        }

        // realmsContract.safeTransferFrom(msg.sender, address(this), _realmId);
        // tokensToOwners[_realmId] = msg.sender;

        uint256[] memory payload = new uint256[](2 + (_realmIds.length * 2));
        payload[0] = msg.sender;
        payload[1] = _realmIds.length * 2; // multiplying because there are low/high values for each uint256
        for (uint256 i = 0; i < _realmIds.length; i++) {
          (low, high) = splitUint256(_realmIds[i]);
          payload[2 + (i * 2)] = low; // save low bits
          payload[2 + (i * 2) + 1] = high; // save high bits
        }

        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(l2ContractAddress, DEPOSIT_SELECTOR, payload);
    }

    function withdrawFromL2(uint256 _realmId) public override {
        IOutbox outbox = IOutbox(inbox.bridge().activeOutbox());
        address l2Sender = outbox.l2ToL1Sender();
        require(l2Sender == l2Target, "Only L2");

        // Construct the withdrawal message's payload.
        uint256[] memory payload = new uint256[](3);
        payload[0] = MESSAGE_WITHDRAW;
        payload[1] = user;
        payload[2] = amount;

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2ContractAddress, payload);

        // Update the L1 balance.
        userBalances[user] += amount;

        address _to = tokensToOwners[_realmId];
        realmsContract.safeTransferFrom(address(this), _to, _realmId);
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