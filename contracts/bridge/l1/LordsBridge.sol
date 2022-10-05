// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStarknetCore.sol";

contract LordsBridge is
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  IRealmsL1Bridge
{
  // $LORDS contract
  address public lordsAddress;

  // Our L2 Bridge address
  uint256 public l2BridgeAddress;

  // Balances
  mapping(address => uint256) public balances;

  /* Starknet */
  IStarknetCore starknetCore;
  // The selector of the "depositFromL1" @l1_handler at StarkNet contract
  uint256 private constant DEPOSIT_SELECTOR =
    512408049450392852989582095984328044240489742106100269794433337059943365139;

  function initialize() public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
  }

  function setLordsAddress(uint256 _newAddress) external onlyOwner {
    lordsAddress = _newAddress;
  }

  function setL2BridgeAddress(uint256 _newAddress) external onlyOwner {
    l2BridgeAddress = _newAddress;
  }

  function setStarknetCore(address _starknetCoreAddress) external onlyOwner {
    starknetCore = IStarknetCore(_starknetCoreAddress);
  }

  /*
        @notice This claims your Realm in L2
    */
  function depositToL2(uint256 _l2AccountAddress, uint256 _amount)
    external
    payable
    nonReentrant
  {
    require(msg.value > 0, "FEE_NOT_PROVIDED");
    require(l2BridgeAddress != 0, "L2_CONTRACT_ADDRESS_REQUIRED");

    IERC20(lordsAddress).transferFrom(msg.sender, address(this), _amount);

    balances[msg.sender] += _amount;

    uint256[] memory payload = new uint256[](2);
    payload[0] = _l2AccountAddress;
    payload[1] = _amount;

    // Send the message to the StarkNet core contract.
    starknetCore.sendMessageToL2{ value: msg.value }(
      l2BridgeAddress,
      DEPOSIT_SELECTOR,
      payload
    );
  }

  function withdrawFromL2(address _to, uint256 _amount) public {
    require(l2BridgeAddress != 0, "L2_CONTRACT_ADDRESS_REQUIRED");

    // Construct the withdrawal message's payload.
    uint256[] memory payload = new uint256[](2);

    // Address to send Realms to
    payload[0] = uint256(uint160(address(_to))); // TODO: needs to be tested
    payload[1] = _amount;

    // Consume the message from the StarkNet core contract.
    // This will revert the (Ethereum) transaction if the message does not exist.
    starknetCore.consumeMessageFromL2(l2BridgeAddress, payload);

    IERC20(lordsAddress).transferFrom(address(this), msg.sender, _amount);
  }
}
