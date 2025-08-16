//+------------------------------------------------------------------+
//|                                             GoldenCandleEA_v2.mq4 |
//|                              Copyright 2025, Golden Candle Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle Team"
#property version   "2.0"
#property strict

// Import DLL strategy functions
#import "GoldenCandleStrategy.dll"
   bool __stdcall InitStrategy();
   void __stdcall DeinitStrategy();
   bool __stdcall UpdateIndicators(const double& price[], const double& volume[], int bars);
   bool __stdcall CheckBuySignal();
   bool __stdcall CheckSellSignal();
   double __stdcall CalculateEntryPrice(bool isBuy);
   double __stdcall CalculateStopLoss(bool isBuy, double entryPrice);
   double __stdcall CalculateTakeProfit(int orderIndex, bool isBuy, double entryPrice, double stopLoss);
   void __stdcall SetParameters(const GoldenCandleParams& params);
#import

// Include managers
#include "Include/OrderManager.mqh"
#include "Include/LevelManager.mqh"

// Input Parameters
input double   LotSize = 0.01;          // Fixed lot size
input int      BaseSL = 10000;          // Base stop loss (points)

// Indicator Parameters
input double   SAR_Step = 0.001;        // Parabolic SAR Step
input double   SAR_Maximum = 0.2;       // Parabolic SAR Maximum
input int      FastMA_Period = 1;       // Fast MA Period
input int      FastMA_Shift = 0;        // Fast MA Shift
input int      SlowMA_Period = 3;       // Slow MA Period
input int      SlowMA_Shift = 1;        // Slow MA Shift

//+------------------------------------------------------------------+
//| Expert initialization function                                      |
//+------------------------------------------------------------------+
int OnInit() {
    // Initialize managers
    if(!g_orderManager.Init(Symbol(), MagicNumber, &g_levelManager)) {
        Print("Failed to initialize OrderManager");
        return INIT_FAILED;
    }
    
    if(!g_levelManager.Init()) {
        Print("Failed to initialize LevelManager");
        return INIT_FAILED;
    }
    
    // Initialize strategy parameters
    GoldenCandleParams params;
    params.sarStep = SAR_Step;
    params.sarMaximum = SAR_Maximum;
    params.fastMAPeriod = FastMA_Period;
    params.fastMAShift = FastMA_Shift;
    params.slowMAPeriod = SlowMA_Period;
    params.slowMAShift = SlowMA_Shift;
    params.entryOffset = 3500;
    params.baseSL = BaseSL;
    params.currentLevel = g_levelManager.GetCurrentLevel();
    params.numOrders = g_levelManager.GetNumOrders();
    
    // Initialize strategy
    SetParameters(params);
    if(!InitStrategy()) {
        Print("Failed to initialize Strategy");
        return INIT_FAILED;
    }
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    DeinitStrategy();
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick() {
    // Skip if we already have a position
    if(g_orderManager.HasOpenPosition()) {
        ManageOpenPositions();
        return;
    }
    
    // Update indicators with latest data
    double prices[];
    double volumes[];
    int bars = 100; // Number of bars to analyze
    
    ArraySetAsSeries(prices, true);
    ArraySetAsSeries(volumes, true);
    ArrayResize(prices, bars);
    ArrayResize(volumes, bars);
    
    for(int i = 0; i < bars; i++) {
        prices[i] = iClose(Symbol(), PERIOD_CURRENT, i);
        volumes[i] = iVolume(Symbol(), PERIOD_CURRENT, i);
    }
    
    if(!UpdateIndicators(prices, volumes, bars)) return;
    
    // Check for signals
    if(CheckBuySignal()) {
        OpenPosition(true);
    }
    else if(CheckSellSignal()) {
        OpenPosition(false);
    }
}

//+------------------------------------------------------------------+
//| Open a new position                                                |
//+------------------------------------------------------------------+
void OpenPosition(bool isBuy) {
    double entryPrice = CalculateEntryPrice(isBuy);
    if(entryPrice <= 0) return;
    
    double stopLoss = CalculateStopLoss(isBuy, entryPrice);
    
    for(int i = 0; i < g_levelManager.GetNumOrders(); i++) {
        double takeProfit = CalculateTakeProfit(i, isBuy, entryPrice, stopLoss);
        
        if(!g_orderManager.OpenPosition(
            isBuy ? OP_BUY : OP_SELL,
            g_levelManager.GetLotSize(),
            entryPrice,
            stopLoss,
            takeProfit
        )) {
            Print("Failed to open position");
            return;
        }
    }
}

//+------------------------------------------------------------------+
//| Manage open positions                                              |
//+------------------------------------------------------------------+
void ManageOpenPositions() {
    if(!g_orderManager.HasOpenPosition()) return;
    
    // Update indicators
    double prices[];
    double volumes[];
    ArraySetAsSeries(prices, true);
    ArraySetAsSeries(volumes, true);
    ArrayResize(prices, 10);
    ArrayResize(volumes, 10);
    
    for(int i = 0; i < 10; i++) {
        prices[i] = iClose(Symbol(), PERIOD_CURRENT, i);
        volumes[i] = iVolume(Symbol(), PERIOD_CURRENT, i);
    }
    
    if(!UpdateIndicators(prices, volumes, 10)) return;
    
    // Check exit conditions
    if(OrderType() == OP_BUY && CheckSellSignal()) {
        g_orderManager.ClosePosition();
    }
    else if(OrderType() == OP_SELL && CheckBuySignal()) {
        g_orderManager.ClosePosition();
    }
}

// Global instances
COrderManager g_orderManager;
CLevelManager g_levelManager;
