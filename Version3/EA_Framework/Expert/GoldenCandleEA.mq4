//+------------------------------------------------------------------+
//|                                               GoldenCandleEA.mq4 |
//|                                     Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"
#property version   "2.0"
#property strict

#include "../EA_Framework/Base/Constants.mqh"
#include "../EA_Framework/Base/Enums.mqh"
#include "../EA_Framework/Base/Structures.mqh"
#include "../EA_Framework/Base/StateManager.mqh"
#include "../EA_Framework/Technical/SignalManager.mqh"
#include "../EA_Framework/Technical/TradeManager.mqh"
#include "../EA_Framework/Technical/MoneyManager.mqh"
#include "../EA_Framework/Strategy/GoldenCandleStrategy.mqh"

//+------------------------------------------------------------------+
//| Global EA Parameters                                               |
//+------------------------------------------------------------------+
input string          GeneralSettings       = "=== General Settings ===";
input string          EAName               = "GoldenCandle EA";
input int             MagicNumber          = 202508;
input ENUM_TIMEFRAMES OperatingTimeframe   = PERIOD_H1;
input bool            EnableTrading        = true;

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
class CGoldenCandleEA {
private:
    // Component managers
    CStateManager*      m_stateManager;
    CSignalManager*     m_signalManager;
    CTradeManager*      m_tradeManager;
    CMoneyManager*      m_moneyManager;
    CGoldenCandleStrategy* m_strategy;
    
    // EA properties
    string             m_symbol;
    ENUM_TIMEFRAMES    m_timeframe;
    int                m_magicNumber;
    bool               m_isInitialized;
    datetime           m_lastUpdateTime;
    
    // Private methods
    bool               ValidateSettings();
    void              ProcessTrading();
    void              ManageOpenPositions();
    void              CheckDailyLimits();
    void              UpdateStats();
    string            GetStatusText();
    
public:
                      CGoldenCandleEA();
                     ~CGoldenCandleEA();
    
    // Main methods
    bool              Init();
    void              Deinit();
    void              OnTick();
    void              OnTimer();
    
    // Event handlers
    void              OnTradeTransaction();
    double            OnTester();
};

