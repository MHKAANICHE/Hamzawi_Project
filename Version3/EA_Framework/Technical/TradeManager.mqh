//+------------------------------------------------------------------+
//|                                                   TradeManager.mqh |
//|                                           Copyright 2025, Golden Candle |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle"
#property strict



#include "../Base/Enums.mqh"
#include "../Base/Constants.mqh"
#include "../Base/Structures.mqh"


//+------------------------------------------------------------------+
//| Trade Manager Class                                                |
//+------------------------------------------------------------------+
class CTradeManager {
private:
    // Level management
    SLevelSetup m_currentLevel;         // Current level setup
    int m_currentLevelNumber;           // Current level (1-25)
    
    // Trading state
    ENUM_TRADING_STATE m_state;         // Current trading state
    bool m_isBacktesting;              // Backtesting flag
    string m_symbol;                   // Trading symbol
    
    // Order management
    double m_fixedLotSize;             // Fixed lot size (0.01)
    int m_baseStopLoss;               // Base stop loss in points
    
    // Risk management
    double           m_maxRiskPercent;
    double           m_riskRewardRatio;
    int              m_maxSpread;
    
    // Position tracking
    SPosition        m_currentPosition;
    STradeStatistics m_stats;
    
    // Dependencies
    CStateManager*   m_stateManager;
    
    // Private methods
    bool             ValidateTradeParameters();
    double           CalculatePositionSize(double stopLoss);
    double           CalculateTakeProfit(ENUM_ORDER_TYPE type, double entry, double stopLoss);
    bool             IsSpreadAcceptable();
    void             UpdateTradeStats(double profit);
    string           GetLastErrorText(int error);
    
public:
                     CTradeManager();
                    ~CTradeManager();
    
    // Initialization
    bool             Init(string symbol, int magicNumber, CStateManager* stateManager);
    void             Deinit();
    
    // Trade operations
    bool             OpenPosition(ENUM_ORDER_TYPE type, double entry, double stopLoss);
    bool             ClosePosition();
    bool             ModifyPosition(double stopLoss, double takeProfit);
    bool             ClosePartial(double percentage);
    
    // Position management
    bool             UpdatePosition();
    bool             HasOpenPosition()      { return m_currentPosition.ticket != 0; }
    SPosition*       GetCurrentPosition()   { return &m_currentPosition; }
    double           GetCurrentProfit()     { return m_currentPosition.profit; }
    
    // Risk management
    void             SetRiskParameters(double riskPercent, double riskReward, int maxSpread);
    bool             ValidateRisk(double stopLoss);
    double           CalculateMaxLoss(double lots, double stopLoss);
    
    // Trade statistics
    STradeStatistics* GetStatistics()       { return &m_stats; }
    void             ResetStatistics();
    
