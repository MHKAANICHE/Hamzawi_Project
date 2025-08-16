//+------------------------------------------------------------------+
//|                                                  bool              Init();
    void              Deinit();
    void              OnTick();
    void              OnTimer();ldenCandleEA.mq4 |
//|                                           Copyright 2025, Golden Candle |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle"
#property version   "3.0"
#property strict

// Import DLL functions
#import "GoldenCandleEA.dll"
   bool __stdcall InitStrategy();
   void __stdcall DeinitStrategy();
   bool __stdcall CheckEntryConditions();
   bool __stdcall CheckExitConditions();
   double __stdcall GetEntryPrice(int orderType);
   void __stdcall SetGoldenCandleParams(SGoldenCandleParams& params);
#import

#include "../Base/Enums.mqh"
#include "../Base/Constants.mqh"
#include "../Base/Structures.mqh"
#include "../Technical/TradeManager.mqh"

// External constants
#define EAName "GoldenCandleEA"
#define MagicNumber 12345

// Trade parameters
extern double StopLoss = 100;        // Stop Loss in points
extern double TakeProfit = 200;      // Take Profit in points

// Forward declarations
class CTradeManager;

//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//| External Parameters                                                |
//+------------------------------------------------------------------+
// Fixed Parameters
extern double LotSize = 0.01;               // Fixed lot size

// Parabolic SAR Parameters
extern double SAR_Step = 0.001;             // Parabolic SAR Step
extern double SAR_Maximum = 0.2;            // Parabolic SAR Maximum

// Moving Average Parameters
extern int FastMA_Period = 1;               // Fast MA Period
extern int FastMA_Shift = 0;                // Fast MA Shift
extern int SlowMA_Period = 3;               // Slow MA Period
extern int SlowMA_Shift = 1;                // Slow MA Shift

// Stop Loss Parameter
extern int Base_SL = 10000;                 // Base stop loss in points

input string          MoneyManagement      = "=== Money Management ===";
input double          BaseRiskPercent      = 1.0;
input double          MaxRiskPercent       = 2.0;
input double          MaxDailyRisk         = 5.0;
input double          MaxDrawdown          = 20.0;
input double          DailyProfitTarget    = 3.0;

input string          SignalSettings       = "=== Signal Settings ===";
input double          MinSignalStrength    = 0.7;
input int             MaxSignalAge         = 3600;
input int             SignalTimeout        = 300;

input string          StrategySettings     = "=== Strategy Settings ===";
input double          BodyToWickRatio      = 2.0;
input double          MinCandleSize        = 10.0;
input double          MaxCandleSize        = 100.0;
input double          MinVolumeMultiplier  = 1.5;
input int             VolumePeriod         = 20;
input int             TrendPeriod          = 50;
input double          TrendStrength        = 0.2;
input int             MomentumPeriod       = 14;
input double          MomentumThreshold    = 0.1;

//+------------------------------------------------------------------+
//| Expert Advisor Class                                               |
//+------------------------------------------------------------------+
// EA State
enum ENUM_EA_STATE {
    STATE_RUNNING,
    STATE_STOPPED
};

struct SGoldenCandleParams {
    double bodyToWickRatio;
    double minCandleSize;
    double maxCandleSize;
    double minVolumeMultiplier;
    int volumeAvgPeriod;
    int trendMAPeriod;
    double trendStrength;
    int momentumPeriod;
    double momentumThreshold;
};

class CGoldenCandleEA {
private:
    bool               m_isInitialized;
    CTradeManager*     m_tradeManager;
    SGoldenCandleParams m_params;
    ENUM_EA_STATE      m_state;
    
    // Private methods
    bool               ValidateSettings();
    void              ProcessTrading();
    void              ManageOpenPositions();
    string            GetStatusText();
    
public:
                      CGoldenCandleEA();
                     ~CGoldenCandleEA();
    
    // Main methods
    bool              Init();
    void              Deinit();
    void              OnTick();
};

