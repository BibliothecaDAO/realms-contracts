// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface SRealmsToken is IERC721Enumerable {
    function changeDiamondAddress(address _newDiamondAddress) external;

    function mintFromStakingContract(address to, uint256 tokenId) external;

    function burn(uint256 tokenId) external;
}
