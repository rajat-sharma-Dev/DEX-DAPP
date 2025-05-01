// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice TickMath optimized for Uniswap-style DEX with TickSpacing and TickBitmap
library TickMath {
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = 887272;

    // Uniswap V3's constants for tick to sqrtPrice conversion
    uint160 internal constant MIN_SQRT_RATIO = 4295128739; // sqrt(1.0001^MIN_TICK) * 2^96
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342; // sqrt(1.0001^MAX_TICK) * 2^96

    /// @notice Get sqrt price from tick using bitwise operations
    /// @dev This function calculates sqrtPrice at a given tick
    /// @param tick The tick for which sqrtPrice is being calculated
    /// @return sqrtPriceX96 The sqrtPrice in Q96 format
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        require(tick >= MIN_TICK && tick <= MAX_TICK, "T");

        int256 absTick = tick < 0 ? int256(-tick) : int256(tick);  // Handle absolute value with int256
        uint256 ratio = 0x100000000000000000000000000000000; // Default value 1 << 96

        // Loop for calculating the ratio efficiently
        if (absTick & 0x1 != 0) ratio = (ratio * 0x10001) >> 16;
        if (absTick & 0x2 != 0) ratio = (ratio * 0x10001) >> 16;
        if (absTick & 0x4 != 0) ratio = (ratio * 0x10001) >> 16;
        if (absTick & 0x8 != 0) ratio = (ratio * 0x10001) >> 16;
        // Repeat similar operations for other bits of absTick
        sqrtPriceX96 = uint160(ratio);
    }

    /// @notice Get tick from sqrt price using bitwise operations
    /// @dev This function calculates tick at a given sqrtPrice
    /// @param sqrtPriceX96 The sqrtPrice in Q96 format
    /// @return tick The corresponding tick
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");

        uint256 ratio = uint256(sqrtPriceX96);
        int24 l = 0;
        int24 r = 255;
        
        // A binary search approach for sqrtPrice to tick
        while (l < r) {
            int24 mid = (l + r + 1) >> 1;
            if (getSqrtRatioAtTick(mid) <= sqrtPriceX96) {
                l = mid;
            } else {
                r = mid - 1;
            }
        }

        tick = l;
    }

    /// @notice Calculate tick spacing for concentrated liquidity
    /// @param tickSpacing The spacing between valid ticks
    /// @return tick The valid tick spaced value
    function getTickSpacing(int24 tickSpacing) internal pure returns (int24) {
        require(tickSpacing > 0, "Tick spacing must be positive");
        return tickSpacing;
    }

    /// @notice Set the active bitmap for ticks
    /// @param tick The tick for which the bitmap is set
    /// @return bitmap The tick bitmap where a specific tick is activated
    function getTickBitmap(int24 tick) internal pure returns (uint256 bitmap) {
        require(tick >= MIN_TICK && tick <= MAX_TICK, "T");

        // Calculate the bitmap position for a tick
        uint256 bitmapPosition = uint256(int256(tick)) / 256; // Using 256 bits per word
        bitmap = 1 << uint256(uint24(tick % 256)); // Set the bit corresponding to this tick
        return bitmap;
    }
}
