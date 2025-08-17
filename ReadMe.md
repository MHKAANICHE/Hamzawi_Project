# GoldenShell EA (MT4)

An advanced automated trading system for MetaTrader 4, combining **Golden Candle validation**, **Moving Average & SAR filters**, and a **25-level money management system**.

## 🚀 Features
- Fully automated entry/exit logic
- Money Management with hardcoded 25-level progression table
- Single-trade safeguard (only one active/pending order per symbol)
- Auto cancel of invalid pending orders on reversal
- SL/TP distance auto-adjust to avoid error 130
- Visual overlay panel (entry, SL/TP, P&L, active/planned levels)
- On-chart control buttons (mode toggle, apply, quick level planning)

## 📂 Project Structure
MQL4/Experts/GoldenShell.mq4
MQL4/Include/Utils.mqh
MQL4/Include/Indicators.mqh
MQL4/Include/GoldenCandle.mqh
MQL4/Include/LevelSystem.mqh
MQL4/Include/OrderManager.mqh
MQL4/Include/UI.mqh


## ⚙️ Inputs
- `LotSizeStart` – starting lot size
- `GoldenCandleSizePips` – user-defined candle size
- `Slippage` – max allowed slippage
- `SAR_Step` / `SAR_Max` – SAR parameters
- `ShowOverlay` – show/hide chart panel
- `DebugLog` – enable verbose logs

## 📊 Money Management
- 25-level progression table (hardcoded)
- After SL → advance to next level
- After TP → reset to Level 1
- Lot size and RR increase progressively to recover losses

## 🖥️ Usage
1. Copy all files to `MQL4/Experts` and `MQL4/Include`
2. Compile `GoldenShell.mq4`
3. Attach to chart, enable AutoTrading
4. Configure inputs
5. Watch overlay for real-time status

## 🧩 Edge Case Handling
- Pending orders are auto-canceled if conditions reverse
- Only one trade active at a time
- SL/TP automatically adjusted if too close to market

## 📜 License
MIT License (for research and educational use).
