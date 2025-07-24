
# Technical Documentation: Hamzawi MT4 Expert Advisor

## Introduction
This document provides a detailed technical description of the MT4 Expert Advisor (EA) as specified in the client requirements (see "EA Forex.pdf").

## Strategy Summary
The EA automates trading using:
- Parabolic SAR (PSAR)
- Two Exponential Moving Averages (EMA)
- A user-defined "Golden Candle" (fake candle, size input by user)

## Inputs/Parameters (All modifiable)
- **Lot Size**: Initial lot size for first entry (default: 0.01)
- **Parabolic SAR**: Step (default: 0.001), Max (default: 0.2), Color (default: green)
- **EMA 1**: Period 1, Exponential, shift 0, apply to Close, Style: Yellow
- **EMA 3**: Period 3, Exponential, shift 1, apply to Close, Style: Red
- **Golden Candle**: The candle where a new PSAR dot appears under price (for buy) or above price (for sell). This is the 'First Candle' and its size is defined as the High minus the Low (High-Low) of that candle, as confirmed by client screenshots. This value is used for entry and stop calculations.

**All parameters will be declared as 'extern' variables in the MT4 EA, so the client can easily adjust them from the EA settings panel.**

## Trade Entry Logic

### Buy Entry
#### First Buy Entry Case
1. PSAR dots are above price and then a new PSAR dot appears below price (on a new closed candle, called the "Golden Candle" or "First Candle").
2. Calculate the Entry Line:
   - Golden Candle size = High - Low of the Golden Candle
   - Entry Line = Top of Golden Candle (First Candle) body + (35% of Golden Candle size)
3. When any subsequent candle crosses the Entry Line, issue a Buy order.
4. Stop Loss (SL) = Golden Candle size (distance below entry)
5. Take Profit (TP) = 2 × SL (distance above entry, only for first entry)

#### Second Buy Entry Case
1. If no entry from the first case, or if SL is hit:
2. When EMA 1 crosses EMA 3 upwards on a closed candle, issue a Buy order.
3. SL = Golden Candle size (distance below entry)

### Sell Entry
*All logic is the opposite of Buy logic:*
1. PSAR dots below price, new dot appears above price (Golden Candle/First Candle)
2. Calculate the Entry Line:
   - Golden Candle size = High - Low of the Golden Candle
   - Entry Line = Bottom of Golden Candle (First Candle) body - (35% of Golden Candle size)
3. Sell when price crosses Entry Line
4. SL = Golden Candle size (distance above entry)
5. TP = 2 × SL (distance below entry, only for first entry)
6. Second entry: EMA 1 crosses EMA 3 downwards, SL = Golden Candle size (distance above entry)

## Chart Levels Structure
The following levels must be drawn on the chart for each trade:
1. **Entry Level**: Price of entry (marked as 0)
2. **Stop Loss Line**: Price of SL (marked as -1)
3. **Stop Loss Value**: Distance between entry and SL
4. **Level 1**: Entry + 1 × SL value (marked as 1)
5. **Level 2**: Entry + 2 × SL value (marked as 2)
6. **Level 3**: Entry + 3 × SL value (marked as 3)
7. **Level 4**: Entry + 4 × SL value (marked as 4)
8. **Level 5**: Entry + 5 × SL value (marked as 5)
9. **Level 6**: Entry + 6 × SL value (marked as 6)
10. **Level 7**: Entry + 7 × SL value (marked as 7)

*For Sell orders, levels are subtracted from entry.*

## Trailing Stop Loss
1. When price reaches Level 3, move SL to Entry Level (break-even)
2. When price reaches Level 6, move SL to Level 1

## Exit Conditions
1. PSAR changes position (dot flips to opposite side)
2. Take Profit target reached
3. Stop Loss hit

## Order Management
- Only one order is allowed at a time. New entries are only permitted after the previous trade is closed (by TP, SL, or exit condition).

## Lot Sizing & Entry Table
Start with the initial lot size (default: 0.01). If SL is hit, repeat the entry process using the following lot progression table:

