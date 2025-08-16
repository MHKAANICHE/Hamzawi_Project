//+------------------------------------------------------------------+
//|                                                     StateManager.mqh |
//|                                     Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"
#property strict

#include "Enums.mqh"
#include "Structures.mqh"
#include "Constants.mqh"

//+------------------------------------------------------------------+
//| State Manager Class                                                |
//+------------------------------------------------------------------+
class CStateManager {
private:
    STradeState      m_tradeState;        // Current trade state
    SMarketState     m_marketState;       // Current market state
    SConfiguration   m_config;            // Current configuration
    string           m_stateFileName;     // State file name
    
    // Private methods
    bool            SaveStateToFile();
    bool            LoadStateFromFile();
    void            UpdatePerformanceMetrics();
    
public:
    // Constructor/Destructor
                    CStateManager();
                   ~CStateManager();
    
    // Initialization
    bool            Init();
    void            Deinit();
    
    // State Management
    bool            UpdateState();
    bool            ValidateState();
    bool            IsTradeAllowed();
    string          GetStateDescription();
    
    // State Setters
    void            SetTradingState(ENUM_TRADING_STATE state, string reason);
    void            SetMarketCondition(ENUM_MARKET_CONDITION condition);
    void            UpdateDailyStats(double profit);
    void            IncrementConsecutiveLosses();
    void            ResetConsecutiveLosses();
    
    // State Getters
    ENUM_TRADING_STATE  GetTradingState()      const { return m_tradeState.state; }
    datetime           GetLastUpdateTime()     const { return m_tradeState.lastUpdateTime; }
    int               GetConsecutiveLosses()   const { return m_tradeState.consecutiveLosses; }
    double            GetDailyProfit()        const { return m_tradeState.dailyProfit; }
    double            GetMaxDrawdown()        const { return m_tradeState.maxDrawdown; }
    string            GetStateReason()        const { return m_tradeState.stateReason; }
    
    // Market State Getters
    ENUM_MARKET_CONDITION GetMarketCondition() const { return m_marketState.condition; }
    bool             IsTradeable()            const { return m_marketState.isTradeable; }
    string           GetUntradableReason()    const { return m_marketState.untradableReason; }
    
    // Configuration
    void             LoadConfiguration();
    void             SaveConfiguration();
    SConfiguration*  GetConfiguration()        { return &m_config; }
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CStateManager::CStateManager() {
    m_stateFileName = "GoldenCandle_State.bin";
    m_tradeState.Clear();
    m_marketState.Clear();
    m_config.SetDefaults();
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CStateManager::~CStateManager() {
    SaveStateToFile();
}

//+------------------------------------------------------------------+
//| Initialize the state manager                                       |
//+------------------------------------------------------------------+
bool CStateManager::Init() {
    LoadConfiguration();
    if(!LoadStateFromFile()) {
        m_tradeState.Clear();
        m_marketState.Clear();
    }
    return ValidateState();
}

//+------------------------------------------------------------------+
//| Deinitialize the state manager                                    |
//+------------------------------------------------------------------+
void CStateManager::Deinit() {
    SaveStateToFile();
    SaveConfiguration();
}

//+------------------------------------------------------------------+
//| Update current state                                              |
//+------------------------------------------------------------------+
bool CStateManager::UpdateState() {
    UpdatePerformanceMetrics();
    
    // Check daily loss limit
    if(m_tradeState.dailyProfit <= -m_config.maxDailyLoss) {
        SetTradingState(STATE_STOPPED, "Daily loss limit reached");
        return false;
    }
    
    // Check consecutive losses
    if(m_tradeState.consecutiveLosses >= m_config.maxConsecutiveLosses) {
        SetTradingState(STATE_SUSPENDED, "Max consecutive losses reached");
        return false;
    }
    
    // Check drawdown
    if(m_tradeState.maxDrawdown >= m_config.maxDrawdown) {
        SetTradingState(STATE_STOPPED, "Max drawdown reached");
        return false;
    }
    
    // Update market state
    if(m_marketState.spread > m_config.maxSpread) {
        m_marketState.isTradeable = false;
        m_marketState.untradableReason = "Spread too high";
    }
    
    return ValidateState();
}

//+------------------------------------------------------------------+
//| Validate current state                                            |
//+------------------------------------------------------------------+
bool CStateManager::ValidateState() {
    if(m_tradeState.state == STATE_STOPPED) {
        return false;
    }
    
    if(m_tradeState.state == STATE_ERROR) {
        return false;
    }
    
    if(!m_marketState.isTradeable) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                       |
//+------------------------------------------------------------------+
bool CStateManager::IsTradeAllowed() {
    return ValidateState() && m_marketState.isTradeable;
}

//+------------------------------------------------------------------+
//| Get current state description                                      |
//+------------------------------------------------------------------+
string CStateManager::GetStateDescription() {
    string desc = "Trading State: " + EnumToString(m_tradeState.state);
    desc += "\nReason: " + m_tradeState.stateReason;
    desc += "\nMarket Condition: " + EnumToString(m_marketState.condition);
    if(!m_marketState.isTradeable) {
        desc += "\nUntradeable: " + m_marketState.untradableReason;
    }
    return desc;
}

//+------------------------------------------------------------------+
//| Set trading state with reason                                     |
//+------------------------------------------------------------------+
void CStateManager::SetTradingState(ENUM_TRADING_STATE state, string reason) {
    m_tradeState.state = state;
    m_tradeState.stateReason = reason;
    m_tradeState.lastUpdateTime = TimeCurrent();
    SaveStateToFile();
}

//+------------------------------------------------------------------+
//| Update daily statistics                                           |
//+------------------------------------------------------------------+
void CStateManager::UpdateDailyStats(double profit) {
    m_tradeState.dailyProfit += profit;
    
    // Reset daily stats if it's a new day
    static datetime lastDay = 0;
    datetime currentDay = TimeCurrent();
    if(TimeDay(currentDay) != TimeDay(lastDay)) {
        m_tradeState.dailyProfit = profit;
        lastDay = currentDay;
    }
    
    SaveStateToFile();
}
