## Stage 1 - DEX Frontrunning

`SimpleDEX` implements a constant-product AMM (x × y = k) without some security mechanisms. The `swapAforB` and `swapBforA` functions accept any input amount.

### Test Goals (`tests/test_stage_1.py`)

- Demonstrate the attack sequence with three transactions in unit test
- Hint is "sandwich"
- Show attacker's profit
- Discuss mitigations