// SPDX-License-Identifier: None

pragma solidity =0.7.6;

contract Overflow {
    uint8 public lastBalance;
    uint8 public actualBalance;

    constructor() {
        lastBalance = 1;
        actualBalance = 1;
    }

    function add(uint8 val) external returns (uint) {
        lastBalance = actualBalance;
        actualBalance += val;
        return actualBalance;
    }
}
