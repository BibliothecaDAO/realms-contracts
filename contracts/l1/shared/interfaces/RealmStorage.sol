// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface RealmStorage is IERC721Receiver {
    function withdraw(uint256 _tokenId, address _lord) external;
}
