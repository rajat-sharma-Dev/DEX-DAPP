// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundID,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract PriceOracle {
    address public owner;
    mapping(string => AggregatorV3Interface) public priceFeeds;

    constructor() {
        owner = msg.sender;
    }

    function setPriceFeed(string calldata symbol, address feed) external {
        require(msg.sender == owner, "Only owner");
        priceFeeds[symbol] = AggregatorV3Interface(feed);
    }

    function getLatestPrice(string calldata symbol) external view returns (int256) {
        AggregatorV3Interface priceFeed = priceFeeds[symbol];
        require(address(priceFeed) != address(0), "Price feed not found");

        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return answer;
    }
}
