// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @title Realms contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract LootRealms is ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    string public PROVENANCE = "";
    uint256 public lootersPrice = 30000000000000000; //0.03 ETH
    uint256 public publicPrice = 150000000000000000; //0.15 ETH
    bool public saleIsActive = true;
    bool public privateSale = false;

    // URI
    string public baseURI;

    constructor() ERC721("Testnet Realms (for Adventurers)", "LootRealmTest") {}

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function deposit() public payable onlyOwner {}

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function endPrivateSale() public onlyOwner {
        require(privateSale);
        privateSale = false;
    }

    function setLootersPrice(uint256 newPrice) public onlyOwner {
        lootersPrice = newPrice;
    }

    function setPublicPrice(uint256 newPrice) public onlyOwner {
        publicPrice = newPrice;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setProvenance(string memory prov) public onlyOwner {
        PROVENANCE = prov;
    }

    //Public sale minting
    function mint(uint256 lootId) public payable nonReentrant {
        _safeMint(msg.sender, lootId);
    }
}
