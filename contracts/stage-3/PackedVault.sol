// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @title Token18
/// @notice Standard 18-decimal ERC20 token
contract Token18 {
    string public constant name = "Token18";
    string public constant symbol = "TK18";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

/// @title PackedVault
/// @notice Vault that uses packed storage to save gas
contract PackedVault {
    IERC20 public immutable token;

    // Packed struct: uint64 + uint64 + uint128 = 256 bits (1 slot)
    struct UserInfo {
        uint64 balance;
        uint64 lastDeposit;    // Timestamp of last deposit
        uint128 totalDeposited; // Lifetime deposits
    }

    mapping(address => UserInfo) public users;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 requested, uint256 actual);

    constructor(IERC20 _token) {
        token = _token;
    }

    /// @notice Deposit tokens into the vault
    function deposit(uint256 amount) external {
        require(amount > 0, "zero amount");

        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "transfer failed");

        UserInfo storage user = users[msg.sender];

        user.balance += uint64(amount);
        user.lastDeposit = uint64(block.timestamp);
        user.totalDeposited += uint128(amount);

        emit Deposited(msg.sender, amount);
    }

    /// @notice Withdraw tokens from the vault
    function withdraw(uint256 amount) external {
        UserInfo storage user = users[msg.sender];
        require(user.balance >= uint64(amount), "insufficient balance");

        uint64 withdrawAmount = uint64(amount);
        user.balance -= withdrawAmount;

        bool success = token.transfer(msg.sender, withdrawAmount);
        require(success, "transfer failed");

        emit Withdrawn(msg.sender, amount, withdrawAmount);
    }

    /// @notice Get user's stored balance
    function getBalance(address user) external view returns (uint64) {
        return users[user].balance;
    }

    /// @notice Get user's full info
    function getUserInfo(address user) external view returns (uint64 balance, uint64 lastDeposit, uint128 totalDeposited) {
        UserInfo memory info = users[user];
        return (info.balance, info.lastDeposit, info.totalDeposited);
    }
}

