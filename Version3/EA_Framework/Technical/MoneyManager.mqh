//+------------------------------------------------------------------+
//|                                                   MoneyManager.mqh |
//|                                     Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"
#property strict

#include "../Base/Constants.mqh"
#include "../Base/Enums.mqh"
#include "../Base/Structures.mqh"
#include "../Base/StateManager.mqh"

//+------------------------------------------------------------------+
//| Money Manager Class                                                |
//+------------------------------------------------------------------+
class CMoneyManager {
private:
    // Core properties
    double           m_initialBalance;
    double           m_currentBalance;
    double           m_currentEquity;
    bool             m_isInitialized;
    
    // Risk parameters
    double           m_baseRiskPercent;      // Base risk per trade
    double           m_maxRiskPercent;       // Maximum risk per trade
    double           m_maxDailyRisk;         // Maximum daily risk
    double           m_maxDrawdownPercent;   // Maximum drawdown allowed
    
    // Position sizing
    double           m_minLotSize;
    double           m_maxLotSize;
    double           m_lotStep;
    
    // Profit management
    double           m_profitTarget;         // Daily profit target
    double           m_trailingStop;         // Trailing stop percentage
    
    // Performance tracking
    SMoneyStats      m_stats;
    
    // Dependencies
    CStateManager*   m_stateManager;
    
    // Private methods
    bool             ValidateParameters();
    void             UpdatePerformanceMetrics();
    double           CalculateDrawdown();
    bool             IsWithinRiskLimits(double riskAmount);
    
public:
                     CMoneyManager();
                    ~CMoneyManager();
    
    // Initialization
    bool             Init(CStateManager* stateManager);
    void             Deinit();
    
    // Risk management
    double           CalculatePositionSize(string symbol, double stopLoss);
    double           AdjustRiskForConsecutiveLosses(double baseRisk);
    bool             ValidateTradeRisk(double riskAmount);
    
    // Money management
    bool             UpdateBalance();
    bool             CheckProfitTarget();
    bool             CheckDrawdownLimit();
    double           GetAvailableRisk();
    
    // Position sizing
    double           NormalizeLotSize(string symbol, double lots);
    double           GetMinLotSize(string symbol);
    double           GetMaxLotSize(string symbol);
    
    // Performance tracking
    void             UpdateStats(double profit);
    SMoneyStats*     GetStats() { return &m_stats; }
    void             ResetDailyStats();
    
    // Setters
    void             SetRiskParameters(double baseRisk, double maxRisk, double maxDaily, double maxDD);
    void             SetProfitTarget(double target) { m_profitTarget = target; }
    void             SetTrailingStop(double trailing) { m_trailingStop = trailing; }
    
