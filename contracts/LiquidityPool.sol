// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Lib2/TickMath.sol"; // Assuming TickMath is implemented

contract LiquidityPool {
    using TickMath for int24;

    IERC20 public token0;
    IERC20 public token1;
    uint160 public sqrtPriceX96;
    int24 public tick;

    // Global liquidity tracking
    uint256 public totalLiquidity0;
    uint256 public totalLiquidity1;

    uint256 public volume0;
    uint256 public volume1;
    uint256 public lastTradeTime;

    int24 public tickSpacing = 60;
    uint256 public baseFeePercentage = 30;

    address public owner;

    mapping(address => uint256) public feeBalance0;
    mapping(address => uint256) public feeBalance1;

    // Liquidity position tracking: user => tickLower => tickUpper => liquidity
    struct Position {
        uint256 liquidity0;
        uint256 liquidity1;
    }

    mapping(address => mapping(int24 => mapping(int24 => Position))) public positions;

    event LiquidityAdded(address indexed user, uint256 amount0, uint256 amount1);
    event LiquidityRemoved(address indexed user, uint256 amount0, uint256 amount1);
    event LiquidityMinted(address indexed user, int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1);
    event Swap(address indexed user, uint256 amountIn, uint256 amountOut, bool isToken0ToToken1);
    event FeeCollected(address indexed user, uint256 amount0, uint256 amount1);
    event FeeChanged(uint256 newFeePercentage);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor(address _token0, address _token1, uint160 _sqrtPriceX96) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        sqrtPriceX96 = _sqrtPriceX96;
        tick = TickMath.getTickAtSqrtRatio(_sqrtPriceX96);
        owner = msg.sender;
        lastTradeTime = block.timestamp;
    }

    function calculateDynamicFee() public view returns (uint256) {
        uint256 liquidityRatio = totalLiquidity0 > totalLiquidity1 ? totalLiquidity0 / totalLiquidity1 : totalLiquidity1 / totalLiquidity0;
        uint256 feeAdjustment = liquidityRatio > 1 ? baseFeePercentage : baseFeePercentage + (baseFeePercentage / 10);
        uint256 volumeAdjustment = (volume0 + volume1) > 10000 ? feeAdjustment - (feeAdjustment / 10) : feeAdjustment;
        return volumeAdjustment;
    }

    /// --- MINT FUNCTION FOR TICK-RANGE LIQUIDITY ---
    function mint(address user, int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1) external {
        require(tickLower < tickUpper, "Invalid tick range");
        require(tickLower % tickSpacing == 0 && tickUpper % tickSpacing == 0, "Tick spacing violation");

        // Transfer tokens to pool
        require(token0.transferFrom(msg.sender, address(this), amount0), "Token0 transfer failed");
        require(token1.transferFrom(msg.sender, address(this), amount1), "Token1 transfer failed");

        // Update global liquidity
        totalLiquidity0 += amount0;
        totalLiquidity1 += amount1;

        // Update user's position
        positions[user][tickLower][tickUpper].liquidity0 += amount0;
        positions[user][tickLower][tickUpper].liquidity1 += amount1;
        emit LiquidityMinted(user, tickLower, tickUpper, amount0, amount1);
    }

    function addLiquidity(int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1) external {
        require(tickLower % tickSpacing == 0 && tickUpper % tickSpacing == 0, "Ticks must follow spacing");
        require(token0.transferFrom(msg.sender, address(this), amount0), "Token0 transfer failed");
        require(token1.transferFrom(msg.sender, address(this), amount1), "Token1 transfer failed");
        totalLiquidity0 += amount0;
        totalLiquidity1 += amount1;
        emit LiquidityAdded(msg.sender, amount0, amount1);
    }

    function removeLiquidity(int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1) external {
        require(tickLower % tickSpacing == 0 && tickUpper % tickSpacing == 0, "Ticks must follow spacing");
        totalLiquidity0 -= amount0;
        totalLiquidity1 -= amount1;

        require(token0.transfer(msg.sender, amount0), "Token0 transfer failed");
        require(token1.transfer(msg.sender, amount1), "Token1 transfer failed");

        // Distribute accumulated fees
        uint256 fees0 = feeBalance0[msg.sender];
        uint256 fees1 = feeBalance1[msg.sender];
        if (fees0 > 0) {
            require(token0.transfer(msg.sender, fees0), "Token0 fee transfer failed");
            feeBalance0[msg.sender] = 0;
        }
        if (fees1 > 0) {
            require(token1.transfer(msg.sender, fees1), "Token1 fee transfer failed");
            feeBalance1[msg.sender] = 0;
        }

        emit LiquidityRemoved(msg.sender, amount0, amount1);
    }

    function swap(uint256 amountIn, bool isToken0ToToken1) external {
        uint256 amountOut;
        uint256 feePercentage = calculateDynamicFee();
        if (isToken0ToToken1) {
            amountOut = _swapToken0ForToken1(amountIn, feePercentage);
        } else {
            amountOut = _swapToken1ForToken0(amountIn, feePercentage);
        }
        emit Swap(msg.sender, amountIn, amountOut, isToken0ToToken1);
    }

    function _swapToken0ForToken1(uint256 amountIn, uint256 feePercentage) internal returns (uint256 amountOut) {
        uint256 price = uint256(sqrtPriceX96);
        uint256 feeAmount = (amountIn * feePercentage) / 10000;
        amountOut = ((amountIn - feeAmount) * price) / 1e18;
        volume0 += amountIn;
        require(token0.transferFrom(msg.sender, address(this), amountIn), "Token0 transfer failed");
        require(token1.transfer(msg.sender, amountOut), "Token1 transfer failed");
        feeBalance1[msg.sender] += feeAmount;
    }

    function _swapToken1ForToken0(uint256 amountIn, uint256 feePercentage) internal returns (uint256 amountOut) {
        uint256 price = uint256(sqrtPriceX96);
        uint256 feeAmount = (amountIn * feePercentage) / 10000;
        amountOut = ((amountIn - feeAmount) * price) / 1e18;
        volume1 += amountIn;
        require(token1.transferFrom(msg.sender, address(this), amountIn), "Token1 transfer failed");
        require(token0.transfer(msg.sender, amountOut), "Token0 transfer failed");
        feeBalance0[msg.sender] += feeAmount;
    }

    function getPoolState() external view returns (
        uint256 reserve0,
        uint256 reserve1,
        uint160 currentSqrtPriceX96,
        int24 currentTick,
        uint24 currentFee
    ) {
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));
        currentSqrtPriceX96 = sqrtPriceX96;
        currentTick = tick;
        currentFee = uint24(calculateDynamicFee());
    }

    function setBaseFeePercentage(uint256 newBaseFeePercentage) external onlyOwner {
        baseFeePercentage = newBaseFeePercentage;
        emit FeeChanged(newBaseFeePercentage);
    }
}
