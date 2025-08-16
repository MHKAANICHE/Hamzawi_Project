//+------------------------------------------------------------------+
//|                                         TakeProfitManager.mqh |
//|                              Copyright 2025, Golden Candle Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle Team"
#property strict

// Take Profit Configuration
#define MAX_TP_LEVELS    7     // Maximum number of TP levels
#define TP_LINE_STYLE    STYLE_DOT
#define TP_LINE_WIDTH    1

//+------------------------------------------------------------------+
//| Take Profit Level Structure                                        |
//+------------------------------------------------------------------+
struct STPLevel {
    int     level;          // Level number
    double  price;          // Target price
    double  lotSize;        // Lot size to close
    double  riskReward;     // Risk:Reward ratio
    bool    reached;        // Whether level was reached
    string  lineId;         // Chart line identifier
    
    void Init(int lvl, double tp, double lots, double rr) {
        level = lvl;
        price = tp;
        lotSize = lots;
        riskReward = rr;
        reached = false;
        lineId = "TP_Line_" + IntegerToString(lvl);
    }
};

//+------------------------------------------------------------------+
//| Take Profit Management Class                                       |
//+------------------------------------------------------------------+
class CTakeProfitManager {
private:
    string      m_symbol;
    int         m_magicNumber;
    bool        m_initialized;
    
    // TP tracking
    STPLevel    m_levels[];
    int         m_levelCount;
    int         m_currentLevel;
    
    // Visual elements
    color       m_tpColors[MAX_TP_LEVELS];
    
    // Internal methods
    bool        CreateTPLine(STPLevel &level);
    void        UpdateTPLine(STPLevel &level);
    void        RemoveTPLine(const STPLevel &level);
    bool        ValidateTPLevel(double price);
    
public:
                CTakeProfitManager();
               ~CTakeProfitManager();
    
    // Initialization
    bool        Init(string symbol, int magic);
    
    // Level management
    bool        SetTPLevels(double entryPrice, double stopLoss, bool isBuy);
    bool        UpdateLevels(double price);
    void        ClearLevels();
    
    // Level operations
    bool        AddLevel(double price, double lots, double rr);
    bool        RemoveLevel(int level);
    
