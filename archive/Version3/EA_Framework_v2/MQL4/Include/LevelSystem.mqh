//+------------------------------------------------------------------+
//|                                                   LevelSystem.mqh |
//|                              Copyright 2025, Golden Candle Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle Team"
#property strict

// Level qualification IDs
enum ENUM_ORDER_QUALIFICATION {
    LEVEL_1_MAIN = 1001,      // Single order levels (1-6)
    LEVEL_7_FIRST = 7001,     // First order of level 7
    LEVEL_7_SECOND = 7002,    // Second order of level 7
    LEVEL_8_FIRST = 8001,     // First order of level 8
    LEVEL_8_SECOND = 8002,    // Second order of level 8
    LEVEL_9_FIRST = 9001,     // First order of level 9
    LEVEL_9_SECOND = 9002,    // Second order of level 9
    LEVEL_10_FIRST = 10001,   // First order of level 10
    LEVEL_10_SECOND = 10002,  // Second order of level 10
    LEVEL_11_FIRST = 11001,   // First order of level 11
    LEVEL_11_SECOND = 11002,  // Second order of level 11
    LEVEL_11_THIRD = 11003,   // Third order of level 11
    LEVEL_12_FIRST = 12001,   // First order of level 12
    LEVEL_12_SECOND = 12002,  // Second order of level 12
    LEVEL_12_THIRD = 12003    // Third order of level 12
};

// Level Setup Structure
struct SLevelSetup {
    int level;                       // Level number (1-25)
    double baseLot;                 // Base lot size (always 0.01)
    int numOrders;                  // Number of simultaneous orders
    double riskReward[];           // Risk:Reward ratios for each order
    ENUM_ORDER_QUALIFICATION quals[]; // Qualification IDs for orders
    
    void Init(const int _level, const double _baseLot, const int _numOrders) {
        level = _level;
        baseLot = _baseLot;
        numOrders = _numOrders;
        ArrayResize(riskReward, numOrders);
        ArrayResize(quals, numOrders);
        InitializeRiskReward();
        InitializeQuals();
    }
    
private:
    void InitializeRiskReward() {
        if(level <= 6) {
            riskReward[0] = level + 1;  // Levels 1-6: Single order with increasing R:R
        }
        else {
            switch(level) {
                case 7:  // Level 7: Two orders with 1:1 and 1:7
                    riskReward[0] = 1.0;
                    riskReward[1] = 7.0;
                    break;
                    
                case 8:  // Level 8: Two orders with 1:3 and 1:7
                    riskReward[0] = 3.0;
                    riskReward[1] = 7.0;
                    break;
                    
                case 9:  // Level 9: Two orders with 1:5 and 1:7
                    riskReward[0] = 5.0;
                    riskReward[1] = 7.0;
                    break;
                    
                case 10: // Level 10: Two orders with 1:7 and 1:7
                    riskReward[0] = 7.0;
                    riskReward[1] = 7.0;
                    break;
                    
                case 11: // Level 11: Three orders with 1:3, 1:7, 1:7
                    riskReward[0] = 3.0;
                    riskReward[1] = 7.0;
                    riskReward[2] = 7.0;
                    break;
                    
                case 12: // Level 12: Three orders with 1:5, 1:7, 1:7
                    riskReward[0] = 5.0;
                    riskReward[1] = 7.0;
                    riskReward[2] = 7.0;
                    break;
            }
        }
    }
    
    void InitializeQuals() {
        if(level <= 6) {
            quals[0] = (ENUM_ORDER_QUALIFICATION)(LEVEL_1_MAIN + level - 1);
        }
        else {
            switch(level) {
                case 7:
                    quals[0] = LEVEL_7_FIRST;
                    quals[1] = LEVEL_7_SECOND;
                    break;
                case 8:
                    quals[0] = LEVEL_8_FIRST;
                    quals[1] = LEVEL_8_SECOND;
                    break;
                case 9:
                    quals[0] = LEVEL_9_FIRST;
                    quals[1] = LEVEL_9_SECOND;
                    break;
                case 10:
                    quals[0] = LEVEL_10_FIRST;
                    quals[1] = LEVEL_10_SECOND;
                    break;
                case 11:
                    quals[0] = LEVEL_11_FIRST;
                    quals[1] = LEVEL_11_SECOND;
                    quals[2] = LEVEL_11_THIRD;
                    break;
                case 12:
                    quals[0] = LEVEL_12_FIRST;
                    quals[1] = LEVEL_12_SECOND;
                    quals[2] = LEVEL_12_THIRD;
                    break;
            }
        }
    }
};

