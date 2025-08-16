//+------------------------------------------------------------------+
//|                                         StopLossManager.mqh |
//|                              Copyright 2025, Golden Candle Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle Team"
#property strict

// Stop loss adjustment levels
#define SL_BREAKEVEN_TARGET_LEVEL  3     // Move to breakeven at 3rd target
#define SL_FIRST_LEVEL_TARGET      6     // Move to 1st level at 6th target

//+------------------------------------------------------------------+
//| Dynamic stop loss management class                                 |
//+------------------------------------------------------------------+
class CStopLossManager {
private:
    string         m_symbol;              // Trading symbol
    double         m_point;               // Point value
    double         m_stopLevel;           // Minimum stop level (broker)
    
    // Stop loss tracking
    double         m_initialStopLoss;     // Initial SL level
    double         m_currentStopLoss;     // Current SL level
    int           m_targetLevel;          // Current target level reached
    bool          m_isBreakeven;          // Whether at breakeven
    
    // Internal calculations
    double        CalculateBreakevenLevel(double entryPrice, bool isBuy);
    double        CalculateFirstLevel(double entryPrice, bool isBuy);
    bool          ValidateStopLevel(double price, double newSL);
    
public:
                  CStopLossManager();
                 ~CStopLossManager();
    
    // Initialization
    bool          Init(string symbol);
    
    // Stop loss operations
    bool          SetInitialStop(double entryPrice, double stopLoss);
    bool          UpdateStopLoss(double price, int targetLevel);
    
    // Status checks
    bool          IsBreakeven()    const { return m_isBreakeven; }
    double        CurrentStop()     const { return m_currentStopLoss; }
    int           TargetLevel()     const { return m_targetLevel; }
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CStopLossManager::CStopLossManager() {
    m_symbol = NULL;
    m_point = 0;
    m_stopLevel = 0;
    m_initialStopLoss = 0;
    m_currentStopLoss = 0;
    m_targetLevel = 0;
    m_isBreakeven = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CStopLossManager::~CStopLossManager() {
}

//+------------------------------------------------------------------+
//| Initialize the Stop Loss Manager                                   |
//+------------------------------------------------------------------+
bool CStopLossManager::Init(string symbol) {
    if(symbol == "") return false;
    
    m_symbol = symbol;
    m_point = MarketInfo(symbol, MODE_POINT);
    m_stopLevel = MarketInfo(symbol, MODE_STOPLEVEL) * m_point;
    
    return true;
}

//+------------------------------------------------------------------+
//| Set initial stop loss level                                        |
//+------------------------------------------------------------------+
bool CStopLossManager::SetInitialStop(double entryPrice, double stopLoss) {
    if(entryPrice <= 0 || stopLoss <= 0) return false;
    
    // Validate stop level
    if(!ValidateStopLevel(entryPrice, stopLoss)) return false;
    
    m_initialStopLoss = stopLoss;
    m_currentStopLoss = stopLoss;
    m_targetLevel = 0;
    m_isBreakeven = false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate breakeven level                                          |
//+------------------------------------------------------------------+
double CStopLossManager::CalculateBreakevenLevel(double entryPrice, bool isBuy) {
    // Add small buffer to breakeven
    double buffer = 10 * m_point;
    return isBuy ? entryPrice + buffer : entryPrice - buffer;
}

//+------------------------------------------------------------------+
//| Calculate first profit target level                                |
//+------------------------------------------------------------------+
double CStopLossManager::CalculateFirstLevel(double entryPrice, bool isBuy) {
    double distance = MathAbs(entryPrice - m_initialStopLoss);
    double firstLevel = isBuy ? entryPrice + distance : entryPrice - distance;
    return firstLevel;
}

//+------------------------------------------------------------------+
//| Validate stop loss level against broker requirements               |
//+------------------------------------------------------------------+
bool CStopLossManager::ValidateStopLevel(double price, double newSL) {
    double minDistance = m_stopLevel;
    return MathAbs(price - newSL) >= minDistance;
}

//+------------------------------------------------------------------+
//| Update stop loss based on price and target level                  |
//+------------------------------------------------------------------+
bool CStopLossManager::UpdateStopLoss(double price, int targetLevel) {
    if(price <= 0 || targetLevel < m_targetLevel) return false;
    
    bool isBuy = price > m_initialStopLoss;
    double newSL = m_currentStopLoss;
    
    // Move to breakeven at 3rd target
    if(targetLevel >= SL_BREAKEVEN_TARGET_LEVEL && !m_isBreakeven) {
        newSL = CalculateBreakevenLevel(price, isBuy);
        if(ValidateStopLevel(price, newSL)) {
            m_currentStopLoss = newSL;
            m_isBreakeven = true;
        }
    }
    
    // Move to first level at 6th target
    if(targetLevel >= SL_FIRST_LEVEL_TARGET && m_isBreakeven) {
        newSL = CalculateFirstLevel(price, isBuy);
        if(ValidateStopLevel(price, newSL)) {
            m_currentStopLoss = newSL;
        }
    }
    
    m_targetLevel = targetLevel;
    return true;
}
