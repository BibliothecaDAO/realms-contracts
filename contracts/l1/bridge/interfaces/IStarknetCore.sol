pragma solidity ^0.8.0;

interface IStarknetCore {
  /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
  function sendMessageToL2(
    uint256 toAddress,
    uint256 selector,
    uint256[] calldata payload
  ) external payable returns (bytes32);

  /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
  function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload)
    external
    returns (bytes32);
}
