// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SRealmToken is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    address private stakingFacetAddress;
    IERC721 private realmsContract;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __ERC721_init("SRealmToken", "SREALM");
        __ERC721Burnable_init();
        __ERC721Enumerable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function setRealmsContract(address _newRealmsAddress) public onlyOwner {
        realmsContract = IERC721(_newRealmsAddress);
    }

    function changeDiamondAddress(address _newStakingFacetAddress) public {
        stakingFacetAddress = _newStakingFacetAddress;
    }

    // Minting
    function mintFromStakingContract(address _to, uint256 _tokenId) public {
        // require(msg.sender == stakingFacetAddress, "Not a staking facet");

        _safeMint(_to, _tokenId);
    }

    // Others
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
