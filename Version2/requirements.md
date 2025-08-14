# Golden Candle EA Version 2 – Requirements

## 1. Architecture
- MT4 EA (MQL4) as core, communicates with C++ DLLs.
- DLLs: GUI, technical logic, strategy, money management, alerts.
- Windows environment only.

## 2. User Inputs (extern)
- Lot size (initial, progression table)
- Parabolic SAR parameters
- EMA parameters
- Golden Candle size (min/max, manual or auto)
- Ladder step, number of levels
- Risk:Reward per attempt
- Magic number
- Color settings
- Enable/disable trading, pause, skip controls
- Slippage acceptance (pips)
- **Max spread accepted (pips)**
- Sharpe ratio target (for optimization)

## 3. Edge Cases
- Golden Candle too small/large (skip signal)
- OrderSend fails (retry, alert, manual intervention)
- StopLevel issues (block trade, alert)
- Market closed/untradable symbol (alert, skip)
- EMA cross before Golden Candle (ignore)
- Manual pause/skip (immediate effect)
- Parameter change during trade (apply next)
- Price gaps/slippage (respect input, alert)
- Trade closed externally (reset state)
- DLL/EA comm failure (alert, pause)

## 4. GUI (C++/HTML Mockup)
- Landing, settings, trade monitor, popups, alerts
- All user actions: input, alerts, ignore/choice buttons
- HTML mockups for internal dev only

## 5. MT4 Integration
- Subfolders: expert, include, library
- DLLs in library, EA in expert, shared headers in include

## 6. Testing & Documentation
- Demo/live, all edge cases, user manual, changelogs

---