    // Status checks
    bool        IsLevelReached(int level) const;
    int         GetCurrentLevel() const { return m_currentLevel; }
    double      GetLevelPrice(int level) const;
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CTakeProfitManager::CTakeProfitManager() {
    m_symbol = NULL;
    m_magicNumber = 0;
    m_initialized = false;
    m_levelCount = 0;
    m_currentLevel = 0;
    
    // Initialize TP level colors
    m_tpColors[0] = clrGreen;
    m_tpColors[1] = clrLime;
    m_tpColors[2] = clrYellowGreen;
    m_tpColors[3] = clrGold;
    m_tpColors[4] = clrOrange;
    m_tpColors[5] = clrOrangeRed;
    m_tpColors[6] = clrRed;
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CTakeProfitManager::~CTakeProfitManager() {
    ClearLevels();
}

//+------------------------------------------------------------------+
//| Initialize Take Profit Manager                                     |
//+------------------------------------------------------------------+
bool CTakeProfitManager::Init(string symbol, int magic) {
    if(symbol == "" || magic <= 0) return false;
    
    m_symbol = symbol;
    m_magicNumber = magic;
    m_initialized = true;
    
    return true;
}

//+------------------------------------------------------------------+
//| Create TP level visualization                                      |
//+------------------------------------------------------------------+
bool CTakeProfitManager::CreateTPLine(STPLevel &level) {
    if(ObjectFind(0, level.lineId) >= 0) {
        ObjectDelete(0, level.lineId);
    }
    
    if(!ObjectCreate(0, level.lineId, OBJ_HLINE, 0, 0, level.price)) {
        Print("Failed to create TP line: ", GetLastError());
        return false;
    }
    
    ObjectSet(level.lineId, OBJPROP_COLOR, m_tpColors[level.level - 1]);
    ObjectSet(level.lineId, OBJPROP_STYLE, TP_LINE_STYLE);
    ObjectSet(level.lineId, OBJPROP_WIDTH, TP_LINE_WIDTH);
    
    return true;
}

//+------------------------------------------------------------------+
//| Update TP line position                                           |
//+------------------------------------------------------------------+
void CTakeProfitManager::UpdateTPLine(STPLevel &level) {
    if(ObjectFind(0, level.lineId) >= 0) {
        ObjectMove(0, level.lineId, 0, 0, level.price);
    }
}

//+------------------------------------------------------------------+
//| Remove TP line                                                     |
//+------------------------------------------------------------------+
void CTakeProfitManager::RemoveTPLine(const STPLevel &level) {
    ObjectDelete(0, level.lineId);
}

//+------------------------------------------------------------------+
//| Validate TP level price                                           |
//+------------------------------------------------------------------+
bool CTakeProfitManager::ValidateTPLevel(double price) {
    if(price <= 0) return false;
    
    double minDistance = MarketInfo(m_symbol, MODE_STOPLEVEL) * Point;
    double bid = MarketInfo(m_symbol, MODE_BID);
    double ask = MarketInfo(m_symbol, MODE_ASK);
    
    return MathAbs(price - bid) >= minDistance && 
           MathAbs(price - ask) >= minDistance;
}

//+------------------------------------------------------------------+
//| Set TP levels based on entry                                      |
//+------------------------------------------------------------------+
bool CTakeProfitManager::SetTPLevels(double entryPrice, double stopLoss, 
                                    bool isBuy) {
    if(!m_initialized) return false;
    
    ClearLevels();
    
    double riskDistance = MathAbs(entryPrice - stopLoss);
    
    // Calculate and add TP levels
    for(int i = 0; i < MAX_TP_LEVELS; i++) {
        double rr = i + 2.0;  // R:R starts from 1:2
        double tpDistance = riskDistance * rr;
        double tpPrice = isBuy ? entryPrice + tpDistance : 
                                entryPrice - tpDistance;
        
        // Calculate lots for partial closure
        double baseLots = 0.1;  // Should come from money management
        double levelLots = baseLots / (i + 1);
        
        if(!AddLevel(tpPrice, levelLots, rr)) {
            ClearLevels();
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Add new TP level                                                  |
//+------------------------------------------------------------------+
bool CTakeProfitManager::AddLevel(double price, double lots, double rr) {
    if(!ValidateTPLevel(price)) return false;
    
    int idx = ArraySize(m_levels);
    ArrayResize(m_levels, idx + 1);
    
    m_levels[idx].Init(idx + 1, price, lots, rr);
    if(!CreateTPLine(m_levels[idx])) return false;
    
    m_levelCount++;
    return true;
}

//+------------------------------------------------------------------+
//| Remove TP level                                                   |
//+------------------------------------------------------------------+
bool CTakeProfitManager::RemoveLevel(int level) {
    if(level <= 0 || level > m_levelCount) return false;
    
    RemoveTPLine(m_levels[level - 1]);
    
    // Shift remaining levels
    for(int i = level - 1; i < m_levelCount - 1; i++) {
        m_levels[i] = m_levels[i + 1];
    }
    
    m_levelCount--;
    ArrayResize(m_levels, m_levelCount);
    return true;
}

//+------------------------------------------------------------------+
//| Update TP levels status                                           |
//+------------------------------------------------------------------+
bool CTakeProfitManager::UpdateLevels(double price) {
    if(!m_initialized || m_levelCount == 0) return false;
    
    bool updated = false;
    
    for(int i = 0; i < m_levelCount; i++) {
        if(!m_levels[i].reached) {
            bool isBuy = m_levels[i].price > price;
            bool reached = isBuy ? price >= m_levels[i].price :
                                 price <= m_levels[i].price;
            
            if(reached) {
                m_levels[i].reached = true;
                m_currentLevel = m_levels[i].level;
                updated = true;
            }
        }
    }
    
    return updated;
}

//+------------------------------------------------------------------+
//| Clear all TP levels                                               |
//+------------------------------------------------------------------+
void CTakeProfitManager::ClearLevels() {
    for(int i = 0; i < m_levelCount; i++) {
        RemoveTPLine(m_levels[i]);
    }
    
    ArrayResize(m_levels, 0);
    m_levelCount = 0;
    m_currentLevel = 0;
}

//+------------------------------------------------------------------+
//| Check if level is reached                                         |
//+------------------------------------------------------------------+
bool CTakeProfitManager::IsLevelReached(int level) const {
    if(level <= 0 || level > m_levelCount) return false;
    return m_levels[level - 1].reached;
}

//+------------------------------------------------------------------+
//| Get level price                                                   |
//+------------------------------------------------------------------+
double CTakeProfitManager::GetLevelPrice(int level) const {
    if(level <= 0 || level > m_levelCount) return 0;
    return m_levels[level - 1].price;
}
