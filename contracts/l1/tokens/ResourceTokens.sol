// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./ERC1155PackedBalance/ERC1155MintBurnPackedBalance.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ResourceTokens is ERC1155MintBurnPackedBalance, Ownable {
    // Resources
    uint256 public constant WOOD = 1;
    uint256 public constant STONE = 2;
    uint256 public constant COAL = 3;
    uint256 public constant COPPER = 4;
    uint256 public constant OBSIDIAN = 5;
    uint256 public constant SILVER = 6;
    uint256 public constant IRONWOOD = 7;
    uint256 public constant COLD_IRON = 8;
    uint256 public constant GOLD = 9;
    uint256 public constant HARTWOOD = 10;
    uint256 public constant DIAMONDS = 11;
    uint256 public constant SAPPHIRE = 12;
    uint256 public constant DEEP_CRYSTAL = 13;
    uint256 public constant RUBY = 14;
    uint256 public constant IGNIUM = 15;
    uint256 public constant ETHEREAL_SILICA = 16;
    uint256 public constant TRUE_ICE = 17;
    uint256 public constant TWILIGHT_QUARTZ = 18;
    uint256 public constant ALCHEMICAL_SILVER = 19;
    uint256 public constant ADAMANTINE = 20;
    uint256 public constant MITHRAL = 21;
    uint256 public constant DRAGONHIDE = 22;

    address public treasury;
    address public diamond;
    uint256 public tax;

    constructor(
        address _treasury,
        address _diamond,
        uint256 _tax
    ) {
        treasury = _treasury;
        diamond = _diamond;
        tax = _tax;
    }

    function batchResourceMinting(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public checkIfOwnerOrDiamond {
        _batchMint(_to, _ids, _amounts, _data);

        uint256[] memory _treasuryAmount = new uint256[](22);

        for (uint256 i = 0; i < _amounts.length; i++) {
            _treasuryAmount[i] = (_amounts[i] * tax) / 10;
        }

        _batchMint(treasury, _ids, _amounts, _data);
    }

    function resourceMinting(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public checkIfOwnerOrDiamond {
        _batchMint(_to, _ids, _amounts, _data);
        _batchMint(treasury, _ids, _amounts, _data);
    }

    function batchBurnResources(
        address _from,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) public {
        _batchBurn(_from, _ids, _amounts);
    }

    function changeDiamondAddress(address _newDiamond) public onlyOwner {
        diamond = _newDiamond;
    }

    function changeTreasuryAddress(address _newTreasury) public onlyOwner {
        treasury = _newTreasury;
    }

    function changeTax(uint256 _newTax) public onlyOwner {
        tax = _newTax;
    }

    modifier checkIfOwnerOrDiamond() {
        require(
            msg.sender == owner() || msg.sender == diamond,
            "NOT THE DIAMOND"
        );
        _;
    }

    function daoMinting(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public onlyOwner {
        _batchMint(_to, _ids, _amounts, _data);
    }
}
