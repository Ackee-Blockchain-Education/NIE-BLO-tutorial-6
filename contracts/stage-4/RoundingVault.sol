// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

/// @title RoundingVault
contract RoundingVault {
    mapping(address => uint256) public shares;
    uint256 public totalShares;

    event Deposited(address indexed user, uint256 amount, uint256 sharesIssued);
    event Withdrawn(address indexed user, uint256 sharesBurned, uint256 amountOut);

    /// @notice Deposit ETH and receive shares
    function deposit() external payable {
        require(msg.value > 0, "zero deposit");

        uint256 sharesToIssue;

        if (totalShares == 0) {
            // First deposit: 1:1 ratio
            sharesToIssue = msg.value;
        } else {
            sharesToIssue = (msg.value * totalShares) / address(this).balance;
        }

        shares[msg.sender] += sharesToIssue;
        totalShares += sharesToIssue;

        emit Deposited(msg.sender, msg.value, sharesToIssue);
    }

    /// @notice Withdraw ETH by burning shares
    function withdraw(uint256 sharesToBurn) external {
        require(shares[msg.sender] >= sharesToBurn, "insufficient shares");
        require(totalShares > 0, "no shares");

        uint256 amountOut = (sharesToBurn / totalShares) * address(this).balance;

        shares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn;

        (bool success, ) = msg.sender.call{value: amountOut}("");
        require(success, "transfer failed");

        emit Withdrawn(msg.sender, sharesToBurn, amountOut);
    }

    /// @notice Get user's share balance
    function getShares(address user) external view returns (uint256) {
        return shares[user];
    }

    /// @notice Get total vault balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Calculate withdrawal amount
    function previewWithdraw(uint256 sharesToBurn) external view returns (uint256) {
        if (totalShares == 0) return 0;

        return (sharesToBurn * address(this).balance) / totalShares;
    }
}

