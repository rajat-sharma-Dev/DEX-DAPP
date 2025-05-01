// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMockERC20 {
    function mint(address to, uint256 amount) external;
}

contract Faucet {
    address public owner;

    mapping(string => IMockERC20) public tokens;

    constructor() {
        owner = msg.sender;
    }

    function addToken(string memory symbol, address tokenAddress) external {
        require(msg.sender == owner, "Not owner");
        tokens[symbol] = IMockERC20(tokenAddress);
    }

    function requestTokens(string memory symbol) external {
        IMockERC20 token = tokens[symbol];
        require(address(token) != address(0), "Token not supported");

        token.mint(msg.sender, 1000 * 10 ** 18); // mint 1000 tokens to user
    }
}
