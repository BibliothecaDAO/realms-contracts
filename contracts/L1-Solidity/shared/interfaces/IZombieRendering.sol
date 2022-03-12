// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./ZombiesTypes.sol";

interface IZombieRendering {
    function tokenURI(uint256 tokenId, ZombiesTypes.Species memory zombies)
        external
        view
        returns (string memory);
}
