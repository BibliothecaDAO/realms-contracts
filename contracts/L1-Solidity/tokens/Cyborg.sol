// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts@4.4.2/token/ERC20/ERC20.sol";

contract CryptoCyborgs is ERC20 {
    constructor() ERC20("Crypto Cyborgs", "CYBORG") {
        _mint(msg.sender, 1000000000000000 * 10 ** decimals());
    }
}