    // Getters
    double           GetBaseRisk()          { return m_baseRiskPercent; }
    double           GetMaxRisk()           { return m_maxRiskPercent; }
    double           GetMaxDailyRisk()      { return m_maxDailyRisk; }
    double           GetMaxDrawdown()       { return m_maxDrawdownPercent; }
    double           GetCurrentDrawdown()   { return CalculateDrawdown(); }
    double           GetDailyProfit()       { return m_stats.dailyProfit; }
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CMoneyManager::CMoneyManager() {
    m_isInitialized = false;
    m_initialBalance = 0;
    m_currentBalance = 0;
    m_currentEquity = 0;
    
    // Default risk parameters
    m_baseRiskPercent = 1.0;      // 1% base risk per trade
    m_maxRiskPercent = 2.0;       // 2% maximum risk per trade
    m_maxDailyRisk = 5.0;         // 5% maximum daily risk
    m_maxDrawdownPercent = 20.0;  // 20% maximum drawdown
    
    m_profitTarget = 0;           // No default profit target
    m_trailingStop = 0;           // No default trailing stop
    
    m_stats.Clear();
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CMoneyManager::~CMoneyManager() {
    Deinit();
}

//+------------------------------------------------------------------+
//| Initialize the Money Manager                                       |
//+------------------------------------------------------------------+
bool CMoneyManager::Init(CStateManager* stateManager) {
    if(m_isInitialized) return true;
    
    if(stateManager == NULL) {
        Print("StateManager is required");
        return false;
    }
    
    m_stateManager = stateManager;
    
    if(!ValidateParameters()) {
        return false;
    }
    
    m_initialBalance = AccountBalance();
    m_currentBalance = m_initialBalance;
    m_currentEquity = AccountEquity();
    
    m_isInitialized = true;
    return true;
}

//+------------------------------------------------------------------+
//| Deinitialize the Money Manager                                    |
//+------------------------------------------------------------------+
void CMoneyManager::Deinit() {
    m_isInitialized = false;
}

//+------------------------------------------------------------------+
//| Calculate position size based on risk                             |
//+------------------------------------------------------------------+
double CMoneyManager::CalculatePositionSize(string symbol, double stopLoss) {
    if(!m_isInitialized || stopLoss <= 0) return 0;
    
    double riskAmount = m_currentBalance * (m_baseRiskPercent / 100.0);
    riskAmount = AdjustRiskForConsecutiveLosses(riskAmount);
    
    if(!IsWithinRiskLimits(riskAmount)) {
        return 0;
    }
    
    double pointValue = MarketInfo(symbol, MODE_POINT);
    double tickValue = MarketInfo(symbol, MODE_TICKVALUE);
    double stopDistance = MathAbs(MarketInfo(symbol, MODE_ASK) - stopLoss);
    
    if(stopDistance <= 0 || tickValue <= 0) return 0;
    
    double lots = NormalizeDouble(riskAmount / (stopDistance * tickValue / pointValue), 2);
    return NormalizeLotSize(symbol, lots);
}

//+------------------------------------------------------------------+
//| Adjust risk based on consecutive losses                           |
//+------------------------------------------------------------------+
double CMoneyManager::AdjustRiskForConsecutiveLosses(double baseRisk) {
    int consecutive = m_stateManager.GetConsecutiveLosses();
    
    // Reduce risk after consecutive losses
    if(consecutive >= 2) {
        baseRisk *= (1.0 - (0.1 * (consecutive - 1))); // Reduce by 10% per loss after 2
    }
    
    return MathMax(baseRisk, m_currentBalance * 0.001); // Minimum 0.1% risk
}

//+------------------------------------------------------------------+
//| Validate trade risk amount                                        |
//+------------------------------------------------------------------+
bool CMoneyManager::ValidateTradeRisk(double riskAmount) {
    if(riskAmount <= 0) return false;
    
    // Check against maximum risk per trade
    double riskPercent = (riskAmount / m_currentBalance) * 100.0;
    if(riskPercent > m_maxRiskPercent) {
        return false;
    }
    
    // Check daily risk limit
    double totalDailyRisk = ((m_stats.dailyLoss + riskAmount) / m_currentBalance) * 100.0;
    if(totalDailyRisk > m_maxDailyRisk) {
        return false;
    }
    
    // Check current drawdown
    if(CalculateDrawdown() >= m_maxDrawdownPercent) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Update account balance and equity                                 |
//+------------------------------------------------------------------+
bool CMoneyManager::UpdateBalance() {
    if(!m_isInitialized) return false;
    
    m_currentBalance = AccountBalance();
    m_currentEquity = AccountEquity();
    
    UpdatePerformanceMetrics();
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if daily profit target is reached                          |
//+------------------------------------------------------------------+
bool CMoneyManager::CheckProfitTarget() {
    if(m_profitTarget <= 0) return false;
    return m_stats.dailyProfit >= (m_initialBalance * m_profitTarget / 100.0);
}

//+------------------------------------------------------------------+
//| Check if drawdown limit is exceeded                              |
//+------------------------------------------------------------------+
bool CMoneyManager::CheckDrawdownLimit() {
    return CalculateDrawdown() >= m_maxDrawdownPercent;
}

//+------------------------------------------------------------------+
//| Calculate current drawdown percentage                             |
//+------------------------------------------------------------------+
double CMoneyManager::CalculateDrawdown() {
    if(m_initialBalance <= 0) return 0;
    
    double drawdown = m_initialBalance - m_currentEquity;
    return (drawdown / m_initialBalance) * 100.0;
}

//+------------------------------------------------------------------+
//| Update performance metrics                                        |
//+------------------------------------------------------------------+
void CMoneyManager::UpdatePerformanceMetrics() {
    // Update maximum drawdown if current drawdown is larger
    double currentDD = CalculateDrawdown();
    if(currentDD > m_stats.maxDrawdown) {
        m_stats.maxDrawdown = currentDD;
    }
    
    // Update equity high water mark
    if(m_currentEquity > m_stats.highWaterMark) {
        m_stats.highWaterMark = m_currentEquity;
    }
}

//+------------------------------------------------------------------+
//| Normalize lot size according to symbol settings                   |
//+------------------------------------------------------------------+
double CMoneyManager::NormalizeLotSize(string symbol, double lots) {
    double minLots = MarketInfo(symbol, MODE_MINLOT);
    double maxLots = MarketInfo(symbol, MODE_MAXLOT);
    double lotStep = MarketInfo(symbol, MODE_LOTSTEP);
    
    lots = MathFloor(lots / lotStep) * lotStep;
    lots = MathMax(minLots, MathMin(lots, maxLots));
    
    return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Update money management statistics                                |
//+------------------------------------------------------------------+
void CMoneyManager::UpdateStats(double profit) {
    if(profit > 0) {
        m_stats.dailyProfit += profit;
        m_stats.totalProfit += profit;
    } else {
        m_stats.dailyLoss += MathAbs(profit);
        m_stats.totalLoss += MathAbs(profit);
    }
    
    UpdatePerformanceMetrics();
}

//+------------------------------------------------------------------+
//| Reset daily statistics                                            |
//+------------------------------------------------------------------+
void CMoneyManager::ResetDailyStats() {
    m_stats.dailyProfit = 0;
    m_stats.dailyLoss = 0;
}

//+------------------------------------------------------------------+
//| Set risk management parameters                                    |
//+------------------------------------------------------------------+
void CMoneyManager::SetRiskParameters(double baseRisk, double maxRisk, 
                                    double maxDaily, double maxDD) {
    m_baseRiskPercent = baseRisk;
    m_maxRiskPercent = maxRisk;
    m_maxDailyRisk = maxDaily;
    m_maxDrawdownPercent = maxDD;
}

//+------------------------------------------------------------------+
//| Validate money management parameters                              |
//+------------------------------------------------------------------+
bool CMoneyManager::ValidateParameters() {
    if(m_baseRiskPercent <= 0 || m_baseRiskPercent > 100) {
        Print("Invalid base risk percent");
        return false;
    }
    
    if(m_maxRiskPercent <= 0 || m_maxRiskPercent > 100) {
        Print("Invalid max risk percent");
        return false;
    }
    
    if(m_maxDailyRisk <= 0 || m_maxDailyRisk > 100) {
        Print("Invalid max daily risk");
        return false;
    }
    
    if(m_maxDrawdownPercent <= 0 || m_maxDrawdownPercent > 100) {
        Print("Invalid max drawdown percent");
        return false;
    }
    
    return true;
}
