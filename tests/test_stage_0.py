from wake.testing import *

from pytypes.contracts.stage0.Foo import Foo

# Print failing tx call trace
def revert_handler(e: RevertError):
    if e.tx is not None:
        print(e.tx.call_trace)


@chain.connect()
@on_revert(revert_handler)
def test_default():
    deployer, alice = chain.accounts[0:2]

    foo = Foo.deploy(from_=deployer)

    print(foo.actualBalance())

    foo.add(250, from_=alice)
    print(foo.actualBalance())
    foo.add(20, from_=alice)

    print(foo.actualBalance())