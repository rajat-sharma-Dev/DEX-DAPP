// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LiquidityPool.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
//import "@openzeppelin/contracts/utils/Counters.sol";

contract PositionManager is ERC721URIStorage {
    
    uint256 private _tokenIds;

    struct Position {
        address pool;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }

    mapping(uint256 => Position) public positions;

    event PositionMinted(uint256 tokenId, address indexed owner, address pool, int24 tickLower, int24 tickUpper, uint128 liquidity);
    event PositionBurned(uint256 tokenId, address indexed owner, address pool, int24 tickLower, int24 tickUpper, uint128 liquidity);

    constructor() ERC721("LP Position", "LPP") {}

    function mintPosition(
        address pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external returns (uint256) {
        _tokenIds++;
        uint256 newId = _tokenIds;
        _mint(msg.sender, newId);

        // Call into pool to add liquidity
        LiquidityPool(pool).addLiquidity(tickLower, tickUpper, liquidity, liquidity);

        // Store the position details
        positions[newId] = Position(pool, tickLower, tickUpper, liquidity);

        // Emit PositionMinted event
        emit PositionMinted(newId, msg.sender, pool, tickLower, tickUpper, liquidity);

        return newId;
    }

    function burnPosition(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");

        Position memory pos = positions[tokenId];

        // Call into pool to remove liquidity
        LiquidityPool(pos.pool).removeLiquidity(pos.tickLower, pos.tickUpper, pos.liquidity, pos.liquidity);

        // Emit PositionBurned event
        emit PositionBurned(tokenId, msg.sender, pos.pool, pos.tickLower, pos.tickUpper, pos.liquidity);

        // Remove the position details and burn the token
        delete positions[tokenId];
        _burn(tokenId);
    }
}
