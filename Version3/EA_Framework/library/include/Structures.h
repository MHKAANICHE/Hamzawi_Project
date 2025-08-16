#ifndef GOLDEN_CANDLE_STRUCTURES_H
#define GOLDEN_CANDLE_STRUCTURES_H

#include "Enums.h"
#include "Constants.h"

// Market Data Structure
struct MqlRates {
    long    time;          // Period start time
    double  open;          // Open price
    double  high;          // High price
    double  low;           // Low price
    double  close;         // Close price
    double  tick_volume;   // Tick volume
    int     spread;        // Spread
    double  real_volume;   // Real volume
};

// Signal Information Structure
struct SSignalInfo {
    ENUM_SIGNAL_TYPE type;  // Type of signal
    long            time;   // Signal time
    double          price;  // Signal price
    double          entryPrice;  // Entry price
    double          stopLoss;    // Stop loss
    double          takeProfit;  // Take profit
    double          lots;        // Lot size
    char            comment[256]; // Order comment

    void Clear() {
        type = SIGNAL_NONE;
        time = 0;
        price = entryPrice = stopLoss = takeProfit = lots = 0.0;
        comment[0] = '\0';
    }
};

// Golden Candle Structure
struct SGoldenCandle {
    long     time;         // Candle time
    double   open;         // Open price
    double   high;         // High price
    double   low;          // Low price
    double   close;        // Close price
    double   size;         // Candle size
    double   entryLine;    // Entry line
    bool     isValid;      // Validity flag
    char     invalidReason[256]; // Invalid reason

    void Clear() {
        time = 0;
        open = high = low = close = size = entryLine = 0.0;
        isValid = false;
        invalidReason[0] = '\0';
    }
};

#endif // GOLDEN_CANDLE_STRUCTURES_H
