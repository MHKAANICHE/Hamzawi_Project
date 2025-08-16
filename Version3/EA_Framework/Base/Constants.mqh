//+------------------------------------------------------------------+
//|                                                          Constants.mqh |
//|                                     Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"
#property strict

//--- Trading Constants
#define DEFAULT_MAGIC_NUMBER            123456
#define DEFAULT_SLIPPAGE               3
#define DEFAULT_SPREAD_LIMIT           20        // Maximum allowed spread in points
#define MIN_LOTS                       0.01      // Minimum lot size
#define MAX_LOTS                       100.0     // Maximum lot size
#define DEFAULT_RISK_PERCENT           2.0       // Default risk per trade

//--- Golden Candle Parameters
#define MIN_GOLDEN_CANDLE_SIZE        10        // Minimum size in points
#define MAX_GOLDEN_CANDLE_SIZE        1000      // Maximum size in points
#define DEFAULT_GOLDEN_CANDLE_SIZE    100       // Default size in points

//--- Emergency Parameters
#define MAX_DAILY_LOSS_PERCENT        5.0       // Maximum daily loss before stopping
#define MAX_DRAWDOWN_PERCENT          20.0      // Maximum drawdown before stopping
#define MAX_CONSECUTIVE_LOSSES        5         // Maximum consecutive losses before stopping

//--- Time Constants
#define DEFAULT_START_HOUR            1         // Default trading start hour (GMT)
#define DEFAULT_END_HOUR             23        // Default trading end hour (GMT)
#define DEFAULT_FRIDAY_END_HOUR      21        // Early close on Friday (GMT)
#define SUNDAY_START_HOUR            22        // Sunday market open (GMT)

//--- Performance Thresholds
#define MIN_TICK_LATENCY_MS          10        // Minimum acceptable tick processing time
#define MAX_TICK_LATENCY_MS          100       // Maximum acceptable tick processing time
#define MAX_HISTORY_LOAD_MS          5000      // Maximum time to load history
#define MAX_CALCULATION_TIME_MS      50        // Maximum time for calculations per tick

//--- Error Codes
#define ERR_INVALID_GOLDEN_CANDLE    10001     // Invalid Golden Candle size
#define ERR_SPREAD_TOO_HIGH          10002     // Spread exceeds limit
#define ERR_SLIPPAGE_TOO_HIGH        10003     // Slippage exceeds limit
#define ERR_OUTSIDE_TRADING_HOURS    10004     // Outside allowed trading hours
#define ERR_MAX_DAILY_LOSS           10005     // Maximum daily loss reached
#define ERR_MAX_DRAWDOWN             10006     // Maximum drawdown reached
#define ERR_CONSECUTIVE_LOSSES       10007     // Too many consecutive losses

//--- DLL Settings
#define DLL_ALLOWED                  false     // DLL usage flag
#define DLL_CONFIRM_REQUIRED         true      // Require confirmation for DLL operations

//--- Version Control
#define MIN_MT4_BUILD               500        // Minimum required MT4 build
#define CURRENT_EA_VERSION          "1.0"      // Current EA version

//--- VPS Settings
#define VPS_RECOMMENDED             true       // VPS usage recommendation
#define MIN_NETWORK_SPEED           1.0        // Minimum network speed in Mbps

//--- Broker Compatibility
#define REQUIRE_HEDGE_ALLOWED       false      // Require hedging capability
#define REQUIRE_FIFO_DISABLED       false      // Require FIFO rule disabled
#define MIN_BROKER_DIGITS           2          // Minimum decimal places
#define MAX_BROKER_DIGITS           5          // Maximum decimal places

//--- Testing Parameters
#define MIN_TEST_PERIOD_MONTHS      12         // Minimum backtest period
#define MIN_MODELING_QUALITY        90         // Minimum modeling quality percentage
#define MIN_PROFIT_FACTOR          1.5         // Minimum acceptable profit factor
#define MIN_RECOVERY_FACTOR        1.0         // Minimum recovery factor
#define MAX_RELATIVE_DRAWDOWN      30.0        // Maximum relative drawdown percentage
