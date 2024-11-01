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

    pass


# Stage 1: Reentrancy
@default_chain.connect()
@on_revert(revert_handler)
def test_reentrancy():
    from pytypes.contracts.stage1.Reentrancy import (
        Bank as Bank,
        Attacker as Attacker,
    )

    pass


# Stage 2: Forcing Ether
@default_chain.connect()
@on_revert(revert_handler)
def test_forcing_ether():
    from pytypes.contracts.stage2.Force import (
        DegenGame as DegenGame,
        Feeder as Feeder,
        AttackForWin as AttackForWin,
    )

    pass


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

    pass