// Global EA instance
CGoldenCandleEA EA;

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CGoldenCandleEA::CGoldenCandleEA() {
    m_isInitialized = false;
    m_lastUpdateTime = 0;
    
    // Initialize component pointers
    m_stateManager = NULL;
    m_signalManager = NULL;
    m_tradeManager = NULL;
    m_moneyManager = NULL;
    m_strategy = NULL;
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
    
    Print("Initializing ", EAName, " v", __VERSION__);
    
    // Validate settings
    if(!ValidateSettings()) {
        Print("Failed to validate settings");
        return false;
    }
    
    // Initialize symbol and timeframe
    m_symbol = Symbol();
    m_timeframe = OperatingTimeframe;
    m_magicNumber = MagicNumber;
    
    // Create component managers
    m_stateManager = new CStateManager();
    m_signalManager = new CSignalManager();
    m_tradeManager = new CTradeManager();
    m_moneyManager = new CMoneyManager();
    m_strategy = new CGoldenCandleStrategy();
    
    // Initialize state manager
    if(!m_stateManager.Init()) {
        Print("Failed to initialize StateManager");
        return false;
    }
    
    // Initialize signal manager
    if(!m_signalManager.Init(m_symbol, m_timeframe)) {
        Print("Failed to initialize SignalManager");
        return false;
    }
    
    // Initialize money manager
    if(!m_moneyManager.Init(m_stateManager)) {
        Print("Failed to initialize MoneyManager");
        return false;
    }
    
    // Set money management parameters
    m_moneyManager.SetRiskParameters(BaseRiskPercent, MaxRiskPercent, 
                                   MaxDailyRisk, MaxDrawdown);
    m_moneyManager.SetProfitTarget(DailyProfitTarget);
    
    // Initialize trade manager
    if(!m_tradeManager.Init(m_symbol, m_magicNumber, m_stateManager)) {
        Print("Failed to initialize TradeManager");
        return false;
    }
    
    // Initialize strategy
    if(!m_strategy.Init(m_symbol, m_timeframe, m_signalManager, m_moneyManager)) {
        Print("Failed to initialize Strategy");
        return false;
    }
    
    // Set strategy parameters
    SGoldenCandleParams strategyParams;
    strategyParams.bodyToWickRatio = BodyToWickRatio;
    strategyParams.minCandleSize = MinCandleSize;
    strategyParams.maxCandleSize = MaxCandleSize;
    strategyParams.minVolumeMultiplier = MinVolumeMultiplier;
    strategyParams.volumeAvgPeriod = VolumePeriod;
    strategyParams.trendMAPeriod = TrendPeriod;
    strategyParams.trendStrength = TrendStrength;
    strategyParams.momentumPeriod = MomentumPeriod;
    strategyParams.momentumThreshold = MomentumThreshold;
    
    m_strategy.SetGoldenCandleParams(strategyParams);
    
    // Initialize timer for regular updates
    EventSetTimer(1);
    
    m_isInitialized = true;
    Print(EAName, " initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Deinitialize the Expert Advisor                                    |
//+------------------------------------------------------------------+
void CGoldenCandleEA::Deinit() {
    if(!m_isInitialized) return;
    
    // Clean up timer
    EventKillTimer();
    
    // Clean up components
    if(m_strategy != NULL) {
        delete m_strategy;
        m_strategy = NULL;
    }
    if(m_moneyManager != NULL) {
        delete m_moneyManager;
        m_moneyManager = NULL;
    }
    if(m_tradeManager != NULL) {
        delete m_tradeManager;
        m_tradeManager = NULL;
    }
    if(m_signalManager != NULL) {
        delete m_signalManager;
        m_signalManager = NULL;
    }
    if(m_stateManager != NULL) {
        delete m_stateManager;
        m_stateManager = NULL;
    }
    
    m_isInitialized = false;
    Print(EAName, " deinitialized");
}

//+------------------------------------------------------------------+
//| Process tick event                                                |
//+------------------------------------------------------------------+
void CGoldenCandleEA::OnTick() {
    if(!m_isInitialized || !EnableTrading) return;
    
    // Update state and check if trading is allowed
    m_stateManager.UpdateState();
    if(!m_stateManager.IsTradeAllowed()) return;
    
    // Process trading logic
    ProcessTrading();
    
    // Manage open positions
    ManageOpenPositions();
    
    // Check daily limits
    CheckDailyLimits();
    
    // Update statistics
    UpdateStats();
    
    // Update status display
    Comment(GetStatusText());
}

//+------------------------------------------------------------------+
//| Process timer event                                               |
//+------------------------------------------------------------------+
void CGoldenCandleEA::OnTimer() {
    if(!m_isInitialized) return;
    
    // Regular maintenance tasks
    m_moneyManager.UpdateBalance();
    m_strategy.OnTimer();
    
    // Reset daily stats at market close/open
    static datetime lastResetTime = 0;
    datetime currentTime = TimeCurrent();
    
    if(TimeHour(currentTime) == 0 && TimeHour(lastResetTime) != 0) {
        m_moneyManager.ResetDailyStats();
        lastResetTime = currentTime;
    }
}

//+------------------------------------------------------------------+
//| Process trading logic                                             |
//+------------------------------------------------------------------+
void CGoldenCandleEA::ProcessTrading() {
    // Check if we already have a position
    if(m_tradeManager.HasOpenPosition()) return;
    
    // Update signals
    if(!m_signalManager.UpdateSignals()) return;
    
    // Check entry conditions
    if(!m_strategy.CheckEntryConditions()) return;
    
    // Get current signal
    SSignal* signal = m_signalManager.GetCurrentSignal();
    if(signal == NULL || !signal.isValid) return;
    
    // Calculate entry price and stop loss
    double entryPrice = m_strategy.GetEntryPrice(signal.type);
    double stopLoss = m_strategy.CalculateStopLoss(signal.type);
    
    // Open position
    m_tradeManager.OpenPosition(signal.type, entryPrice, stopLoss);
}

//+------------------------------------------------------------------+
//| Manage open positions                                             |
//+------------------------------------------------------------------+
void CGoldenCandleEA::ManageOpenPositions() {
    if(!m_tradeManager.HasOpenPosition()) return;
    
    // Update position status
    m_tradeManager.UpdatePosition();
    
    // Check exit conditions
    if(m_strategy.CheckExitConditions()) {
        m_tradeManager.ClosePosition();
        return;
    }
}

//+------------------------------------------------------------------+
//| Check daily trading limits                                        |
//+------------------------------------------------------------------+
void CGoldenCandleEA::CheckDailyLimits() {
    // Check daily profit target
    if(m_moneyManager.CheckProfitTarget()) {
        if(m_tradeManager.HasOpenPosition()) {
            m_tradeManager.ClosePosition();
        }
        m_stateManager.SetTradingState(STATE_STOPPED, "Daily profit target reached");
        return;
    }
    
    // Check drawdown limit
    if(m_moneyManager.CheckDrawdownLimit()) {
        if(m_tradeManager.HasOpenPosition()) {
            m_tradeManager.ClosePosition();
        }
        m_stateManager.SetTradingState(STATE_STOPPED, "Maximum drawdown reached");
        return;
    }
}

//+------------------------------------------------------------------+
//| Update trading statistics                                         |
//+------------------------------------------------------------------+
void CGoldenCandleEA::UpdateStats() {
    if(!m_tradeManager.HasOpenPosition()) return;
    
    SPosition* pos = m_tradeManager.GetCurrentPosition();
    if(pos == NULL) return;
    
    m_moneyManager.UpdateStats(pos.profit);
}

//+------------------------------------------------------------------+
//| Get EA status text                                               |
//+------------------------------------------------------------------+
string CGoldenCandleEA::GetStatusText() {
    string status = EAName + " Status\n";
    status += "==================\n";
    status += "Trading State: " + EnumToString(m_stateManager.GetTradingState()) + "\n";
    status += "State Reason: " + m_stateManager.GetStateReason() + "\n\n";
    
    status += "Performance Metrics\n";
    status += "==================\n";
    SMoneyStats* stats = m_moneyManager.GetStats();
    status += "Daily Profit: " + DoubleToString(stats.dailyProfit, 2) + "\n";
    status += "Current Drawdown: " + DoubleToString(m_moneyManager.GetCurrentDrawdown(), 2) + "%\n";
    status += "Max Drawdown: " + DoubleToString(stats.maxDrawdown, 2) + "%\n\n";
    
    if(m_tradeManager.HasOpenPosition()) {
        SPosition* pos = m_tradeManager.GetCurrentPosition();
        status += "Open Position\n";
        status += "==================\n";
        status += "Type: " + EnumToString(pos.type) + "\n";
        status += "Profit: " + DoubleToString(pos.profit, 2) + "\n";
        status += "SL: " + DoubleToString(pos.stopLoss, Digits) + "\n";
        status += "TP: " + DoubleToString(pos.takeProfit, Digits) + "\n";
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
