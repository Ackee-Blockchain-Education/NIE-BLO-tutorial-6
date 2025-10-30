// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

/// @title SimpleBank
/// @notice Classic reentrancy vulnerability
contract SimpleBank {
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "deposit amount must be positive");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "insufficient balance");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "transfer failed");

        unchecked {
            balances[msg.sender] -= amount;
        }

        emit Withdraw(msg.sender, amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}