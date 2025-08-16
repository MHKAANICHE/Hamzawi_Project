//+------------------------------------------------------------------+
//|                                                  MASystem.mqh |
//|                              Copyright 2025, Golden Candle Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle Team"
#property strict

// MA System Configuration
#define MA_FAST_PERIOD    1
#define MA_FAST_SHIFT     0
#define MA_SLOW_PERIOD    3
#define MA_SLOW_SHIFT     1
#define MA_METHOD         MODE_EMA
#define MA_PRICE         PRICE_CLOSE

// Visual Settings
#define UP_ARROW_CODE     233
#define DOWN_ARROW_CODE   234
#define UP_ARROW_COLOR    clrOrangeRed
#define DOWN_ARROW_COLOR  clrMagenta
#define ARROW_SIZE       2

//+------------------------------------------------------------------+
//| Moving Average System Class                                        |
//+------------------------------------------------------------------+
class CMASystem {
private:
    string            m_symbol;
    ENUM_TIMEFRAMES   m_timeframe;
    bool              m_initialized;
    
    // MA handles
    int               m_fastMA;
    int               m_slowMA;
    
    // Signal tracking
    datetime          m_lastSignalTime;
    double            m_lastSignalPrice;
    bool              m_lastSignalBuy;
    
    // Arrow management
    string            CreateArrowName(datetime time);
    bool              DrawArrow(datetime time, double price, bool isBuy);
    
    // Signal validation
    bool              ValidateCrossover(int shift);
    
public:
                     CMASystem();
                    ~CMASystem();
    
    // Initialization
    bool             Init(string symbol, ENUM_TIMEFRAMES tf);
    
    // Signal detection
    bool             CheckSignal(int shift = 1);
    bool             GetLastSignal(datetime &time, double &price, bool &isBuy);
    
    // Cleanup
    void             RemoveArrows();
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CMASystem::CMASystem() {
    m_symbol = NULL;
    m_timeframe = PERIOD_CURRENT;
    m_initialized = false;
    m_fastMA = INVALID_HANDLE;
    m_slowMA = INVALID_HANDLE;
    m_lastSignalTime = 0;
    m_lastSignalPrice = 0;
    m_lastSignalBuy = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CMASystem::~CMASystem() {
    RemoveArrows();
}

//+------------------------------------------------------------------+
//| Initialize the MA System                                           |
//+------------------------------------------------------------------+
bool CMASystem::Init(string symbol, ENUM_TIMEFRAMES tf) {
    if(symbol == "") return false;
    
    m_symbol = symbol;
    m_timeframe = tf;
    
    // Initialize indicators
    m_fastMA = iMA(symbol, tf, MA_FAST_PERIOD, MA_FAST_SHIFT, 
                  MA_METHOD, MA_PRICE);
    m_slowMA = iMA(symbol, tf, MA_SLOW_PERIOD, MA_SLOW_SHIFT,
                  MA_METHOD, MA_PRICE);
    
    if(m_fastMA == INVALID_HANDLE || m_slowMA == INVALID_HANDLE) {
        Print("Failed to create MA indicators");
        return false;
    }
    
    m_initialized = true;
    return true;
}

//+------------------------------------------------------------------+
//| Create unique arrow name                                           |
//+------------------------------------------------------------------+
string CMASystem::CreateArrowName(datetime time) {
    return "MA_Arrow_" + TimeToString(time);
}

//+------------------------------------------------------------------+
//| Draw arrow on chart                                               |
//+------------------------------------------------------------------+
bool CMASystem::DrawArrow(datetime time, double price, bool isBuy) {
    string name = CreateArrowName(time);
    
    if(ObjectCreate(0, name, OBJ_ARROW, 0, time, price)) {
        ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 
                        isBuy ? UP_ARROW_CODE : DOWN_ARROW_CODE);
        ObjectSetInteger(0, name, OBJPROP_COLOR,
                        isBuy ? UP_ARROW_COLOR : DOWN_ARROW_COLOR);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, ARROW_SIZE);
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Remove all arrows                                                  |
//+------------------------------------------------------------------+
void CMASystem::RemoveArrows() {
    ObjectsDeleteAll(0, "MA_Arrow_");
}

//+------------------------------------------------------------------+
//| Validate MA crossover                                             |
//+------------------------------------------------------------------+
bool CMASystem::ValidateCrossover(int shift) {
    if(shift <= 0) return false;
    
    double fastMA1 = iMA(m_symbol, m_timeframe, MA_FAST_PERIOD, MA_FAST_SHIFT,
                        MA_METHOD, MA_PRICE, shift);
    double fastMA2 = iMA(m_symbol, m_timeframe, MA_FAST_PERIOD, MA_FAST_SHIFT,
                        MA_METHOD, MA_PRICE, shift + 1);
    double slowMA1 = iMA(m_symbol, m_timeframe, MA_SLOW_PERIOD, MA_SLOW_SHIFT,
                        MA_METHOD, MA_PRICE, shift);
    double slowMA2 = iMA(m_symbol, m_timeframe, MA_SLOW_PERIOD, MA_SLOW_SHIFT,
                        MA_METHOD, MA_PRICE, shift + 1);
    
    // Check for crossover
    bool crossUp = fastMA2 < slowMA2 && fastMA1 > slowMA1;
    bool crossDown = fastMA2 > slowMA2 && fastMA1 < slowMA1;
    
    return crossUp || crossDown;
}

//+------------------------------------------------------------------+
//| Check for new signals                                             |
//+------------------------------------------------------------------+
bool CMASystem::CheckSignal(int shift = 1) {
    if(!m_initialized || shift <= 0) return false;
    
    datetime time = iTime(m_symbol, m_timeframe, shift);
    if(time <= m_lastSignalTime) return false;
    
    // Validate crossover
    if(!ValidateCrossover(shift)) return false;
    
    // Get MA values
    double fastMA = iMA(m_symbol, m_timeframe, MA_FAST_PERIOD, MA_FAST_SHIFT,
                       MA_METHOD, MA_PRICE, shift);
    double slowMA = iMA(m_symbol, m_timeframe, MA_SLOW_PERIOD, MA_SLOW_SHIFT,
                       MA_METHOD, MA_PRICE, shift);
    
    // Determine signal direction
    bool isBuy = fastMA > slowMA;
    double price = iClose(m_symbol, m_timeframe, shift);
    
    // Draw arrow
    if(DrawArrow(time, price, isBuy)) {
        m_lastSignalTime = time;
        m_lastSignalPrice = price;
        m_lastSignalBuy = isBuy;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Get last signal details                                           |
//+------------------------------------------------------------------+
bool CMASystem::GetLastSignal(datetime &time, double &price, bool &isBuy) {
    if(!m_initialized || m_lastSignalTime == 0) return false;
    
    time = m_lastSignalTime;
    price = m_lastSignalPrice;
    isBuy = m_lastSignalBuy;
    return true;
}
