<!-- Banner image for GitHub (optional, can be replaced with your own) -->
<p align="center">
  <img src="https://img.icons8.com/ios-filled/100/2a5d9f/robot-2.png" alt="EA Icon" width="90"/>
</p>

# Hamzawi_Project - MT4 Expert Advisor

---
## 📈 Overview

**Hamzawi_Project** is a professional Expert Advisor (EA) for **MetaTrader 4 (MT4)** that automates trading based on a custom strategy provided by the client.
The EA leverages Parabolic SAR, two Exponential Moving Averages, and a user-defined **Golden Candle** to determine trade entries, exits, and risk management.
## ✨ Key Features

- Customizable lot size, Parabolic SAR, and Moving Average parameters
- Golden Candle input for dynamic entry and stop loss calculation
- Automated buy/sell logic based on indicator signals
- Dynamic stop loss, take profit, and trailing stop system
- Visual chart levels for entry, stop loss, and profit targets
- Lot progression table for risk management
- Comprehensive logging for all technical actions and errors
- Visual Golden Candle highlighting on the chart
## 🛠️ How to Use

1. Place the EA file (`GoldenCandleEA.mq4`) in your MT4 `Experts` directory.
2. Restart MetaTrader 4 and attach the EA to your desired chart.
3. Configure the input parameters as needed:
    - Lot size
    - Parabolic SAR settings
    - Moving Average settings
    - Golden Candle size
4. The EA will automatically execute trades and manage positions according to the strategy rules.
## 📋 Requirements

- MetaTrader 4 platform
- The provided PDF (`EA Forex.pdf`) contains the original client requirements and strategy details.
## 📚 Documentation

See `Technical_Documentation.md` for a detailed technical description of the EA logic and implementation.
## 📝 Critique & Compliance Review
### 1. Explicitness of Client Requirements

**a. Golden Candle Logic**

- ✔️ The EA detects Golden Candles using Parabolic SAR and price action, as specified.
- ✔️ It only starts trading after the first Golden Candle appears, as now required.
- ✔️ It draws a rectangle on the chart for each Golden Candle, making detection explicit.

**b. Entry Logic**

- ✔️ Entry is only allowed after a Golden Candle appears.
- ✔️ Both Buy and Sell entries are handled, with correct calculation of entry, SL, and TP.
- ✔️ EMA cross entries are implemented, with fallback to ATR if GoldenCandleSize is not set.

**c. Lot Progression**

- ✔️ Lot progression table is implemented and capped.
- ✔️ Lot index advances on SL, resets on TP, and is logged.

**d. Chart Visuals**

- ✔️ Entry, SL, and profit levels are drawn on the chart.
- ✔️ Golden Candle rectangles are drawn for visual verification.

**e. Logging and Debugging**

- ✔️ All key actions (setup, entry, exit, errors, SL/TP adjustments, waiting for Golden Candle) are logged to a CSV file and the Experts tab.
- ✔️ SL/TP distance and StopLevel fallback are logged for broker compliance.

**f. Robustness**

- ✔️ OrderSend is retried up to 3 times.
- ✔️ SL/TP are adjusted if too close to price, with fallback if StopLevel is zero.
- ✔️ MagicNumber is used for trade identification.

**g. User Adjustability**

- ✔️ All key parameters are extern and user-adjustable.

### 2. Areas for Improvement or Clarification

- **a. Golden Candle Detection:**
  - The EA only looks for the most recent Golden Candle (from shift=1). If multiple Golden Candles appear in history, only the latest is considered for entry. This is generally correct, but if the client wants to trade every Golden Candle, a loop or queue would be needed.
- **b. EMA Cross Logic:**
  - EMA cross entries are allowed on every bar after the first Golden Candle, not just immediately after a Golden Candle. If the client wants EMA cross entries only when a Golden Candle is present, this logic should be tightened.
- **c. Trade Management:**
  - The EA only manages one trade at a time (`inTrade` flag). If the client wants multiple simultaneous trades (e.g., grid or scaling), this would need to be expanded.
- **d. Persistent State:**
  - The `goldenCandleAppeared` flag is not persistent across EA restarts or chart reloads. If the EA is restarted, it will re-detect the first Golden Candle. If true persistence is required, this should be saved to a file or GlobalVariable.
- **e. Market Gaps and Slippage:**
  - There is no explicit handling for market gaps or slippage. This is typical for most EAs, but if the client wants extra safety, additional checks could be added.
- **f. Parameter Change Logging:**
  - The EA logs the initial setup, but does not log if the user changes parameters during runtime. If this is required, periodic or event-driven logging of parameter changes should be added.
- **g. Error Handling:**
  - The EA logs errors, but does not halt or alert the user if repeated errors occur. For unattended use, consider adding alerts or more robust error recovery.

### 3. Documentation and Transparency

- ✔️ The EA is well-instrumented for verification: all key events are logged, and chart objects make the logic visible.
- ✔️ The code is readable and parameters are explicit.
- ❓ If the client wants a user manual or more detailed in-code comments, this could be expanded.

### 4. Summary Table
| Requirement                  | Status | Comment                                      |
|------------------------------|:------:|----------------------------------------------|
| Golden Candle detection      |   ✔️   | Fully implemented, visual and logged         |
| Entry/exit logic             |   ✔️   | All rules present, robust                    |
| Lot progression              |   ✔️   | Table, capping, and logging                  |
| Chart visuals                |   ✔️   | Entry, SL, TP, Golden Candle rectangles      |
| Logging                      |   ✔️   | All key actions, errors, and setup logged    |
| Robustness (retry, SL/TP)    |   ✔️   | OrderSend retry, SL/TP adjust, fallback      |
| User adjustability           |   ✔️   | All key params are extern                    |
| EMA cross logic              |   ⚠️   | May need tightening if only after Golden Candle |
| Multi-trade support          |   ❌   | Only one trade at a time                     |
| Persistent state             |   ⚠️   | Not persistent across restarts               |
| Parameter change logging     |   ⚠️   | Only initial setup logged                    |
| Error handling/alerts        |   ⚠️   | Logs errors, but no user alert/halt on fail  |
> **Conclusion:**
> The EA is robust, explicit, and covers nearly all client requirements. The only possible gaps are in EMA cross logic timing, multi-trade support, persistent state, and parameter change logging. If the client needs any of these, further refinement is recommended.

Let me know if you want to address any of these points or need a more detailed review!

## 🐧 Install Terminal on Linux

The terminal runs on Linux using Wine. Wine is a free compatibility layer that allows application software developed for Microsoft Windows to run on Unix-like operating systems.

We have prepared a special script to make the installation process as simple as possible. The script will automatically detect your system version, based on which it will download and install the appropriate Wine package. After that, it will download and run the platform installer.

To start the installation, open the command line (Terminal) and specify the relevant command:

**For Ubuntu:**

```bash
wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4ubuntu.sh ; chmod +x mt4ubuntu.sh ; ./mt4ubuntu.sh
```

**For Debian:**

```bash
wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4debian.sh ; chmod +x mt4debian.sh ; ./mt4debian.sh
```

This command downloads the script, makes it executable and runs it. You only need to enter your account password to allow installation.

---

<div align="center">
    &copy; 2025 Moh Hamzawi. All rights reserved.<br>
    <sub>Developed by MHKAANICHE.<br>For support or questions, please refer to the project documentation.</sub>
</div>
