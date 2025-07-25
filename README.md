

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
        <h3>1. Explicitness of Client Requirements</h3>
        <ul>
            <li><b>a. Golden Candle Logic</b>
                <ul>
                    <li>✔️ The EA detects Golden Candles using Parabolic SAR and price action, as specified.</li>
                    <li>✔️ It only starts trading after the first Golden Candle appears, as now required.</li>
                    <li>✔️ It draws a rectangle on the chart for each Golden Candle, making detection explicit.</li>
                </ul>
            </li>
            <li><b>b. Entry Logic</b>
                <ul>
                    <li>✔️ Entry is only allowed after a Golden Candle appears.</li>
                    <li>✔️ Both Buy and Sell entries are handled, with correct calculation of entry, SL, and TP.</li>
                    <li>✔️ EMA cross entries are implemented, with fallback to ATR if GoldenCandleSize is not set.</li>
                </ul>
            </li>
            <li><b>c. Lot Progression</b>
                <ul>
                    <li>✔️ Lot progression table is implemented and capped.</li>
                    <li>✔️ Lot index advances on SL, resets on TP, and is logged.</li>
                </ul>
            </li>
            <li><b>d. Chart Visuals</b>
                <ul>
                    <li>✔️ Entry, SL, and profit levels are drawn on the chart.</li>
                    <li>✔️ Golden Candle rectangles are drawn for visual verification.</li>
                </ul>
            </li>
            <li><b>e. Logging and Debugging</b>
                <ul>
                    <li>✔️ All key actions (setup, entry, exit, errors, SL/TP adjustments, waiting for Golden Candle) are logged to a CSV file and the Experts tab.</li>
                    <li>✔️ SL/TP distance and StopLevel fallback are logged for broker compliance.</li>
                </ul>
            </li>
            <li><b>f. Robustness</b>
                <ul>
                    <li>✔️ OrderSend is retried up to 3 times.</li>
                    <li>✔️ SL/TP are adjusted if too close to price, with fallback if StopLevel is zero.</li>
                    <li>✔️ MagicNumber is used for trade identification.</li>
                </ul>
            </li>
            <li><b>g. User Adjustability</b>
                <ul>
                    <li>✔️ All key parameters are extern and user-adjustable.</li>
                </ul>
            </li>
        </ul>
        <h3>2. Areas for Improvement or Clarification</h3>
        <ul>
            <li><b>a. Golden Candle Detection</b><br>
                The EA only looks for the most recent Golden Candle (from shift=1). If multiple Golden Candles appear in history, only the latest is considered for entry. This is generally correct, but if the client wants to trade every Golden Candle, a loop or queue would be needed.
            </li>
            <li><b>b. EMA Cross Logic</b><br>
                EMA cross entries are allowed on every bar after the first Golden Candle, not just immediately after a Golden Candle. If the client wants EMA cross entries only when a Golden Candle is present, this logic should be tightened.
            </li>
            <li><b>c. Trade Management</b><br>
                The EA only manages one trade at a time (<code>inTrade</code> flag). If the client wants multiple simultaneous trades (e.g., grid or scaling), this would need to be expanded.
            </li>
            <li><b>d. Persistent State</b><br>
                The <code>goldenCandleAppeared</code> flag is not persistent across EA restarts or chart reloads. If the EA is restarted, it will re-detect the first Golden Candle. If true persistence is required, this should be saved to a file or GlobalVariable.
            </li>
            <li><b>e. Market Gaps and Slippage</b><br>
                There is no explicit handling for market gaps or slippage. This is typical for most EAs, but if the client wants extra safety, additional checks could be added.
            </li>
            <li><b>f. Parameter Change Logging</b><br>
                The EA logs the initial setup, but does not log if the user changes parameters during runtime. If this is required, periodic or event-driven logging of parameter changes should be added.
            </li>
            <li><b>g. Error Handling</b><br>
                The EA logs errors, but does not halt or alert the user if repeated errors occur. For unattended use, consider adding alerts or more robust error recovery.
            </li>
        </ul>
        <h3>3. Documentation and Transparency</h3>
        <ul>
            <li>✔️ The EA is well-instrumented for verification: all key events are logged, and chart objects make the logic visible.</li>
            <li>✔️ The code is readable and parameters are explicit.</li>
            <li>❓ If the client wants a user manual or more detailed in-code comments, this could be expanded.</li>
        </ul>
        <h3>4. Summary Table</h3>
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
    </div>

---

<div align="center">
    &copy; 2025 Moh Hamzawi. All rights reserved.<br>
    <sub>Developed by MHKAANICHE.<br>For support or questions, please refer to the project documentation.</sub>
</div>
