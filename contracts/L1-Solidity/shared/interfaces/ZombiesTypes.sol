// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ZombiesTypes {
    struct Species {
        uint256 dna;
        uint128 deaths;
        uint128 confidence;
        bool zombie;
    }
}
