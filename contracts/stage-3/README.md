## Stage 3 - Type Casting with Storage Packing

`PackedVault` attempts to optimize gas costs by packing user data into a single storage slot using smaller integer types.

### Test Goals (`tests/test_stage_3.py`)

- Identify the vulnerability (or more) in the code
- Create a test with exploitation flow
- Discuss impact
- Fix the vulnerability
