//+------------------------------------------------------------------+
//|                                            RiskManager.mqh |
//|                              Copyright 2025, Golden Candle Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle Team"
#property strict

// Risk Management Constants
#define MAX_DRAWDOWN_PERCENT    20.0    // Maximum allowed drawdown
#define MIN_MARGIN_LEVEL        200.0   // Minimum required margin level
#define MAX_SPREAD_POINTS       50      // Maximum allowed spread
#define MIN_DAILY_PROFIT       -500.0   // Daily loss limit
#define MIN_BALANCE            1000.0   // Minimum required balance

//+------------------------------------------------------------------+
//| Risk Management Class                                              |
//+------------------------------------------------------------------+
class CRiskManager {
private:
    string         m_symbol;
    bool           m_initialized;
    
    // Risk tracking
    double         m_initialBalance;
    double         m_maxDrawdown;
    double         m_dailyLossLimit;
    double         m_maxSpread;
    
    // Daily tracking
    datetime       m_lastCheckTime;
    double         m_dailyStartBalance;
    double         m_worstDrawdown;
    
    // Internal validation
    bool           ValidateMarginLevel();
    bool           ValidateDrawdown();
    bool           ValidateDailyLoss();
    bool           ValidateSpread();
    
public:
                   CRiskManager();
                  ~CRiskManager();
    
    // Initialization
    bool           Init(string symbol, double maxDD = MAX_DRAWDOWN_PERCENT,
                       double dailyLimit = MIN_DAILY_PROFIT);
    
    // Risk validation
    bool           ValidateNewPosition(double lots, double stopLoss);
    bool           ValidateAccountState();
    bool           ValidateTradeConditions();
    
    // Status updates
    void           OnTick();
    void           OnDayStart();
    
    // Risk metrics
    double         GetCurrentDrawdown();
    double         GetDailyProfit();
    double         GetWorstDrawdown() const { return m_worstDrawdown; }
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager() {
    m_symbol = NULL;
    m_initialized = false;
    m_initialBalance = 0;
    m_maxDrawdown = MAX_DRAWDOWN_PERCENT;
    m_dailyLossLimit = MIN_DAILY_PROFIT;
    m_maxSpread = MAX_SPREAD_POINTS;
    m_lastCheckTime = 0;
    m_dailyStartBalance = 0;
    m_worstDrawdown = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CRiskManager::~CRiskManager() {
}

//+------------------------------------------------------------------+
//| Initialize Risk Manager                                            |
//+------------------------------------------------------------------+
bool CRiskManager::Init(string symbol, double maxDD = MAX_DRAWDOWN_PERCENT,
                       double dailyLimit = MIN_DAILY_PROFIT) {
    if(symbol == "" || maxDD <= 0) return false;
    
    m_symbol = symbol;
    m_maxDrawdown = maxDD;
    m_dailyLossLimit = dailyLimit;
    
    m_initialBalance = AccountBalance();
    m_dailyStartBalance = m_initialBalance;
    m_lastCheckTime = TimeLocal();
    
    m_initialized = true;
    return true;
}

//+------------------------------------------------------------------+
//| Validate margin level                                             |
//+------------------------------------------------------------------+
bool CRiskManager::ValidateMarginLevel() {
    double marginLevel = AccountMargin() > 0 ? 
        AccountEquity() / AccountMargin() * 100.0 : 0;
    
    return marginLevel >= MIN_MARGIN_LEVEL;
}

//+------------------------------------------------------------------+
//| Validate drawdown                                                  |
//+------------------------------------------------------------------+
bool CRiskManager::ValidateDrawdown() {
    double drawdown = GetCurrentDrawdown();
    
    if(drawdown > m_worstDrawdown) {
        m_worstDrawdown = drawdown;
    }
    
    return drawdown <= m_maxDrawdown;
}

//+------------------------------------------------------------------+
//| Validate daily loss                                               |
//+------------------------------------------------------------------+
bool CRiskManager::ValidateDailyLoss() {
    return GetDailyProfit() >= m_dailyLossLimit;
}

//+------------------------------------------------------------------+
//| Validate spread                                                   |
//+------------------------------------------------------------------+
bool CRiskManager::ValidateSpread() {
    double currentSpread = MarketInfo(m_symbol, MODE_SPREAD);
    return currentSpread <= m_maxSpread;
}

//+------------------------------------------------------------------+
//| Validate new position risk                                        |
//+------------------------------------------------------------------+
bool CRiskManager::ValidateNewPosition(double lots, double stopLoss) {
    if(!m_initialized || lots <= 0 || stopLoss <= 0) return false;
    
    // Calculate potential loss
    double tickValue = MarketInfo(m_symbol, MODE_TICKVALUE);
    double tickSize = MarketInfo(m_symbol, MODE_TICKSIZE);
    double points = MathAbs(MarketInfo(m_symbol, MODE_ASK) - stopLoss);
    double potentialLoss = (points / tickSize) * tickValue * lots;
    
    // Check if loss would exceed daily limit
    if(GetDailyProfit() - potentialLoss < m_dailyLossLimit)
        return false;
    
    // Check if loss would exceed max drawdown
    double potentialDrawdown = ((AccountEquity() - potentialLoss) / 
                               m_initialBalance - 1.0) * 100.0;
    
    return potentialDrawdown > -m_maxDrawdown;
}

//+------------------------------------------------------------------+
//| Validate overall account state                                    |
//+------------------------------------------------------------------+
bool CRiskManager::ValidateAccountState() {
    if(!m_initialized) return false;
    
    // Check account conditions
    if(AccountBalance() < MIN_BALANCE) return false;
    if(!ValidateMarginLevel()) return false;
    if(!ValidateDrawdown()) return false;
    if(!ValidateDailyLoss()) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Validate current trade conditions                                 |
//+------------------------------------------------------------------+
bool CRiskManager::ValidateTradeConditions() {
    if(!m_initialized) return false;
    
    // Check market conditions
    if(!ValidateSpread()) return false;
    
    // Check if market is open
    if(MarketInfo(m_symbol, MODE_TRADEALLOWED) == 0) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Update risk metrics on tick                                       |
//+------------------------------------------------------------------+
void CRiskManager::OnTick() {
    if(!m_initialized) return;
    
    // Check for day change
    MqlDateTime now;
    TimeToStruct(TimeLocal(), now);
    
    MqlDateTime last;
    TimeToStruct(m_lastCheckTime, last);
    
    if(now.day != last.day) {
        OnDayStart();
    }
    
    m_lastCheckTime = TimeLocal();
}

//+------------------------------------------------------------------+
//| Handle start of new trading day                                   |
//+------------------------------------------------------------------+
void CRiskManager::OnDayStart() {
    m_dailyStartBalance = AccountBalance();
}

//+------------------------------------------------------------------+
//| Calculate current drawdown                                        |
//+------------------------------------------------------------------+
double CRiskManager::GetCurrentDrawdown() {
    if(!m_initialized) return 0;
    
    return ((AccountEquity() / m_initialBalance) - 1.0) * 100.0;
}

//+------------------------------------------------------------------+
//| Calculate current day's profit                                    |
//+------------------------------------------------------------------+
double CRiskManager::GetDailyProfit() {
    if(!m_initialized) return 0;
    
    return AccountBalance() - m_dailyStartBalance;
}
