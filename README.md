# 🦄 Uniswap V3-Style DEX – Core Smart Contract Implementation

A custom-built decentralized exchange (DEX) smart contract system inspired by Uniswap V3. This implementation supports concentrated liquidity using ticks, swap logic, and fee accounting — built from scratch using Solidity and Hardhat.

## 🔍 Overview

This project reconstructs the essential components of a Uniswap V3-style DEX protocol without relying on external libraries. It demonstrates deep understanding of:

- Tick-based liquidity provisioning
- Swaps within specific price ranges
- Liquidity pool math
- Fee accrual per position

> ⚠️ This is a **backend-only** implementation (smart contracts only). There is **no frontend UI** included in this repo.

## 🛠️ Tech Stack

- **Language**: Solidity (>=0.8.0)
- **Framework**: Hardhat


## ✨ Features

- 🧮 **Tick-Based Liquidity**: Add liquidity in a specific price range using tick math
- 💱 **Swap Logic**: Users can swap tokens with precision routing through price ticks
- 💰 **Fee Accounting**: Tracks and allocates fees proportionally to liquidity providers
- 📐 **No External Dependencies**: All core logic is written from scratch for educational purposes
