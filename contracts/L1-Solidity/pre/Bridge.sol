// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../shared/interfaces/RealmsToken.sol";
import "../shared/interfaces/IJourney.sol";

contract Bridge {
    RealmsToken realmsToken;
    IJourney journey;

    address starkNetBridge;

    constructor(address _realms, address _journey) {
        realmsToken = RealmsToken(_realms);
        journey = IJourney(_journey);
    }

    function withdrawRealm(address _user, uint256[] memory _tokenIds) public {
        // require(msg.sender == starkNetBridge, "not starknet");
        journey.bridgeWithdraw(_user, _tokenIds);
    }
}
