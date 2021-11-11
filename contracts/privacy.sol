pragma solidity >=0.4.20 <0.8.0;

contract StoreYourSecret {
    bytes32 private secretBytes;
    string private secretString;

    constructor(bytes32 _secretBytes, string memory _secretString) public {
        secretBytes = _secretBytes;
        secretString = _secretString;
    }
}
