// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Journey is ERC721Holder, Ownable, ReentrancyGuard, Pausable {
    event StakeRealms(uint256[] tokenIds, address player);
    event UnStakeRealms(uint256[] tokenIds, address player);

    mapping(address => uint256) epochClaimed;
    mapping(uint256 => address) ownership;
    mapping(address => mapping(uint256 => uint256)) public realmsStaked;

    IERC20 lordsToken;
    IERC721 realmsToken;

    // contracts
    address bridge;

    // consts
    uint256 lordsPerRealm;
    uint256 genesis;
    uint256 epoch;
    uint256 finalAge;

    constructor(
        uint256 _lordsPerRealm,
        uint256 _epoch,
        address _realmsAddress,
        address _lordsToken
    ) {
        genesis = block.timestamp;
        lordsPerRealm = _lordsPerRealm;
        epoch = _epoch;

        lordsToken = IERC20(_lordsToken);
        realmsToken = IERC721(_realmsAddress);
    }

    /**
     * @notice Set's Lords Issuance in gwei per staked realm
     */
    function lordsIssuance(uint256 _new) external onlyOwner {
        lordsPerRealm = _new * 10**18; // converted into decimals
    }

    function updateRealmsAddress(address _newRealms) external onlyOwner {
        realmsToken = IERC721(_newRealms);
    }

    function updateLordsAddress(address _newLords) external onlyOwner {
        lordsToken = IERC20(_newLords);
    }

    function updateEpochLength(uint256 _newEpoch) external onlyOwner {
        epoch = _newEpoch;
    }

    function setBridge(address _newBridge) external onlyOwner {
        bridge = _newBridge;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setFinalAge(uint256 _finalAge) external onlyOwner {
        finalAge = _finalAge;
    }

    /**
     * @notice Set's epoch to epoch * 1 hour.
     */
    function _epochNum() internal view returns (uint256) {
        if (finalAge != 0) {
            return finalAge;
        } else {
            return (block.timestamp - genesis) / (epoch * 3600); // hours
        }
        // return 5;
    }

    /**
     * @notice Boards the Ship (Stakes). Sets ownership of Token to Staker. Transfers NFT to Contract. Set's epoch date, Set's number of Realms staked in the Epoch.
     * @param _tokenIds Ids of Realms
     */
    function boardShip(uint256[] memory _tokenIds)
        external
        whenNotPaused
        nonReentrant
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                realmsToken.ownerOf(_tokenIds[i]) == msg.sender,
                "NOT_OWNER"
            );
            ownership[_tokenIds[i]] = msg.sender;

            realmsToken.safeTransferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );
        }

        if (getNumberRealms(msg.sender) == 0) {
            epochClaimed[msg.sender] = _epochNum();
        }

        realmsStaked[msg.sender][_epochNum()] += uint256(_tokenIds.length);

        emit StakeRealms(_tokenIds, msg.sender);
    }

    function exitShip(uint256[] memory _tokenIds)
        external
        whenNotPaused
        nonReentrant
    {
        _exitShip(_tokenIds);
    }

    /**
     * @notice Exits Ship, and transfers all Realms back to owner. Claims any lords available.
     * @param _tokenIds Ids of Realms
     */
    function _exitShip(uint256[] memory _tokenIds) internal {
        if (lordsAvailable(msg.sender) != 0) {
            _claimLords();
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(ownership[_tokenIds[i]] == msg.sender, "NOT_OWNER");

            ownership[_tokenIds[i]] = address(0);

            realmsToken.safeTransferFrom(
                address(this),
                msg.sender,
                _tokenIds[i]
            );
        }

        // remove last in first
        if (_epochNum() == 0) {
            realmsStaked[msg.sender][_epochNum()] -= _tokenIds.length;
        } else {
            uint256 realmsInPrevious = realmsStaked[msg.sender][
                _epochNum() - 1
            ];
            uint256 realmsInCurrent = realmsStaked[msg.sender][_epochNum()];

            if (realmsInPrevious > _tokenIds.length) {
                realmsStaked[msg.sender][_epochNum() - 1] -= _tokenIds.length;
            } else if (realmsInCurrent == _tokenIds.length) {
                realmsStaked[msg.sender][_epochNum()] -= _tokenIds.length;
            } else if (realmsInPrevious <= _tokenIds.length) {
                // remove oldest first
                uint256 oldestFirst = (_tokenIds.length - realmsInPrevious);

                realmsStaked[msg.sender][_epochNum() - 1] -= (_tokenIds.length -
                    oldestFirst);

                realmsStaked[msg.sender][_epochNum()] -= oldestFirst;
            }
        }

        emit UnStakeRealms(_tokenIds, msg.sender);
    }

    /**
     * @notice Claims all available Lords for Owner.
     */
    function claimLords() external whenNotPaused nonReentrant {
        _claimLords();
    }

    function _claimLords() internal {
        uint256 totalClaimable;
        uint256 totalRealms;

        require(_epochNum() > 1, "GENESIS_epochNum");

        // loop over epochs, sum up total claimable staked lords per epoch
        for (uint256 i = epochClaimed[msg.sender]; i < _epochNum(); i++) {
            totalRealms += realmsStaked[msg.sender][i];
            totalClaimable +=
                realmsStaked[msg.sender][i] *
                ((_epochNum() - 1) - i);
        }

        // set totalRealms staked in latest epoch - 1 so loop doesn't have to iterate again
        realmsStaked[msg.sender][_epochNum() - 1] = totalRealms;

        // set epoch claimed to current - 1
        epochClaimed[msg.sender] = _epochNum() - 1;

        require(totalClaimable > 0, "NOTHING_TO_CLAIM");

        // available lords * total realms staked per period
        uint256 lords = lordsPerRealm * totalClaimable;

        lordsToken.approve(address(this), lords);

        lordsToken.transferFrom(address(this), msg.sender, lords);
    }

    /**
     * @notice Lords available for the player.
     */
    function lordsAvailable(address _player)
        public
        view
        returns (uint256 lords)
    {
        uint256 totalClaimable;
        if (_epochNum() > 1) {
            for (uint256 i = epochClaimed[_player]; i < _epochNum(); i++) {
                totalClaimable +=
                    realmsStaked[_player][i] *
                    ((_epochNum() - 1) - i);
            }

            lords = lordsPerRealm * totalClaimable;
        } else {
            lords = 0;
        }
    }

    /**
     * @notice Called only by future Bridge contract to withdraw the Realms
     * @param _tokenIds Ids of Realms
     */
    function bridgeWithdraw(address _player, uint256[] memory _tokenIds)
        public
        onlyBridge
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            ownership[_tokenIds[i]] = address(0);

            realmsToken.safeTransferFrom(address(this), _player, _tokenIds[i]);
        }

        emit UnStakeRealms(_tokenIds, _player);
    }

    function withdrawAllLords(address _destination) public onlyOwner {
        uint256 balance = lordsToken.balanceOf(address(this));

        lordsToken.approve(address(this), balance);
        lordsToken.transferFrom(address(this), _destination, balance);
    }

    modifier onlyBridge() {
        require(msg.sender == bridge, "NOT_THE_BRIDGE");
        _;
    }

    function checkOwner(uint256 _tokenId) public view returns (address) {
        return ownership[_tokenId];
    }

    function getEpoch() public view returns (uint256) {
        return _epochNum();
    }

    function getLordsAddress() public view returns (address) {
        return address(lordsToken);
    }

    function getRealmsAddress() public view returns (address) {
        return address(realmsToken);
    }

    function getEpochLength() public view returns (uint256) {
        return epoch;
    }

    function getLordsIssurance() public view returns (uint256) {
        return lordsPerRealm;
    }

    function getTimeUntilEpoch() public view returns (uint256) {
        return (epoch * 3600 * (getEpoch() + 1)) - (block.timestamp - genesis);
    }

    function getFinalAge() public view returns (uint256) {
        return finalAge;
    }

    function getNumberRealms(address _player) public view returns (uint256) {
        uint256 totalRealms;

        if (_epochNum() >= 1) {
            for (uint256 i = epochClaimed[_player]; i <= _epochNum(); i++) {
                totalRealms += realmsStaked[_player][i];
            }
            return totalRealms;
        } else {
            return realmsStaked[_player][0];
        }
    }
}
