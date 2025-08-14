# User Manual: GoldenCandleEA for MetaTrader 4

## Installation
1. Compile `GoldenCandleEA_v2.mq4` in MetaEditor to produce `GoldenCandleEA_v2.ex4`.
2. Compile `GoldenCandleEA_GUI.cpp` and `GoldenCandleEA_GUI.rc` to produce `GoldenCandleEA_GUI.dll`.
3. Copy `GoldenCandleEA_v2.ex4` to your MT4 `Experts` folder.
4. Copy `GoldenCandleEA_GUI.dll` to your MT4 `Libraries` folder.
5. Restart MetaTrader 4.

## Setup & Configuration
1. Open the MT4 Navigator panel, find `GoldenCandleEA_v2`, and drag it onto your desired chart.
2. In the EA settings dialog, adjust the following parameters as needed:
   - LotSize, MaxSpread, Slippage
   - GoldenCandleMinSize, GoldenCandleMaxSize
   - SharpeRatioTarget, MagicNumber, RiskPercent, MaxOrders, AlertSound
3. Click OK to activate the EA.

## Using the EA
- The EA will automatically detect Golden Candle setups and manage trades according to the strategy.
- The GUI dialog will appear periodically (or on user request) for manual actions:
   - Pause/Resume trading
   - Skip to next lot progression level
   - Place a manual order (with custom lot, entry, SL, TP)
   - Adjust minimum Golden Candle size
   - Ignore the current alert
- All actions and errors are logged for review.

## Backtesting
- Use the MT4 Strategy Tester (Ctrl+R) to backtest the EA. See `Technical_Documentation.md` for step-by-step instructions.

## Troubleshooting
- Ensure both the EA (`.ex4`) and DLL (`.dll`) are in the correct folders.
- If the GUI does not appear, check DLL permissions in MT4 (Tools > Options > Expert Advisors > Allow DLL imports).
- Review the Experts and Journal tabs for log messages.

## Support
- For questions or issues, refer to the documentation or contact the developer.
