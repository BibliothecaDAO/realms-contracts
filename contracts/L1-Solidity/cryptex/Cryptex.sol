pragma solidity ^0.8.2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// THE LORDS CRYPTEX //
/************************\
  | C   F   I   L   O   R  |
  | B   E   H   K   N   Q  |
  | A   D   G   J   M   P  |
  \************************/

contract Cryptex is Ownable, ERC721Holder {
    IERC721 public tokenContract;

    address public secretOracle;

    event KeyTurned(string _answer, address _traveler);
    bool isActive;

    string public correctKey;

    string[] private alphabet = [
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
        "g",
        "h",
        "i",
        "j",
        "k",
        "l",
        "m",
        "n",
        "o",
        "p",
        "q",
        "r",
        "s",
        "t",
        "u",
        "v",
        "w",
        "x",
        "y",
        "z"
    ];

    struct CryptexAnswer {
        uint256 a;
        uint256 b;
        uint256 c;
        uint256 d;
        uint256 e;
        uint256 f;
    }

    mapping(address => CryptexAnswer) answer;

    constructor(address _tokenContract, address _secretOracle) {
        tokenContract = IERC721(_tokenContract);
        secretOracle = _secretOracle;
    }

    function enterPassword(
        uint256 _turnA,
        uint256 _turnB,
        uint256 _turnC,
        uint256 _turnD,
        uint256 _turnE,
        uint256 _turnF
    ) external payable {
        CryptexAnswer storage answer = answer[_msgSender()];
        answer.a = _turnA;
        answer.b = _turnB;
        answer.c = _turnC;
        answer.d = _turnD;
        answer.e = _turnE;
        answer.f = _turnF;

        emit KeyTurned(
            string(
                abi.encodePacked(
                    alphabet[answer.a],
                    alphabet[answer.b],
                    alphabet[answer.c],
                    alphabet[answer.d],
                    alphabet[answer.e],
                    alphabet[answer.f]
                )
            ),
            _msgSender()
        );
    }

    function getAnswer(address _traveler) public view returns (string memory) {
        CryptexAnswer storage answer = answer[_msgSender()];

        return
            string(
                abi.encodePacked(
                    alphabet[answer.a],
                    alphabet[answer.b],
                    alphabet[answer.c],
                    alphabet[answer.d],
                    alphabet[answer.e],
                    alphabet[answer.f]
                )
            );
    }

    function isLocked(bool _value) external isSecretOracle {
        isActive = _value;
    }

    function sendLostToken(address _winner) external isSecretOracle {
        CryptexAnswer storage answer = answer[_winner];

        correctKey = string(
            abi.encodePacked(
                alphabet[answer.a],
                alphabet[answer.b],
                alphabet[answer.c],
                alphabet[answer.d],
                alphabet[answer.e],
                alphabet[answer.f]
            )
        );

        isActive == false;

        // tokenContract.transferFrom(address(this), _winner, _tokenId);
    }

    function checkWinner(address winner) public view returns (bool) {
        CryptexAnswer storage answer = answer[_msgSender()];

        return
            keccak256(
                abi.encodePacked(
                    alphabet[answer.a],
                    alphabet[answer.b],
                    alphabet[answer.c],
                    alphabet[answer.d],
                    alphabet[answer.e],
                    alphabet[answer.f]
                )
            ) == keccak256(abi.encodePacked(correctKey));
    }

    modifier isSecretOracle() {
        require(_msgSender() == secretOracle, "You are not the master. ");
        _;
    }

    modifier checkIsActive() {
        require(isActive == true, "Cryptex has been opened.");
        _;
    }

    function updateFromMaster(address _newMaster, address _newSecretOracle)
        external
        onlyOwner
    {
        transferOwnership(_newMaster);
        secretOracle = _newSecretOracle;
    }
}