// Global EA instance
CGoldenCandleEA EA;

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CGoldenCandleEA::CGoldenCandleEA() {
    m_isInitialized = false;
    m_tradeManager = NULL;
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CGoldenCandleEA::~CGoldenCandleEA() {
    Deinit();
}

//+------------------------------------------------------------------+
//| Initialize the Expert Advisor                                      |
//+------------------------------------------------------------------+
bool CGoldenCandleEA::Init() {
    if(m_isInitialized) return true;
    
    // Initialize trade manager
    m_tradeManager = new CTradeManager();
    if(!m_tradeManager.Init(Symbol(), MagicNumber)) {
        Print("Failed to initialize TradeManager");
        return false;
    }
    
    // Initialize strategy parameters
    m_params.bodyToWickRatio = BodyToWickRatio;
    m_params.minCandleSize = MinCandleSize;
    m_params.maxCandleSize = MaxCandleSize;
    m_params.minVolumeMultiplier = MinVolumeMultiplier;
    m_params.volumeAvgPeriod = VolumePeriod;
    m_params.trendMAPeriod = TrendPeriod;
    m_params.trendStrength = TrendStrength;
    m_params.momentumPeriod = MomentumPeriod;
    m_params.momentumThreshold = MomentumThreshold;
    
    // Initialize DLL strategy
    if(!InitStrategy()) {
        Print("Failed to initialize DLL strategy");
        return false;
    }
    
    // Set strategy parameters
    SetGoldenCandleParams(m_params);
    
    m_isInitialized = true;
    Print("GoldenCandleEA initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Deinitialize the Expert Advisor                                    |
//+------------------------------------------------------------------+
void CGoldenCandleEA::Deinit() {
    if(!m_isInitialized) return;
    
    // Deinitialize DLL strategy
    DeinitStrategy();
    
    // Clean up trade manager
    if(m_tradeManager != NULL) {
        delete m_tradeManager;
        m_tradeManager = NULL;
    }
    
    m_isInitialized = false;
}

//+------------------------------------------------------------------+
//| Process tick event                                                |
//+------------------------------------------------------------------+
void CGoldenCandleEA::OnTick() {
    if(!m_isInitialized) return;
    
    ProcessTrading();
    ManageOpenPositions();
}

//+------------------------------------------------------------------+
//| Process timer event                                               |
//+------------------------------------------------------------------+
void CGoldenCandleEA::OnTimer() {
    if(!m_isInitialized) return;
    
    // Update parameters if needed
    SetGoldenCandleParams(m_params);
}
//+------------------------------------------------------------------+
//| Process trading logic                                             |
//+------------------------------------------------------------------+
void CGoldenCandleEA::ProcessTrading() {
    if(!m_tradeManager || m_tradeManager.HasOpenPosition()) return;
    
    // Check entry conditions using DLL
    if(!CheckEntryConditions()) return;
    
    // Get entry price from DLL
    double entryPrice = GetEntryPrice(OP_BUY); // or OP_SELL based on signal
    if(entryPrice <= 0) return;
    
    // Calculate stop loss and take profit
    double stopLoss = entryPrice - StopLoss * Point;
    double takeProfit = entryPrice + TakeProfit * Point;
    
    // Open position
    m_tradeManager.OpenPosition(OP_BUY, LotSize, entryPrice, stopLoss, takeProfit);
}

//+------------------------------------------------------------------+
//| Manage open positions                                             |
//+------------------------------------------------------------------+
void CGoldenCandleEA::ManageOpenPositions() {
    if(!m_tradeManager || !m_tradeManager.HasOpenPosition()) return;
    
    // Check exit conditions using DLL
    if(CheckExitConditions()) {
        m_tradeManager.ClosePosition();
    }
}

//+------------------------------------------------------------------+
//| Get EA status text                                               |
//+------------------------------------------------------------------+
string CGoldenCandleEA::GetStatusText() {
    string status = EAName + " Status\n";
    status += "==================\n";
    status += "State: " + (m_state == STATE_RUNNING ? "Running" : "Stopped") + "\n\n";
    
    if(m_tradeManager && m_tradeManager.HasOpenPosition()) {
        double profit = m_tradeManager.GetPositionProfit();
        status += "Open Position\n";
        status += "==================\n";
        status += "Profit: " + DoubleToString(profit, 2) + "\n";
    }
    
    return status;
}

//+------------------------------------------------------------------+
//| Validate EA settings                                              |
//+------------------------------------------------------------------+
bool CGoldenCandleEA::ValidateSettings() {
    if(MagicNumber <= 0) {
        Print("Invalid MagicNumber");
        return false;
    }
    
    if(BaseRiskPercent <= 0 || BaseRiskPercent > 100) {
        Print("Invalid BaseRiskPercent");
        return false;
    }
    
    if(MaxRiskPercent <= 0 || MaxRiskPercent > 100) {
        Print("Invalid MaxRiskPercent");
        return false;
    }
    
    if(MaxDailyRisk <= 0 || MaxDailyRisk > 100) {
        Print("Invalid MaxDailyRisk");
        return false;
    }
    
    if(MaxDrawdown <= 0 || MaxDrawdown > 100) {
        Print("Invalid MaxDrawdown");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit() {
    return EA.Init() ? INIT_SUCCEEDED : INIT_FAILED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    EA.Deinit();
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick() {
    EA.OnTick();
}

//+------------------------------------------------------------------+
//| Expert timer function                                             |
//+------------------------------------------------------------------+
void OnTimer() {
    EA.OnTimer();
}
