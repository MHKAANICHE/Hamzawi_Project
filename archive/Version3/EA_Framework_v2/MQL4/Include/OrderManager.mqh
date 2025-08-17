//+------------------------------------------------------------------+
//|                                                   OrderManager.mqh |
//|                              Copyright 2025, Golden Candle Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle Team"
#property strict

#include "LevelSystem.mqh"

// Order structure
struct SOrder {
    int ticket;
    int type;
    double lots;
    double openPrice;
    double stopLoss;
    double takeProfit;
    ENUM_ORDER_QUALIFICATION qual;
    datetime openTime;
    bool isComplete;
    bool isProfit;
    
    void Clear() {
        ticket = 0;
        type = -1;
        lots = 0;
        openPrice = 0;
        stopLoss = 0;
        takeProfit = 0;
        qual = LEVEL_1_MAIN;
        openTime = 0;
        isComplete = false;
        isProfit = false;
    }
};

//+------------------------------------------------------------------+
//| Order Manager Class                                                |
//+------------------------------------------------------------------+
class COrderManager {
private:
    string            m_symbol;
    int              m_magicNumber;
    CLevelManager*    m_levelManager;
    bool             m_isInitialized;
    
    SOrder           m_orders[];          // Current level orders
    int              m_orderCount;        // Number of active orders
    
    bool             ValidateOrder(int type, double lots, double price, 
                                double sl, double tp);
    void             CheckOrdersStatus();
    
public:
                     COrderManager();
                    ~COrderManager();
    
    bool             Init(string symbol, int magic, CLevelManager* levelMgr);
    bool             OpenPosition(int type, double lots, double price, 
                               double sl, double tp, ENUM_ORDER_QUALIFICATION qual);
    bool             OpenLevelOrders(int type, double basePrice);
    bool             CloseAllPositions();
    bool             HasOpenPositions() const { return m_orderCount > 0; }
    bool             ModifyPosition(int ticket, double sl, double tp);
    double           GetTotalProfit();
    
    // Level management
    bool             IsLevelComplete() const;
    bool             CanAdvanceLevel() const;
};
