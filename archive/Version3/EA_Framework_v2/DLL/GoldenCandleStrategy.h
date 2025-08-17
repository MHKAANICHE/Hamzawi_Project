#pragma once
#include <windows.h>

// DLL Export definitions
#define DLL_EXPORT extern "C" __declspec(dllexport)

// SAR Direction enum
enum SARDirection {
    SAR_DOWN,
    SAR_UP,
    SAR_UNKNOWN
};

// SAR State structure
struct SARState {
    double currentSAR;
    double extremePoint;
    double accelerationFactor;
    SARDirection direction;
    bool isInitialized;
    bool isContinuous;
    int consecutiveCount;
};

// Strategy parameters structure
struct GoldenCandleParams {
    // SAR Parameters
    double sarStep;
    double sarMaximum;
    
    // MA Parameters
    int fastMAPeriod;
    int fastMAShift;
    int slowMAPeriod;
    int slowMAShift;
    
    // Entry Parameters
    double entryOffset;    // 3500 points offset
    double baseSL;         // 10000 points base
    
    // Level Parameters
    int currentLevel;
    int numOrders;
};

// Technical Analysis Functions
DLL_EXPORT bool __stdcall InitStrategy();
DLL_EXPORT void __stdcall DeinitStrategy();
DLL_EXPORT bool __stdcall UpdateIndicators(
    const double open[], const double high[],
    const double low[], const double close[],
    const double volume[], int bars);
DLL_EXPORT bool __stdcall CheckBuySignal();
DLL_EXPORT bool __stdcall CheckSellSignal();
DLL_EXPORT double __stdcall CalculateEntryPrice(bool isBuy);
DLL_EXPORT double __stdcall CalculateStopLoss(bool isBuy, double entryPrice);
DLL_EXPORT double __stdcall CalculateTakeProfit(int orderIndex, bool isBuy, double entryPrice, double stopLoss);
DLL_EXPORT void __stdcall SetParameters(const GoldenCandleParams* params);
