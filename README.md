# Integer overflow
Basic example of integer overflow

```
o = Overflow.deploy({'from': accounts[0]})
o.add(200)
o.add(30)
o.add(30)
```

`import "OpenZeppelin/openzeppelin-contracts@3.4.2/contracts/math/SafeMath.sol";`
