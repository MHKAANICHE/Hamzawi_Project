# GoldenCandle EA - Implementation Requirements

## 1. External Input Parameters

### 1.1 Core Parameters
```cpp
input double   LotSize = 0.01;          // Fixed lot size for trades
input int      BaseSL = 10000;          // Base stop loss and Golden Candle size (points)
```

### 1.2 Indicator Parameters
```cpp
// Parabolic SAR
input double   SAR_Step = 0.001;        // Parabolic SAR Step
input double   SAR_Maximum = 0.2;       // Parabolic SAR Maximum
input color    SAR_Color = clrOrange;   // Parabolic SAR Color

// Moving Averages
input int      FastMA_Period = 1;       // Fast MA Period
input int      FastMA_Shift = 0;        // Fast MA Shift
input int      SlowMA_Period = 3;       // Slow MA Period
input int      SlowMA_Shift = 1;        // Slow MA Shift
```

## 2. Trading Logic

### 2.1 Entry Conditions
```pseudocode
// Buy Entry
IF (SAR_Direction changes DOWN to UP) AND
   (Price crosses above SAR) AND
   (SAR is below Price) AND
   (NOT continuous SAR) AND
   (NO open positions):
   Place_Pending_Buy(Close + 3500)

// Sell Entry (Mirror)
IF (SAR_Direction changes UP to DOWN) AND
   (Price crosses below SAR) AND
   (SAR is above Price) AND
   (NOT continuous SAR) AND
   (NO open positions):
   Place_Pending_Sell(Close - 3500)
```

### 2.2 Lot Size and Take Profit Structure

```cpp
// Order qualification system for split orders management
enum ORDER_QUALIFICATION {
    LEVEL_1_MAIN = 1001,      // Single order levels (1-6)
    LEVEL_7_FIRST = 7001,     // First order of level 7
    LEVEL_7_SECOND = 7002,    // Second order of level 7
    LEVEL_8_FIRST = 8001,     // First order of level 8
    LEVEL_8_SECOND = 8002,    // And so on...
    // ... Define all split order qualifications
};

struct LevelSetup {
    int level;                    // Trading level (1-25)
    double baseLot;              // Base lot size (always 0.01)
    int numOrders;               // Number of simultaneous orders
    double[] RR;                 // Risk:Reward ratios for each order
    ORDER_QUALIFICATION[] quals; // Qualification IDs for order identification
};

// Example Levels:
LevelSetup[1] = {1, 0.01, 1, [2]};                  // Level 1: 0.01 lot, R:R = 1:2
LevelSetup[2] = {2, 0.01, 1, [3]};                  // Level 2: 0.01 lot, R:R = 1:3
LevelSetup[3] = {3, 0.01, 1, [4]};                  // Level 3: 0.01 lot, R:R = 1:4
LevelSetup[4] = {4, 0.01, 1, [5]};                  // Level 4: 0.01 lot, R:R = 1:5
LevelSetup[5] = {5, 0.01, 1, [6]};                  // Level 5: 0.01 lot, R:R = 1:6
LevelSetup[6] = {6, 0.01, 1, [7]};                  // Level 6: 0.01 lot, R:R = 1:7

// Advanced Levels with Split Orders:
LevelSetup[7] = {7, 0.01, 2, [1,7]};               // Level 7: Two 0.01 lot orders
LevelSetup[8] = {8, 0.01, 2, [3,7]};               // Level 8: Two 0.01 lot orders
LevelSetup[9] = {9, 0.01, 2, [5,7]};               // Level 9: Two 0.01 lot orders
LevelSetup[10] = {10, 0.01, 2, [7,7]};             // Level 10: Two 0.01 lot orders

// Triple Split Orders:
LevelSetup[11] = {11, 0.01, 3, [3,7,7]};          // Level 11: Three 0.01 lot orders
LevelSetup[12] = {12, 0.01, 3, [5,7,7]};          // Level 12: Three 0.01 lot orders
```

## 3. User Interface

### 3.1 Chart Display (Upper Left Corner)
```cpp
// Not available in backtest mode
class ChartControl {
    // System Controls
    Button PauseButton;         // Pause/Resume trading
    Button LevelPrevButton;     // Go to previous level
    Button LevelNextButton;     // Go to next level
    Button ApplyLevelButton;    // Apply selected level
    
    // Level Display
    Label SelectedLevel;        // Shows selected level (pending confirmation)
    Label CurrentLevel;         // Shows current active level
    Label ActiveOrders;         // Shows active order details
    
    // Level Selection State
    int pendingLevelSelection; // Stores the selected but not yet applied level
    
    void OnLevelChange(bool forward) {
        // Update pendingLevelSelection
        // Update visual indicator
        // Wait for ApplyLevelButton click
    }
    
    void OnApplyLevel() {
        // Show confirmation dialog
        // If confirmed:
        // 1. Update TradingManager's next level setup
        // 2. Keep progression state (don't restart)
        // 3. Show confirmation message
    }
    
    // Visual Level System
    void DrawLevelProgress() {
        // Visual representation of levels 1-25
        // Color coding:
        // - Green: Completed levels
        // - Yellow: Current level
        // - Gray: Future levels
        // Each level shows:
        // - Level number
        // - Number of orders
        // - R:R setup
    }
}
```

## 4. Stop Loss Management

```cpp
class StopLossManager {
    double base_sl;                 // Base stop loss (points, adjusted for digits)
    int breakeven_level = 3;        // Move to breakeven at 3rd target
    int first_level_move = 6;       // Move to first level at 6th target
    
    void Initialize(string symbol) {
        // Adjust base_sl based on symbol digits
        int digits = SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        base_sl = NormalizeDouble(10000.0 * Point, digits); // Normalize for symbol
    }
    
    void UpdateStopLoss(double current_profit) {
        // current_profit: The current floating profit in points
        // Example: If trade is 30 points in profit, current_profit = 30
        if(current_profit >= breakeven_level * base_sl)
            MoveToBreakeven();
        if(current_profit >= first_level_move * base_sl)
            MoveToFirstLevel();
    }
}
```

## 5. Risk Management
- Fixed lot size trading (user-defined)
- No dynamic position sizing
- Base stop loss normalized based on symbol digits (default 10000 points, adjusted per broker's digit settings)
- Take profits based on R:R ratios only
- No additional risk checks required

## 6. Trading Rules
1. One trade at a time
2. Entry based on SAR and MA signals
3. Fixed reference line placement (±3500 points)
4. Level progression based on trade outcomes
5. Multiple orders per level (7 onwards)
6. Fixed lot size throughout
7. No automated risk management

This specification focuses on the exact client requirements while removing unrequested features and automated protections. The system relies on fixed parameters and manual control rather than automated risk management.
