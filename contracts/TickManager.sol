// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LiquidityPool.sol";

contract TickManager {

    struct Tick {
        uint128 liquidity;
        bool initialized;
    }

    // Mapping to store tick information
    mapping(int24 => Tick) public ticks;
    
    // Constant for tick spacing (example 60)
    int24 public constant TICK_SPACING = 60;  // Changed to int24

    // This will store active ticks for a specific pool
    mapping(address => mapping(int24 => bool)) public activeTicks;

    // Initialize a tick range and mint liquidity for the given tick levels
    function initializeTickRange(
        address pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external {
        require(tickLower < tickUpper, "Invalid tick range");

        for (int24 tick = tickLower; tick <= tickUpper; tick += TICK_SPACING) {
            if (!ticks[tick].initialized) {
                ticks[tick].initialized = true;
                // Initialize the tick and mint liquidity to the pool for the given tick range
                LiquidityPool(pool).mint(address(this), tick, tick + TICK_SPACING, liquidity, liquidity);
            }
        }
    }

    // Function to activate a tick for a given pool (when liquidity is added or removed)
    function activateTick(address pool, int24 tick) external {
        activeTicks[pool][tick] = true;
    }

    // Function to deactivate a tick for a given pool (when liquidity is removed or reset)
    function deactivateTick(address pool, int24 tick) external {
        activeTicks[pool][tick] = false;
    }

    // Helper function to get the liquidity for a particular tick (useful for the user)
    function getLiquidityForTick(address pool, int24 tick) external view returns (uint128) {
        return ticks[tick].liquidity;
    }

    // Function to get the status of a tick (initialized or not)
    function isTickInitialized(int24 tick) external view returns (bool) {
        return ticks[tick].initialized;
    }
}
