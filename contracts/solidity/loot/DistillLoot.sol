// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./ILoot.sol";

interface StarkNetLike {
    function sendMessageToL2(
        uint256 to,
        uint256 selector,
        uint256[] calldata payload
    ) external;

    function consumeMessageFromL2(uint256 from, uint256[] calldata payload)
        external;
}

contract DistillLoot {
    ILoot iLoot;
    address public starkNet;
    address public distilationStarkNet;

    uint256 distilFunction =
        1285101517810983806491589552491143496277809242732141897358598292095611420389; // dummy

    constructor(
        address _loot,
        address _starkNet,
        address _distilationStarkNet
    ) {
        iLoot = ILoot(_loot);
        starkNet = _starkNet;
        distilationStarkNet = _distilationStarkNet;
    }

    function distilBag(uint256 _tokenId) external {
        // pluck items
        // bag id
        // item location id
        // greatness
    }

    function getItemGreatness(
        uint256 _tokenId,
        string memory _prefix,
        uint256 _length
    ) public {}
}
