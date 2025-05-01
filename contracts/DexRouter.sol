// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./PoolFactory.sol";
import "./LiquidityPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DexRouter {
    PoolFactory public factory;
    address public owner;

    constructor(address _factory) {
        factory = PoolFactory(_factory);
        owner = msg.sender;
    }

    // Add liquidity to the pool
    function addLiquidity(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) external {
        address poolAddr = factory.getPool(token0, token1);
        require(poolAddr != address(0), "Pool doesn't exist");

        // Transfer tokens to the liquidity pool contract
        IERC20(token0).transferFrom(msg.sender, poolAddr, amount0);
        IERC20(token1).transferFrom(msg.sender, poolAddr, amount1);

        // Add liquidity using the pool's addLiquidity function
        LiquidityPool(poolAddr).addLiquidity(-120, 120, amount0, amount1);

    }

    // Remove liquidity from the pool
    function removeLiquidity(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) external {
        address poolAddr = factory.getPool(token0, token1);
        require(poolAddr != address(0), "Pool doesn't exist");

        // Call removeLiquidity on the pool contract
        LiquidityPool(poolAddr).removeLiquidity(-120, 120, amount0, amount1);

    }

    // Swap tokens in the pool
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external {
        address poolAddr = factory.getPool(tokenIn, tokenOut);
        require(poolAddr != address(0), "Pool doesn't exist");

        // Transfer input tokens to the liquidity pool
        IERC20(tokenIn).transferFrom(msg.sender, poolAddr, amountIn);
        
        // Perform the swap using the pool's swap function
        LiquidityPool(poolAddr).swap(amountIn, tokenIn < tokenOut); // or pass a bool directly


    }

    // Get the current price of the pool (to aid with swaps and liquidity additions)
    // function getPoolPrice(address token0, address token1) external view returns (uint256 price) {
    //     address poolAddr = factory.getPool(token0, token1);
    //     require(poolAddr != address(0), "Pool doesn't exist");

    //     // Fetch the current price of the pool from LiquidityPool
    //     return LiquidityPool(poolAddr).getPrice();
    // }

    // Add functionality for token price checks and liquidity fees if needed
    // function getPoolLiquidity(address token0, address token1) external view returns (uint256 liquidity) {
    //     address poolAddr = factory.getPool(token0, token1);
    //     require(poolAddr != address(0), "Pool doesn't exist");

    //     // Fetch the liquidity for the specific pool
    //     return LiquidityPool(poolAddr).getLiquidity();
    // }
    function getPoolState(address token0, address token1) external view returns (
        uint256 reserve0,
        uint256 reserve1,
        uint160 currentSqrtPriceX96,
        int24 currentTick,
        uint24 currentFee
    ) {
        address poolAddr = factory.getPool(token0, token1);
        require(poolAddr != address(0), "Pool doesn't exist");

        // Fetch the state of the pool from LiquidityPool
        (reserve0, reserve1, currentSqrtPriceX96, currentTick, currentFee) = LiquidityPool(poolAddr).getPoolState();
    }

    
}
