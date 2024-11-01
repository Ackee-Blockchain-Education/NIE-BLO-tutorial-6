// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.20;

/* Let's discuss how create3() works.
 *
 * create() deploys a contract and the new contract's address is computed
 * deterministically as
 *
 *     address = keccak256(rlp([sender_address,sender_nonce]))[12:]
 *
 * So, the address is dependent on the sender's address and the number of the
 * transactions sent by the sender.
 *
 * create2(), however, is a function that computes the address of a contract
 * that would be deployed as
 *
 *     address = keccak256(0xff + sender_addr + salt + keccak256(init_code))[12:]
 *
 * So, the address is dependent on the sender's address, a salt, and the
 * contract's initialization code. There is no nonce involved in the
 * computation. This means that the address can be determined deterministicly
 * at any point in time, given the same sender address, salt, and initialization
 * code.
 *
 * create3() is a combination of create() and create2(). It is not a native EVM
 * opcode, but rather a library. By using create3(), we achive the same
 * determinism as create2(), but without the dependency on the contract's
 * initialization code.
 *
 * First, we deploy a proxy contract using create2(). The address of the proxy
 * contract is computed as the address of the sender, the salt, and the hash of
 * the bytecode of the proxy contract. The proxy contract is a simple contract
 * and its bytecode is constant and known in advance. Of course, we can compute
 * the address of the proxy contract in advance.
 *
 * The proxy contract has a single function that takes a byte array as an
 * argument. This byte array is the initialization code of the contract we want
 * to deploy. The proxy contract deploys the contract using the create() opcode.
 * The address of the deployed contract is computed deterministically as the
 * address of the proxy contract and the nonce of the proxy contract. Notice
 * that the nonce of the proxy contract is always 1 after deployment. This means
 * that the address of the deployed contract is also deterministic.
 *
 * By chaining the two create() opcodes, we can deploy a contract at a
 * deterministic address that is only dependent on the sender's address and
 * a salt. Every deployment actually consists of two deployments: one for the
 * proxy contract and one for the actual contract.
 */

library Bytes32AddressLib {
    function fromLast20Bytes(
        bytes32 bytesValue
    ) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(
        address addressValue
    ) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

library CREATE3 {
    using Bytes32AddressLib for bytes32;

    bytes internal constant TEMP_BYTECODE =
        type(TemporaryContract).creationCode;
    bytes32 internal constant TEMP_BYTECODE_HASH = keccak256(TEMP_BYTECODE);

    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        uint256 value
    ) internal returns (address deployed) {
        bytes memory temp = TEMP_BYTECODE;
        address proxy;
        assembly {
            // Deploy a new contract with our pre-made bytecode via CREATE2.
            // We start 32 bytes into the code to avoid copying the byte length.
            proxy := create2(value, add(temp, 32), mload(temp), salt)
        }
        require(proxy != address(0), "DEPLOYMENT_FAILED");

        TemporaryContract(proxy).metamorph(creationCode);

        deployed = getDeployed(salt);
    }

    function getDeployed(bytes32 salt) internal view returns (address) {
        return getDeployed(salt, address(this));
    }

    function getDeployed(
        bytes32 salt,
        address creator
    ) internal pure returns (address) {
        address proxy = keccak256(
            abi.encodePacked(
                // Prefix:
                bytes1(0xFF),
                // Creator:
                creator,
                // Salt:
                salt,
                // Bytecode hash:
                TEMP_BYTECODE_HASH
            )
        ).fromLast20Bytes();

        return
            keccak256(
                abi.encodePacked(
                    // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01)
                    // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
                    hex"d6_94",
                    proxy,
                    hex"01" // Nonce of the proxy contract (1)
                )
            ).fromLast20Bytes();
    }
}

interface ICREATE3Factory {
    function deployContract(
        bytes32 salt,
        bytes memory creationCode
    ) external payable returns (address deployed);

    function getDeployed(
        address deployer,
        bytes32 salt
    ) external view returns (address deployed);
}

contract CREATE3Factory is ICREATE3Factory {
    function deployContract(
        bytes32 salt,
        bytes memory creationCode
    ) external payable override returns (address deployed) {
        return CREATE3.deploy(salt, creationCode, msg.value);
    }

    function getDeployed(
        address deployer,
        bytes32 salt
    ) external pure override returns (address deployed) {
        return CREATE3.getDeployed(salt, deployer);
    }
}

contract TemporaryContract {
    function metamorph(bytes memory initCode) public payable {
        assembly {
            if iszero(create(0, add(initCode, 32), mload(initCode))) {
                revert(0, 0)
            }
            selfdestruct(caller())
        }
    }
}
