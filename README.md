# NIE-BLO Tutorial 6

Hacking, debugging and testing with the Wake framework.

* Stage 0: Integer overflow.
* Stage 1: Reentrancy.
* Stage 2: Forcing Ether.
* Stage 3: Metamorphosis.

## Running the tests

Write your tests in [`tests/test_default.py`](tests/test_default.py). If you are unsure, the complete version of the test can be found in the `solution` branch of this repository.

To run the tests, make sure you have downloaded and installed Anvil:

```bash
curl -L https://foundry.paradigm.xyz | bash  # insecure install, you know
source ~/.bashrc && foundryup
```

Next, you can run the following:

```bash
wake test
```
