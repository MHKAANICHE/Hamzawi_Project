#ifndef GOLDEN_CANDLE_CONSTANTS_H
#define GOLDEN_CANDLE_CONSTANTS_H

// Core Trading Constants
const double GOLDEN_CANDLE_ENTRY_OFFSET = 3500.0;     // Points from close for pending order
const double DEFAULT_BASE_SL = 10000.0;              // Base stop loss in points
const double DEFAULT_LOT_SIZE = 0.01;                // Fixed lot size
const int MAX_SPLIT_ORDERS = 3;                     // Maximum split orders per level
const int MAX_LEVEL = 25;                          // Maximum trading level
const bool ONE_TRADE_AT_TIME = true;               // Only one trade allowed at a time

// Trading Parameters
const double DEFAULT_RISK_PERCENT = 2.0;            // Default risk percentage
const double MIN_LOTS = 0.01;                      // Minimum lot size
const double MAX_LOTS = 100.0;                     // Maximum lot size
const int DEFAULT_MAGIC_NUMBER = 7777;             // Default magic number
const int DEFAULT_SLIPPAGE = 3;                   // Default maximum slippage
const int DEFAULT_SPREAD_LIMIT = 20;              // Default maximum spread

// Golden Candle Parameters
const double MIN_GOLDEN_CANDLE_SIZE = 10.0;        // Minimum size in points
const double MAX_GOLDEN_CANDLE_SIZE = 1000.0;      // Maximum size in points
const double DEFAULT_GOLDEN_CANDLE_SIZE = 100.0;   // Default size in points

#endif // GOLDEN_CANDLE_CONSTANTS_H
