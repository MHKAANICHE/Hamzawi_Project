//+------------------------------------------------------------------+
//|                                                  LevelManager.mqh |
//|                              Copyright 2025, Golden Candle Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle Team"
#property strict

// Level setup structure
struct SLevelSetup {
    int level;            // Current level (1-25)
    double baseLot;       // Base lot size (0.01)
    int numOrders;        // Number of orders for this level
    double riskReward[]; // Risk:Reward ratios for each order
    
    void Init(int l, double lot, int orders) {
        level = l;
        baseLot = lot;
        numOrders = orders;
        ArrayResize(riskReward, orders);
    }
};

//+------------------------------------------------------------------+
//| Level Manager Class                                                |
//+------------------------------------------------------------------+
class CLevelManager {
private:
    SLevelSetup       m_currentLevel;
    int              m_levelNumber;
    
    void             InitializeLevel(int level);
    
public:
                     CLevelManager();
                    ~CLevelManager();
    
    bool             Init(int startLevel = 1);
    void             SetLevel(int level);
    int              GetCurrentLevel()    { return m_levelNumber; }
    int              GetNumOrders()       { return m_currentLevel.numOrders; }
    double           GetLotSize()         { return m_currentLevel.baseLot; }
    double           GetRiskReward(int orderIndex);
    
    bool             OnTradeResult(bool isProfit);
};