| # | Lot Size | Lot Entry | Target for Each Lot |
|---|----------|-----------|---------------------|
| 1 | 0.01     | 1         | 2                   |
| 2 | 0.01     | 1         | 3                   |
| 3 | 0.01     | 1         | 4                   |
| 4 | 0.01     | 1         | 5                   |
| 5 | 0.01     | 1         | 6                   |
| 6 | 0.01     | 1         | 7                   |
| 7 | 0.02     | 2         | 1+7                 |
| 8 | 0.02     | 2         | 3+7                 |
| 9 | 0.02     | 2         | 5+7                 |
|10 | 0.02     | 2         | 7+7                 |
|11 | 0.03     | 3         | 3+7+7               |
|12 | 0.03     | 3         | 5+7+7               |
|13 | 0.04     | 4         | 1+7+7+7             |
|14 | 0.04     | 4         | 5+7+7+7             |
|15 | 0.05     | 5         | 2+7+7+7+7           |
|16 | 0.05     | 5         | 7+7+7+7+7           |
|17 | 0.06     | 6         | 5+7+7+7+7+7         |
|18 | 0.07     | 7         | 4+7+7+7+7+7+7       |
|19 | 0.08     | 9         | 4+7+7+7+7+7+7+7     |
|20 | 0.09     | 9         | 5+7+7+7+7+7+7+7+7   |
|21 | 0.10     |10         | 7+7+7+7+7+7+7+7+7+7 |
|22 | 0.12     |12         | 3+7+7+7+7+7+7+7+7+7+7+7 |
|23 | 0.14     |14         | 1+7+7+7+7+7+7+7+7+7+7+7+7+7 |
|24 | 0.16     |16         | 1+7+7+7+7+7+7+7+7+7+7+7+7+7+7+7 |
|25 | 0.18     |18         | 3+7+7+7+7+7+7+7+7+7+7+7+7+7+7+7+7+7 |

*After each SL, move to the next lot size in the table. Reset to the first lot after a win.*

## Parameter Defaults
- Parabolic SAR: Step = 0.001, Max = 0.2, Color = green
- EMA 1: Period = 1, Method = Exponential, Shift = 0, Apply to = Close, Style = Yellow
- EMA 3: Period = 3, Method = Exponential, Shift = 1, Apply to = Close, Style = Red
- Golden Candle: User input
- Lot Size: User input (default 0.01)

## Chart Visuals
- Draw all levels (Entry, SL, 1-7) as horizontal lines, labeled as specified
- Use color coding for clarity (e.g., green for entry, red for SL, blue for profit levels)

## File Reference
- `EA Forex.pdf`: Original client requirements
- `README.md`: Project overview and usage
- `Technical_Documentation.md`: This technical description

## Backtesting the EA: Step-by-Step Manual for Non-Programmers
To help you backtest the EA in MetaTrader 4 (MT4), follow these steps:
1. Open MetaTrader 4.
2. Go to the "View" menu and select "Strategy Tester" (or press Ctrl+R).
3. In the Strategy Tester panel at the bottom:
   - Select the EA from the "Expert Advisor" dropdown.
   - Choose the desired financial instrument (symbol) from the "Symbol" dropdown.
   - Select the timeframe you want to test.
   - Set the "Model" to "Every tick" for the most accurate results.
   - Check the "Visual mode" box to see trades and indicators on the chart as the test runs.
   - Adjust the speed slider to control how fast the backtest runs.
   - Set the date range for your test if needed.
4. Click "Start" to begin the backtest.
5. Watch the chart as the EA trades according to the strategy. You can pause, speed up, or slow down the test at any time.

## Automatic Indicator Display
The EA is designed to automatically display all required indicators (Parabolic SAR, EMA 1, EMA 3, and chart levels) on the chart during both live trading and backtesting. No manual indicator setup is required.

## Notes
- Images and chart examples are described in the PDF and can be referenced for further clarification.

## Developer Decisions for Ambiguities
Where the client requirements were ambiguous or not fully specified, the following principles were applied:
- The most logical and standard trading practice was chosen to fill any gaps.
- All calculations and logic are based on the explicit rules provided; if a rule was unclear, the approach that best fits the overall strategy and risk management was implemented.
- Any such decisions are documented in this technical document at the relevant section.

If further clarification is provided by the client in the future, the EA and this documentation can be updated accordingly.

## Open Suggestions for Further Clarification
The following minor points are noted for possible future clarification from the client. They are not addressed in the current implementation:
- Whether EMA cross signals should be based strictly on candle close or if intra-candle crosses are considered.
- How the EA should behave in case of platform restarts or market gaps during an open trade.
- More detailed chart visual guidelines (e.g., exact color codes, line styles, or example screenshots).
