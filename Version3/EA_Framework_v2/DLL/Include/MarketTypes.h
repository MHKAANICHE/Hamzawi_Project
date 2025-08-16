#pragma once

namespace GoldenCandle {

//+------------------------------------------------------------------+
//| Market data structures                                             |
//+------------------------------------------------------------------+
struct CandleData {
    double open;
    double high;
    double low;
    double close;
    long time;
    long volume;
};

struct MarketData {
    CandleData current;
    double bid;
    double ask;
    double point;
    int digits;
    double tickValue;
    double tickSize;
    int spread;
    bool tradeAllowed;
};

//+------------------------------------------------------------------+
//| Trading structures                                                 |
//+------------------------------------------------------------------+
struct EntryPoint {
    int type;           // Buy/Sell
    double price;
    double stopLoss;
    double takeProfit;
    double lots;
    int magicNumber;
    int slippage;
};

struct EntryLevel {
    double price;
    double lots;
    double riskReward;
    int qualification;
};

struct SignalInfo {
    bool isValid;
    bool isBuy;
    double price;
    double stopLoss;
    double riskReward;
};

//+------------------------------------------------------------------+
//| Configuration structures                                           |
//+------------------------------------------------------------------+
struct CoreConfig {
    char symbol[32];
    int timeframe;
    double sarStep;
    double sarMaximum;
    int maFastPeriod;
    int maSlowPeriod;
    double baseSize;
    double entryLevel;
};

struct CoreState {
    bool isInitialized;
    bool hasOpenPosition;
    int currentLevel;
    double currentProfit;
    double maxDrawdown;
};

} // namespace GoldenCandle
