// SPDX-License-Identifier: None

pragma solidity ^0.8.20;

contract Foo {
    uint8 public lastBalance;
    uint8 public actualBalance;

    constructor() {
        lastBalance = 1;
        actualBalance = 1;
    }

    function add(uint8 val) external returns (uint) {
        unchecked {
            lastBalance = actualBalance;
            actualBalance += val;
            return actualBalance;
        }
    }
}