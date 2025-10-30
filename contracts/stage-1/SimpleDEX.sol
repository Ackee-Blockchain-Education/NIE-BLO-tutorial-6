// SPDX-License-Identifier: None

pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @title SimpleToken
/// @notice Basic ERC20 for DEX demonstrations
contract SimpleToken {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply);
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

/// @title SimpleDEX
/// @notice Constant product AMM without some security stuff
/// @dev Uses x * y = k formula
contract SimpleDEX {
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    event Swap(
        address indexed user,
        address indexed tokenIn,
        uint256 amountIn,
        uint256 amountOut
    );
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);

    constructor(IERC20 _tokenA, IERC20 _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    /// @notice Add initial liquidity to the pool
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "amounts must be positive");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    /// @notice Swap tokenA for tokenB
    function swapAforB(uint256 amountIn) external returns (uint256 amountOut) {
        require(amountIn > 0, "amount must be positive");
        require(reserveA > 0 && reserveB > 0, "no liquidity");

        // Calculate output using constant product formula: x * y = k
        // amountOut = reserveB - (reserveA * reserveB) / (reserveA + amountIn)
        uint256 amountInWithFee = amountIn * 997; // 0.3% fee
        uint256 numerator = amountInWithFee * reserveB;
        uint256 denominator = (reserveA * 1000) + amountInWithFee;
        amountOut = numerator / denominator;

        require(amountOut > 0, "insufficient output");
        require(amountOut < reserveB, "insufficient liquidity");

        tokenA.transferFrom(msg.sender, address(this), amountIn);
        tokenB.transfer(msg.sender, amountOut);

        reserveA += amountIn;
        reserveB -= amountOut;

        emit Swap(msg.sender, address(tokenA), amountIn, amountOut);
    }

    /// @notice Swap tokenB for tokenA
    function swapBforA(uint256 amountIn) external returns (uint256 amountOut) {
        require(amountIn > 0, "amount must be positive");
        require(reserveA > 0 && reserveB > 0, "no liquidity");

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveA;
        uint256 denominator = (reserveB * 1000) + amountInWithFee;
        amountOut = numerator / denominator;

        require(amountOut > 0, "insufficient output");
        require(amountOut < reserveA, "insufficient liquidity");

        tokenB.transferFrom(msg.sender, address(this), amountIn);
        tokenA.transfer(msg.sender, amountOut);

        reserveB += amountIn;
        reserveA -= amountOut;

        emit Swap(msg.sender, address(tokenB), amountIn, amountOut);
    }

    /// @notice Get expected output for a given input (view function)
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        returns (uint256)
    {
        require(amountIn > 0, "amount must be positive");
        require(reserveIn > 0 && reserveOut > 0, "insufficient liquidity");

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        return numerator / denominator;
    }
}

