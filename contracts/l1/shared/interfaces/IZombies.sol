// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IZombies is IERC721 {
    function getTotalZombies() external view returns (uint256);

    function isZombie(uint256 _tokenId) external view returns (bool);

    function getTotalSpecies() external view returns (uint256);

    function getRatio() external view returns (uint256);
}
