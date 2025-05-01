// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./PriceOracle.sol";
import "./LiquidityPool.sol"; // Assuming LiquidityPool contract is imported correctly

contract PoolFactory {
    PriceOracle public oracle; // Instance of the PriceOracle contract
    address public owner; // Owner of the contract (only the owner can create pools)

    // Mapping to store pool addresses for each token pair
    mapping(address => mapping(address => address)) public getPool;

    // Event that will be emitted whenever a new pool is created
    event PoolCreated(address indexed token0, address indexed token1, address pool);

    // Constructor that initializes the oracle address and owner
    constructor(address _oracle) {
        oracle = PriceOracle(_oracle);
        owner = msg.sender;
    }

    // Function to create a new pool between token0 and token1
    function createPool(
        address token0,
        address token1,
        string memory symbol0,
        string memory symbol1
    ) external returns (address pool) {
        // Ensure only the contract owner can create pools
        require(msg.sender == owner, "Not owner");

        // Prevent creation of multiple pools for the same token pair
        require(getPool[token0][token1] == address(0), "Pool already exists");

        // Fetch prices for the tokens from the oracle
        int256 price0 = oracle.getLatestPrice(symbol0);
        int256 price1 = oracle.getLatestPrice(symbol1);
        require(price0 > 0 && price1 > 0, "Invalid price");

        // Calculate the price ratio between token0 and token1
        uint256 priceRatio = uint256(price0) * 1e18 / uint256(price1);

        // Calculate the sqrtPriceX96 using the price ratio (scaled by 2^96)
        uint160 sqrtPriceX96 = uint160(sqrt(priceRatio) * 2**96 / 1e9);

        // Deploy the liquidity pool contract
        pool = address(new LiquidityPool(token0, token1, sqrtPriceX96));

        // Store the created pool in the getPool mapping for both directions
        getPool[token0][token1] = pool;
        getPool[token1][token0] = pool;

        // Emit the PoolCreated event for transparency
        emit PoolCreated(token0, token1, pool);
    }

    // Internal square root function used to calculate sqrtPriceX96
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
