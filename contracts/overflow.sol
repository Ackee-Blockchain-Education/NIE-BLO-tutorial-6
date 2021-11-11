pragma solidity >=0.4.20 <0.8.0;

contract Overflow {
  uint8 public lastBalance;
  uint8 public actualBalance;

  constructor() public {
    lastBalance = 0;
    actualBalance = 0;
  }

  function add(uint8 val) public returns (uint) {
    lastBalance = actualBalance;
    actualBalance += val;
    return actualBalance;
  }

}