    // Getters/Setters
    void             SetLotSize(double lots) { m_lotSize = lots; }
    double           GetLotSize()           { return m_lotSize; }
    string           GetSymbol()            { return m_symbol; }
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CTradeManager::CTradeManager() {
    m_isInitialized = false;
    m_symbol = NULL;
    m_lotSize = 0.1;
    m_slippage = 3;
    m_magicNumber = 0;
    m_maxRiskPercent = 2.0;
    m_riskRewardRatio = 1.5;
    m_maxSpread = 20;
    m_currentPosition.Clear();
    m_stats.Clear();
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CTradeManager::~CTradeManager() {
    Deinit();
}

//+------------------------------------------------------------------+
//| Initialize the Trade Manager                                       |
//+------------------------------------------------------------------+
bool CTradeManager::Init(string symbol, int magicNumber, CStateManager* stateManager) {
    if(m_isInitialized) return true;
    
    if(symbol == NULL || symbol == "") {
        Print("Invalid symbol provided");
        return false;
    }
    
    if(stateManager == NULL) {
        Print("StateManager is required");
        return false;
    }
    
    m_symbol = symbol;
    m_magicNumber = magicNumber;
    m_stateManager = stateManager;
    
    if(!ValidateTradeParameters()) {
        return false;
    }
    
    m_isInitialized = true;
    return true;
}

//+------------------------------------------------------------------+
//| Deinitialize the Trade Manager                                     |
//+------------------------------------------------------------------+
void CTradeManager::Deinit() {
    if(HasOpenPosition()) {
        ClosePosition();
    }
    m_isInitialized = false;
}

//+------------------------------------------------------------------+
//| Open a new position                                               |
//+------------------------------------------------------------------+
bool CTradeManager::OpenPosition(ENUM_ORDER_TYPE type, double entry, double stopLoss) {
    if(!m_isInitialized || !m_stateManager.IsTradeAllowed()) {
        return false;
    }
    
    if(HasOpenPosition()) {
        Print("Position already exists");
        return false;
    }
    
    if(!ValidateRisk(stopLoss)) {
        return false;
    }
    
    if(!IsSpreadAcceptable()) {
        Print("Spread too high: ", MarketInfo(m_symbol, MODE_SPREAD));
        return false;
    }
    
    double lots = CalculatePositionSize(stopLoss);
    if(lots <= 0) {
        Print("Invalid lot size calculated");
        return false;
    }
    
    double takeProfit = CalculateTakeProfit(type, entry, stopLoss);
    
    int ticket = OrderSend(
        m_symbol,
        type,
        lots,
        entry,
        m_slippage,
        stopLoss,
        takeProfit,
        "EA Trade",
        m_magicNumber,
        0,
        type == ORDER_TYPE_BUY ? clrBlue : clrRed
    );
    
    if(ticket <= 0) {
        Print("Order send failed: ", GetLastErrorText(GetLastError()));
        return false;
    }
    
    // Update position tracking
    m_currentPosition.ticket = ticket;
    m_currentPosition.type = type;
    m_currentPosition.lots = lots;
    m_currentPosition.entry = entry;
    m_currentPosition.stopLoss = stopLoss;
    m_currentPosition.takeProfit = takeProfit;
    m_currentPosition.openTime = TimeCurrent();
    
    return true;
}

//+------------------------------------------------------------------+
//| Close current position                                            |
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition() {
    if(!HasOpenPosition()) return true;
    
    bool success = OrderClose(
        m_currentPosition.ticket,
        m_currentPosition.lots,
        MarketInfo(m_symbol, m_currentPosition.type == ORDER_TYPE_BUY ? MODE_BID : MODE_ASK),
        m_slippage,
        m_currentPosition.type == ORDER_TYPE_BUY ? clrRed : clrBlue
    );
    
    if(!success) {
        Print("Close position failed: ", GetLastErrorText(GetLastError()));
        return false;
    }
    
    // Update statistics
    UpdateTradeStats(OrderProfit());
    m_currentPosition.Clear();
    
    return true;
}

//+------------------------------------------------------------------+
//| Modify current position                                           |
//+------------------------------------------------------------------+
bool CTradeManager::ModifyPosition(double stopLoss, double takeProfit) {
    if(!HasOpenPosition()) return false;
    
    bool success = OrderModify(
        m_currentPosition.ticket,
        m_currentPosition.entry,
        stopLoss,
        takeProfit,
        0,
        clrYellow
    );
    
    if(!success) {
        Print("Modify position failed: ", GetLastErrorText(GetLastError()));
        return false;
    }
    
    m_currentPosition.stopLoss = stopLoss;
    m_currentPosition.takeProfit = takeProfit;
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate position size based on risk                             |
//+------------------------------------------------------------------+
double CTradeManager::CalculatePositionSize(double stopLoss) {
    double riskAmount = AccountBalance() * (m_maxRiskPercent / 100.0);
    double pointValue = MarketInfo(m_symbol, MODE_POINT);
    double tickValue = MarketInfo(m_symbol, MODE_TICKVALUE);
    
    double stopDistance = MathAbs(MarketInfo(m_symbol, MODE_ASK) - stopLoss);
    double lotStep = MarketInfo(m_symbol, MODE_LOTSTEP);
    
    if(stopDistance <= 0 || tickValue <= 0) return 0;
    
    double lots = NormalizeDouble(riskAmount / (stopDistance * tickValue / pointValue), 2);
    lots = MathFloor(lots / lotStep) * lotStep;
    
    double minLots = MarketInfo(m_symbol, MODE_MINLOT);
    double maxLots = MarketInfo(m_symbol, MODE_MAXLOT);
    
    return MathMin(MathMax(lots, minLots), maxLots);
}

//+------------------------------------------------------------------+
//| Calculate take profit based on risk/reward ratio                  |
//+------------------------------------------------------------------+
double CTradeManager::CalculateTakeProfit(ENUM_ORDER_TYPE type, double entry, double stopLoss) {
    double stopDistance = MathAbs(entry - stopLoss);
    double takeProfitDistance = stopDistance * m_riskRewardRatio;
    
    return (type == ORDER_TYPE_BUY) ? 
           entry + takeProfitDistance : 
           entry - takeProfitDistance;
}

//+------------------------------------------------------------------+
//| Update current position information                               |
//+------------------------------------------------------------------+
bool CTradeManager::UpdatePosition() {
    if(!HasOpenPosition()) return true;
    
    if(!OrderSelect(m_currentPosition.ticket, SELECT_BY_TICKET)) {
        // Position might have been closed by SL/TP
        if(OrderSelect(m_currentPosition.ticket, SELECT_BY_TICKET, MODE_HISTORY)) {
            UpdateTradeStats(OrderProfit());
            m_currentPosition.Clear();
        }
        return false;
    }
    
    m_currentPosition.profit = OrderProfit();
    return true;
}

//+------------------------------------------------------------------+
//| Validate risk parameters for a trade                              |
//+------------------------------------------------------------------+
bool CTradeManager::ValidateRisk(double stopLoss) {
    if(stopLoss <= 0) return false;
    
    double potentialLoss = CalculateMaxLoss(m_lotSize, stopLoss);
    double accountRisk = (potentialLoss / AccountBalance()) * 100;
    
    return accountRisk <= m_maxRiskPercent;
}

//+------------------------------------------------------------------+
//| Check if current spread is acceptable                             |
//+------------------------------------------------------------------+
bool CTradeManager::IsSpreadAcceptable() {
    int currentSpread = (int)MarketInfo(m_symbol, MODE_SPREAD);
    return currentSpread <= m_maxSpread;
}

//+------------------------------------------------------------------+
//| Update trade statistics                                           |
//+------------------------------------------------------------------+
void CTradeManager::UpdateTradeStats(double profit) {
    m_stats.totalTrades++;
    m_stats.grossProfit += (profit > 0) ? profit : 0;
    m_stats.grossLoss += (profit < 0) ? MathAbs(profit) : 0;
    
    if(profit > 0) {
        m_stats.winningTrades++;
        m_stats.consecutiveWins++;
        m_stats.consecutiveLosses = 0;
    } else {
        m_stats.losingTrades++;
        m_stats.consecutiveLosses++;
        m_stats.consecutiveWins = 0;
    }
    
    m_stats.netProfit = m_stats.grossProfit - m_stats.grossLoss;
    m_stats.winRate = (m_stats.totalTrades > 0) ? 
                      (double)m_stats.winningTrades / m_stats.totalTrades * 100.0 : 
                      0;
}

//+------------------------------------------------------------------+
//| Reset trade statistics                                            |
//+------------------------------------------------------------------+
void CTradeManager::ResetStatistics() {
    m_stats.Clear();
}

//+------------------------------------------------------------------+
//| Get text description of last error                                |
//+------------------------------------------------------------------+
string CTradeManager::GetLastErrorText(int error) {
    string errorText;
    
    switch(error) {
        case ERR_NO_ERROR:
            errorText = "No error";
            break;
        case ERR_NO_RESULT:
            errorText = "No error returned";
            break;
        case ERR_COMMON_ERROR:
            errorText = "Common error";
            break;
        case ERR_INVALID_TRADE_PARAMETERS:
            errorText = "Invalid trade parameters";
            break;
        case ERR_SERVER_BUSY:
            errorText = "Trade server is busy";
            break;
        case ERR_OLD_VERSION:
            errorText = "Old version of the client terminal";
            break;
        case ERR_NO_CONNECTION:
            errorText = "No connection with trade server";
            break;
        case ERR_NOT_ENOUGH_RIGHTS:
            errorText = "Not enough rights";
            break;
        case ERR_TOO_FREQUENT_REQUESTS:
            errorText = "Too frequent requests";
            break;
        case ERR_MALFUNCTIONAL_TRADE:
            errorText = "Malfunctional trade operation";
            break;
        default:
            errorText = "Unknown error";
    }
    
    return errorText;
}

//+------------------------------------------------------------------+
//| Validate trade parameters                                         |
//+------------------------------------------------------------------+
bool CTradeManager::ValidateTradeParameters() {
    if(m_maxRiskPercent <= 0 || m_maxRiskPercent > 100) {
        Print("Invalid risk percent");
        return false;
    }
    
    if(m_riskRewardRatio <= 0) {
        Print("Invalid risk/reward ratio");
        return false;
    }
    
    if(m_maxSpread <= 0) {
        Print("Invalid max spread");
        return false;
    }
    
    if(m_lotSize < MarketInfo(m_symbol, MODE_MINLOT) || 
       m_lotSize > MarketInfo(m_symbol, MODE_MAXLOT)) {
        Print("Invalid lot size");
        return false;
    }
    
    return true;
}
