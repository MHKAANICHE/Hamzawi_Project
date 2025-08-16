//+------------------------------------------------------------------+
//|                                                       Structures.mqh |
//|                                     Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"
#property strict

#include "Enums.mqh"
#include "Constants.mqh"

//--- Signal Information Structure
struct SSignalInfo {
    ENUM_SIGNAL_TYPE   type;           // Type of signal
    datetime          time;           // Signal time
    double            price;          // Signal price
    double            stopLoss;       // Suggested stop loss
    double            takeProfit;     // Suggested take profit
    double            lots;           // Suggested lot size
    string            description;    // Signal description
    
    void Clear() {
        type = SIGNAL_NONE;
        time = 0;
        price = 0.0;
        stopLoss = 0.0;
        takeProfit = 0.0;
        lots = 0.0;
        description = "";
    }
};

//--- Golden Candle Structure
struct SGoldenCandle {
    datetime    time;           // Candle time
    double      open;           // Open price
    double      high;           // High price
    double      low;            // Low price
    double      close;          // Close price
    double      size;           // Candle size in points
    double      entryLine;      // Entry line price
    bool        isValid;        // Validity flag
    string      invalidReason;  // Reason if invalid
    
    void Clear() {
        time = 0;
        open = high = low = close = size = entryLine = 0.0;
        isValid = false;
        invalidReason = "";
    }
};

//--- Trade State Structure
struct STradeState {
    ENUM_TRADING_STATE state;          // Current trading state
    datetime          lastUpdateTime;  // Last update time
    int              consecutiveLosses;// Consecutive losses count
    double           dailyProfit;     // Current day's profit
    double           maxDrawdown;      // Maximum drawdown
    string           stateReason;     // Reason for current state
    
    void Clear() {
        state = STATE_INITIALIZING;
        lastUpdateTime = 0;
        consecutiveLosses = 0;
        dailyProfit = 0.0;
        maxDrawdown = 0.0;
        stateReason = "";
    }
};

//--- Market State Structure
struct SMarketState {
    ENUM_MARKET_CONDITION condition;    // Current market condition
    double               spread;        // Current spread
    double               volatility;    // Current volatility
    bool                 isNewsTime;    // News period flag
    datetime            nextNewsTime;   // Next news event time
    bool                 isTradeable;   // Market tradeable flag
    string              untradableReason; // Reason if untradeable
    
    void Clear() {
        condition = MARKET_NORMAL;
        spread = 0.0;
        volatility = 0.0;
        isNewsTime = false;
        nextNewsTime = 0;
        isTradeable = false;
        untradableReason = "";
    }
};

//--- Performance Metrics Structure
struct SPerformanceMetrics {
    double   tickLatencyMs;     // Tick processing latency
    double   calculationTimeMs; // Calculation time
    double   memoryUsageMB;     // Memory usage
    int      objectCount;       // Chart object count
    datetime lastCheckTime;     // Last check time
    ENUM_PERFORMANCE_LEVEL level; // Current performance level
    
    void Clear() {
        tickLatencyMs = 0.0;
        calculationTimeMs = 0.0;
        memoryUsageMB = 0.0;
        objectCount = 0;
        lastCheckTime = 0;
        level = PERF_OPTIMAL;
    }
};

//--- Configuration Structure
struct SConfiguration {
    // Trading Parameters
    double            riskPercent;
    double            minLots;
    double            maxLots;
    int              magicNumber;
    int              slippage;
    double            maxSpread;
    
    // Strategy Parameters
    double            minGoldenCandleSize;
    double            maxGoldenCandleSize;
    ENUM_STRATEGY_MODE strategyMode;
    
    // Time Restrictions
    ENUM_TIME_RESTRICTION timeRestriction;
    int                  startHour;
    int                  endHour;
    
    // Risk Management
    double              maxDailyLoss;
    double              maxDrawdown;
    int                 maxConsecutiveLosses;
    
    // Notification Settings
    ENUM_ALERT_TYPE     alertType;
    bool                emailNotifications;
    bool                pushNotifications;
    
    void SetDefaults() {
        riskPercent = DEFAULT_RISK_PERCENT;
        minLots = MIN_LOTS;
        maxLots = MAX_LOTS;
        magicNumber = DEFAULT_MAGIC_NUMBER;
        slippage = DEFAULT_SLIPPAGE;
        maxSpread = DEFAULT_SPREAD_LIMIT;
        
        minGoldenCandleSize = MIN_GOLDEN_CANDLE_SIZE;
        maxGoldenCandleSize = MAX_GOLDEN_CANDLE_SIZE;
        strategyMode = MODE_COMBINED;
        
        timeRestriction = TIME_STANDARD_SESSION;
        startHour = DEFAULT_START_HOUR;
        endHour = DEFAULT_END_HOUR;
        
        maxDailyLoss = MAX_DAILY_LOSS_PERCENT;
        maxDrawdown = MAX_DRAWDOWN_PERCENT;
        maxConsecutiveLosses = MAX_CONSECUTIVE_LOSSES;
        
        alertType = ALERT_ALL;
        emailNotifications = true;
        pushNotifications = true;
    }
};
