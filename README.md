
# Hamzawi_Project

## Overview
This project is an Expert Advisor (EA) for MetaTrader 4 (MT4) designed to automate trading based on a custom strategy provided by the client. The EA uses Parabolic SAR, two Exponential Moving Averages, and a user-defined "Golden Candle" to determine trade entries, exits, and risk management.

## Features
- Customizable lot size, Parabolic SAR, and Moving Average parameters
- Golden Candle input for dynamic entry and stop loss calculation
- Automated buy/sell logic based on indicator signals
- Dynamic stop loss, take profit, and trailing stop system
- Visual chart levels for entry, stop loss, and profit targets
- Lot progression table for risk management

## Usage
1. Place the EA file in your MT4 `Experts` directory.
2. Attach the EA to your desired chart.
3. Configure the input parameters:
   - Lot size
   - Parabolic SAR settings
   - Moving Average settings
   - Golden Candle size
4. The EA will automatically execute trades and manage positions according to the strategy rules.

## Requirements
- MetaTrader 4 platform
- The provided PDF ("EA Forex.pdf") contains the original client requirements and strategy details.

## Documentation
See `Technical_Documentation.md` for a detailed technical description of the EA logic and implementation.
