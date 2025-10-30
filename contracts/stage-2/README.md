## Stage 2 - Simple Reentrancy

`SimpleBank` allows users to deposit and withdraw ETH. The `withdraw` function contains a classic reentrancy vulnerability: it makes an external call to send ETH **before** updating the user's balance.

### The Vulnerability

```solidity
function withdraw(uint256 amount) external {
    require(balances[msg.sender] >= amount, "insufficient balance");

    // External call BEFORE state update
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "transfer failed");

    // Balance updated AFTER external call
    balances[msg.sender] -= amount;
}
```

When the bank sends ETH via `.call()`, if the recipient is a contract, its `receive()` or `fallback()` function executes. The attacker can re-enter `withdraw()` before the balance is updated, draining the bank.

### Attack Flow

1. Attacker deposits 1 ETH into the bank
2. Attacker calls `withdraw(1 ETH)`
3. Bank sends 1 ETH to attacker contract
4. Attacker's `receive()` function executes
5. **Re-entry**: Attacker calls `withdraw(1 ETH)` again
6. Bank checks balance (still 1 ETH because not yet updated)
7. Bank sends another 1 ETH
8. Repeat until bank is drained

### Exercise Steps

1. Deploy `SimpleBank` and fund it with deposits from multiple users (e.g., 10 ETH total)
2. Deploy `Attacker` contract pointing to the bank
3. Call `Attacker.attack()` with 1 ETH
4. Observe the attacker drains more than their deposit
5. Check bank balance is now 0 or near-zero

### Mitigation: Checks-Effects-Interactions (CEI) Pattern

```solidity
function withdraw(uint256 amount) external {
    require(balances[msg.sender] >= amount, "insufficient balance");

    // Update state BEFORE external call
    balances[msg.sender] -= amount;

    // External call happens last
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "transfer failed");
}
```

Alternatively, use OpenZeppelin's `ReentrancyGuard` modifier.

### Test Goals (`tests/test_stage_2.py`)

- Fund the bank with multiple deposits
- Write an Attacker contract in Solidity and execute it in a unit test
- Demonstrate the fix by reordering state updates

