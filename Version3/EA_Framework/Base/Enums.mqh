//+------------------------------------------------------------------+
//|                                                             Enums.mqh |
//|                                     Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"
#property strict

//--- Trading States
enum ENUM_TRADING_STATE {
    STATE_ACTIVE,              // Normal trading
    STATE_SUSPENDED,           // Trading temporarily suspended
    STATE_STOPPED,            // Trading stopped (emergency)
    STATE_INITIALIZING,       // System initializing
    STATE_ERROR               // Error state
};

//--- Signal Types
enum ENUM_SIGNAL_TYPE {
    SIGNAL_GOLDEN_CANDLE_BUY,  // Golden Candle buy signal
    SIGNAL_GOLDEN_CANDLE_SELL, // Golden Candle sell signal
    SIGNAL_EMA_CROSS_BUY,      // EMA cross buy signal
    SIGNAL_EMA_CROSS_SELL,     // EMA cross sell signal
    SIGNAL_PSAR_BUY,           // PSAR buy signal
    SIGNAL_PSAR_SELL,          // PSAR sell signal
    SIGNAL_NONE                // No signal
};

//--- Risk Levels
enum ENUM_RISK_LEVEL {
    RISK_VERY_LOW,            // Very low risk
    RISK_LOW,                 // Low risk
    RISK_MEDIUM,              // Medium risk
    RISK_HIGH,                // High risk
    RISK_VERY_HIGH           // Very high risk
};

//--- Time Periods
enum ENUM_TIME_RESTRICTION {
    TIME_ALWAYS_ALLOW,        // Always allow trading
    TIME_STANDARD_SESSION,    // Standard session only
    TIME_CUSTOM_SESSION,      // Custom session times
    TIME_NO_FRIDAY,           // No trading on Friday
    TIME_NO_NFP               // No trading on NFP days
};

//--- Error Severity
enum ENUM_ERROR_SEVERITY {
    SEVERITY_INFO,            // Information only
    SEVERITY_WARNING,         // Warning - can continue
    SEVERITY_ERROR,           // Error - may need attention
    SEVERITY_CRITICAL         // Critical - must stop trading
};

//--- Market Conditions
enum ENUM_MARKET_CONDITION {
    MARKET_NORMAL,            // Normal trading conditions
    MARKET_VOLATILE,          // High volatility
    MARKET_RANGING,           // Ranging market
    MARKET_TRENDING,          // Trending market
    MARKET_NEWS              // High impact news
};

//--- License Types
enum ENUM_LICENSE_TYPE {
    LICENSE_DEMO,             // Demo version
    LICENSE_BASIC,            // Basic license
    LICENSE_PREMIUM,          // Premium license
    LICENSE_ENTERPRISE        // Enterprise license
};

//--- Strategy Modes
enum ENUM_STRATEGY_MODE {
    MODE_GOLDEN_CANDLE_ONLY,  // Only Golden Candle signals
    MODE_EMA_ONLY,            // Only EMA signals
    MODE_COMBINED,            // Combined signals
    MODE_CUSTOM               // Custom strategy
};

//--- Alert Types
enum ENUM_ALERT_TYPE {
    ALERT_NONE,              // No alerts
    ALERT_POPUP,             // Popup alerts
    ALERT_EMAIL,             // Email alerts
    ALERT_PUSH,              // Push notifications
    ALERT_ALL                // All alert types
};

//--- Performance Levels
enum ENUM_PERFORMANCE_LEVEL {
    PERF_OPTIMAL,            // Optimal performance
    PERF_GOOD,               // Good performance
    PERF_ACCEPTABLE,         // Acceptable performance
    PERF_POOR,               // Poor performance
    PERF_CRITICAL            // Critical performance
};
