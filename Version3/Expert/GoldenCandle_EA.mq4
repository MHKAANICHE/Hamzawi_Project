//+------------------------------------------------------------------+
//|                                              GoldenCandle_EA.mq4 |
//|                                           Copyright 2025, Golden Candle |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle"
#property version   "3.0"
#property strict

// Framework includes
#include "../EA_Framework/Base/Constants.mqh"
#include "../EA_Framework/Base/Enums.mqh"
#include "../EA_Framework/Base/Structures.mqh"
#include "../EA_Framework/Strategy/GoldenCandleStrategy.mqh"
#include "../EA_Framework/Technical/TradeManager.mqh"

//+------------------------------------------------------------------+
//| External Parameters                                                |
//+------------------------------------------------------------------+
// Fixed Parameters
extern double LotSize = 0.01;               // Fixed lot size for all trades

// Parabolic SAR Parameters
extern double SAR_Step = 0.001;             // Parabolic SAR Step
extern double SAR_Maximum = 0.2;            // Parabolic SAR Maximum
extern color  SAR_Color = clrOrange;        // Parabolic SAR Color

// Moving Average Parameters
extern int FastMA_Period = 1;               // Fast MA Period
extern int FastMA_Shift = 0;                // Fast MA Shift
extern int SlowMA_Period = 3;               // Slow MA Period
extern int SlowMA_Shift = 1;                // Slow MA Shift

// Stop Loss Parameter
extern int Base_SL = 10000;                 // Base stop loss in points

// Global Objects
CGoldenCandleStrategy* g_strategy = NULL;   // Strategy instance
CTradeManager* g_tradeManager = NULL;       // Trade manager instance
bool g_isBacktesting;                       // Backtesting flag

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit() {
    // Store backtesting state
    g_isBacktesting = IsTesting();
    
    // Initialize strategy
    g_strategy = new CGoldenCandleStrategy();
    if(!g_strategy.Init(Symbol(), Period(), SAR_Step, SAR_Maximum,
                       FastMA_Period, FastMA_Shift,
                       SlowMA_Period, SlowMA_Shift)) {
        Print("Failed to initialize strategy");
        return INIT_FAILED;
    }
    
    // Initialize trade manager
    g_tradeManager = new CTradeManager();
    if(!g_tradeManager.Init(Symbol(), LotSize, Base_SL)) {
        Print("Failed to initialize trade manager");
        return INIT_FAILED;
    }
    
    // Create chart controls (except in backtesting)
    if(!g_isBacktesting) {
        if(!CreateChartControls()) {
            Print("Failed to create chart controls");
            return INIT_FAILED;
        }
    }
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    // Clean up chart controls
    if(!g_isBacktesting) {
        RemoveChartControls();
    }
    
    // Clean up strategy
    if(g_strategy != NULL) {
        delete g_strategy;
        g_strategy = NULL;
    }
    
    // Clean up trade manager
    if(g_tradeManager != NULL) {
        delete g_tradeManager;
        g_tradeManager = NULL;
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick() {
    // Skip if trading is paused
    if(g_tradeManager.IsPaused())
        return;
        
    // Check for open orders
    if(OrdersTotal() > 0) {
        g_tradeManager.CheckOpenOrders();
        return;
    }
    
    // Check for new signals
    SSignalInfo signal;
    if(g_strategy.CheckSignal(signal)) {
        g_tradeManager.ProcessSignal(signal);
    }
}

//+------------------------------------------------------------------+
//| Create chart controls                                             |
//+------------------------------------------------------------------+
bool CreateChartControls() {
    // Create buttons in upper left corner
    if(!ObjectCreate(0, "btnPause", OBJ_BUTTON, 0, 0, 0)) return false;
    ObjectSetInteger(0, "btnPause", OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(0, "btnPause", OBJPROP_YDISTANCE, 10);
    ObjectSetString(0, "btnPause", OBJPROP_TEXT, "Pause");
    
    if(!ObjectCreate(0, "btnPrevLevel", OBJ_BUTTON, 0, 0, 0)) return false;
    ObjectSetInteger(0, "btnPrevLevel", OBJPROP_XDISTANCE, 80);
    ObjectSetInteger(0, "btnPrevLevel", OBJPROP_YDISTANCE, 10);
    ObjectSetString(0, "btnPrevLevel", OBJPROP_TEXT, "<<");
    
    if(!ObjectCreate(0, "btnNextLevel", OBJ_BUTTON, 0, 0, 0)) return false;
    ObjectSetInteger(0, "btnNextLevel", OBJPROP_XDISTANCE, 120);
    ObjectSetInteger(0, "btnNextLevel", OBJPROP_YDISTANCE, 10);
    ObjectSetString(0, "btnNextLevel", OBJPROP_TEXT, ">>");
    
    if(!ObjectCreate(0, "btnApplyLevel", OBJ_BUTTON, 0, 0, 0)) return false;
    ObjectSetInteger(0, "btnApplyLevel", OBJPROP_XDISTANCE, 160);
    ObjectSetInteger(0, "btnApplyLevel", OBJPROP_YDISTANCE, 10);
    ObjectSetString(0, "btnApplyLevel", OBJPROP_TEXT, "Apply");
    
    // Create level display label
    if(!ObjectCreate(0, "lblCurrentLevel", OBJ_LABEL, 0, 0, 0)) return false;
    ObjectSetInteger(0, "lblCurrentLevel", OBJPROP_XDISTANCE, 220);
    ObjectSetInteger(0, "lblCurrentLevel", OBJPROP_YDISTANCE, 15);
    UpdateLevelDisplay();
    
    return true;
}

//+------------------------------------------------------------------+
//| Remove chart controls                                             |
//+------------------------------------------------------------------+
void RemoveChartControls() {
    ObjectDelete(0, "btnPause");
    ObjectDelete(0, "btnPrevLevel");
    ObjectDelete(0, "btnNextLevel");
    ObjectDelete(0, "btnApplyLevel");
    ObjectDelete(0, "lblCurrentLevel");
}

//+------------------------------------------------------------------+
//| Update level display                                              |
//+------------------------------------------------------------------+
void UpdateLevelDisplay() {
    string levelText = "Level " + IntegerToString(g_tradeManager.GetCurrentLevel());
    ObjectSetString(0, "lblCurrentLevel", OBJPROP_TEXT, levelText);
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Chart event handler                                               |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam) {
    // Skip in backtest
    if(g_isBacktesting)
        return;
    
    // Handle button clicks
    if(id == CHARTEVENT_OBJECT_CLICK) {
        if(sparam == "btnPause") {
            if(g_tradeManager.IsPaused()) {
                g_tradeManager.ResumeTrading();
                ObjectSetString(0, "btnPause", OBJPROP_TEXT, "Pause");
            } else {
                g_tradeManager.PauseTrading();
                ObjectSetString(0, "btnPause", OBJPROP_TEXT, "Resume");
            }
        }
        else if(sparam == "btnPrevLevel") {
            if(g_tradeManager.SetPreviousLevel()) {
                UpdateLevelDisplay();
            }
        }
        else if(sparam == "btnNextLevel") {
            if(g_tradeManager.SetNextLevel()) {
                UpdateLevelDisplay();
            }
        }
        else if(sparam == "btnApplyLevel") {
            string message = "Change to Level " + 
                           IntegerToString(g_tradeManager.GetCurrentLevel()) + "?";
            if(MessageBox(message, "Level Change", MB_YESNO) == IDYES) {
                UpdateLevelDisplay();
            }
        }
    }
}
