# Privacy on blockchain
Storing secrets on blockchain is not good idea

```
c = StoreYourSecret.deploy("746f74616c6c79736563726574","hlavnetajne",{'from': accounts[0]})
web3.eth.getStorageAt(c.address,0)
web3.eth.getStorageAt(c.address,0).decode()
```
