// SPDX-License-Identifier: None
pragma solidity 0.8.20;

import "./Token.sol";

contract Vault {
    CCRToken public customToken;
    address public owner;
    uint256 private _status;

    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    constructor() {
        owner = msg.sender;
        _status = NOT_ENTERED;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier nonReentrant() {
        require(_status != ENTERED, "ReentrancyGuard: reentrant call");
        _status = ENTERED;
        _;
        _status = NOT_ENTERED;
    }

    function setToken(address _customToken) external onlyOwner {
        customToken = CCRToken(_customToken);
    }

    function deposit() external payable nonReentrant {
        customToken.mint(msg.sender, msg.value); // ETH to CCRT
    }

    function burnUser() internal {
        customToken.burn(msg.sender, customToken.balanceOf(msg.sender));
    }

    function withdraw() external nonReentrant {
        uint256 balance = customToken.balanceOf(msg.sender);
        require(balance > 0, "Insufficient balance");

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");

        burnUser();
    }
}