//+------------------------------------------------------------------+
//| Level Manager Class                                                |
//+------------------------------------------------------------------+
class CLevelManager {
private:
    SLevelSetup m_currentSetup;    // Current level setup
    int m_currentLevel;            // Current level number
    bool m_isInitialized;         // Initialization flag
    
    int m_completedOrders;        // Number of completed orders in current level
    int m_successfulOrders;       // Number of successful orders in current level
    
    bool ValidateLevel(int level) {
        return level >= 1 && level <= 12;  // Currently supporting levels 1-12
    }
    
public:
                     CLevelManager();
                    ~CLevelManager() { }
    
    // Initialization
    bool             Init(const int startLevel = 1);
    void             Reset();
    
    // Level Management
    bool             SetLevel(const int level);
    int              GetCurrentLevel()  const { return m_currentLevel; }
    SLevelSetup*     GetCurrentSetup() { return &m_currentSetup; }
    
    // Order Management
    int              GetNumOrders()    const { return m_currentSetup.numOrders; }
    double           GetBaseLot()      const { return m_currentSetup.baseLot; }
    double           GetRiskReward(const int orderIndex);
    ENUM_ORDER_QUALIFICATION GetQualification(const int orderIndex);
    
    // Level Progression
    bool             OnOrderComplete(const bool isProfit);
    bool             IsLevelComplete() const { return m_completedOrders >= m_currentSetup.numOrders; }
    bool             CanAdvanceLevel() const;
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CLevelManager::CLevelManager() {
    m_isInitialized = false;
    Reset();
}

//+------------------------------------------------------------------+
//| Initialize the Level Manager                                       |
//+------------------------------------------------------------------+
bool CLevelManager::Init(const int startLevel = 1) {
    if(!ValidateLevel(startLevel)) {
        Print("Invalid start level: ", startLevel);
        return false;
    }
    
    Reset();
    return SetLevel(startLevel);
}

//+------------------------------------------------------------------+
//| Reset all counters                                                |
//+------------------------------------------------------------------+
void CLevelManager::Reset() {
    m_currentLevel = 0;
    m_completedOrders = 0;
    m_successfulOrders = 0;
}

//+------------------------------------------------------------------+
//| Set current trading level                                         |
//+------------------------------------------------------------------+
bool CLevelManager::SetLevel(const int level) {
    if(!ValidateLevel(level)) {
        Print("Invalid level: ", level);
        return false;
    }
    
    // Calculate number of orders for this level
    int numOrders = (level <= 6) ? 1 : 
                    (level <= 10) ? 2 : 3;
    
    // Initialize level setup
    m_currentSetup.Init(level, 0.01, numOrders);  // Fixed 0.01 lot size
    m_currentLevel = level;
    m_completedOrders = 0;
    m_successfulOrders = 0;
    
    m_isInitialized = true;
    return true;
}

//+------------------------------------------------------------------+
//| Get Risk:Reward ratio for specific order                          |
//+------------------------------------------------------------------+
double CLevelManager::GetRiskReward(const int orderIndex) {
    if(!m_isInitialized || orderIndex >= m_currentSetup.numOrders) 
        return 0.0;
        
    return m_currentSetup.riskReward[orderIndex];
}

//+------------------------------------------------------------------+
//| Get qualification ID for specific order                           |
//+------------------------------------------------------------------+
ENUM_ORDER_QUALIFICATION CLevelManager::GetQualification(const int orderIndex) {
    if(!m_isInitialized || orderIndex >= m_currentSetup.numOrders) 
        return LEVEL_1_MAIN;
        
    return m_currentSetup.quals[orderIndex];
}

//+------------------------------------------------------------------+
//| Process completed order result                                    |
//+------------------------------------------------------------------+
bool CLevelManager::OnOrderComplete(const bool isProfit) {
    if(!m_isInitialized) return false;
    
    m_completedOrders++;
    if(isProfit) m_successfulOrders++;
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if can advance to next level                                |
//+------------------------------------------------------------------+
bool CLevelManager::CanAdvanceLevel() const {
    if(!m_isInitialized || !IsLevelComplete()) return false;
    
    // Need all orders to be successful to advance
    return m_successfulOrders == m_currentSetup.numOrders;
}
