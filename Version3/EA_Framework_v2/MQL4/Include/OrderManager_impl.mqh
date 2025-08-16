//+------------------------------------------------------------------+
//|                                              OrderManager_impl.mqh |
//|                              Copyright 2025, Golden Candle Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle Team"
#property strict

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
COrderManager::COrderManager() {
    m_isInitialized = false;
    m_orderCount = 0;
    ArrayResize(m_orders, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
COrderManager::~COrderManager() {
    if(HasOpenPositions()) {
        CloseAllPositions();
    }
}

//+------------------------------------------------------------------+
//| Initialize the Order Manager                                       |
//+------------------------------------------------------------------+
bool COrderManager::Init(string symbol, int magic, CLevelManager* levelMgr) {
    if(symbol == "" || magic <= 0 || levelMgr == NULL) {
        Print("Invalid initialization parameters");
        return false;
    }
    
    m_symbol = symbol;
    m_magicNumber = magic;
    m_levelManager = levelMgr;
    m_isInitialized = true;
    
    return true;
}

//+------------------------------------------------------------------+
//| Open a single position                                            |
//+------------------------------------------------------------------+
bool COrderManager::OpenPosition(int type, double lots, double price,
                              double sl, double tp, ENUM_ORDER_QUALIFICATION qual) {
    if(!m_isInitialized || !ValidateOrder(type, lots, price, sl, tp)) {
        return false;
    }
    
    int ticket = OrderSend(m_symbol, type, lots, price, 3, sl, tp,
                          "Level " + IntegerToString(m_levelManager.GetCurrentLevel()),
                          m_magicNumber, 0, clrNONE);
    
    if(ticket <= 0) {
        Print("Failed to open order: ", GetLastError());
        return false;
    }
    
    // Add to orders array
    int idx = ArraySize(m_orders);
    ArrayResize(m_orders, idx + 1);
    m_orders[idx].ticket = ticket;
    m_orders[idx].type = type;
    m_orders[idx].lots = lots;
    m_orders[idx].openPrice = price;
    m_orders[idx].stopLoss = sl;
    m_orders[idx].takeProfit = tp;
    m_orders[idx].qual = qual;
    m_orders[idx].openTime = TimeCurrent();
    m_orders[idx].isComplete = false;
    
    m_orderCount++;
    return true;
}

//+------------------------------------------------------------------+
//| Open all orders for current level                                 |
//+------------------------------------------------------------------+
bool COrderManager::OpenLevelOrders(int type, double basePrice) {
    if(!m_isInitialized || HasOpenPositions()) return false;
    
    int numOrders = m_levelManager.GetNumOrders();
    double baseLot = m_levelManager.GetBaseLot();
    
    for(int i = 0; i < numOrders; i++) {
        double rr = m_levelManager.GetRiskReward(i);
        ENUM_ORDER_QUALIFICATION qual = m_levelManager.GetQualification(i);
        
        double sl = type == OP_BUY ? basePrice - 10000 * Point : basePrice + 10000 * Point;
        double tp = type == OP_BUY ? basePrice + (10000 * rr * Point) : basePrice - (10000 * rr * Point);
        
        if(!OpenPosition(type, baseLot, basePrice, sl, tp, qual)) {
            CloseAllPositions();
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Close all open positions                                          |
//+------------------------------------------------------------------+
bool COrderManager::CloseAllPositions() {
    bool success = true;
    
    for(int i = ArraySize(m_orders) - 1; i >= 0; i--) {
        if(m_orders[i].isComplete) continue;
        
        if(OrderSelect(m_orders[i].ticket, SELECT_BY_TICKET)) {
            if(OrderType() <= OP_SELL) {  // Only market orders
                bool closed = OrderClose(m_orders[i].ticket, m_orders[i].lots,
                                      OrderType() == OP_BUY ? Bid : Ask,
                                      3, clrNONE);
                if(!closed) {
                    success = false;
                    Print("Failed to close order ", m_orders[i].ticket, ": ", GetLastError());
                }
            }
        }
    }
    
    if(success) {
        ArrayResize(m_orders, 0);
        m_orderCount = 0;
    }
    
    return success;
}

//+------------------------------------------------------------------+
//| Modify position's stop loss and take profit                       |
//+------------------------------------------------------------------+
bool COrderManager::ModifyPosition(int ticket, double sl, double tp) {
    if(!m_isInitialized) return false;
    
    for(int i = 0; i < ArraySize(m_orders); i++) {
        if(m_orders[i].ticket == ticket && !m_orders[i].isComplete) {
            if(OrderSelect(ticket, SELECT_BY_TICKET)) {
                bool modified = OrderModify(ticket, OrderOpenPrice(), sl, tp, 0);
                if(modified) {
                    m_orders[i].stopLoss = sl;
                    m_orders[i].takeProfit = tp;
                    return true;
                }
                Print("Failed to modify order ", ticket, ": ", GetLastError());
            }
            break;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Get total profit of all positions                                 |
//+------------------------------------------------------------------+
double COrderManager::GetTotalProfit() {
    double total = 0;
    
    for(int i = 0; i < ArraySize(m_orders); i++) {
        if(!m_orders[i].isComplete && OrderSelect(m_orders[i].ticket, SELECT_BY_TICKET)) {
            total += OrderProfit();
        }
    }
    
    return total;
}

//+------------------------------------------------------------------+
//| Check if current level is complete                                |
//+------------------------------------------------------------------+
bool COrderManager::IsLevelComplete() const {
    if(!m_isInitialized || !m_levelManager) return false;
    
    int completedOrders = 0;
    for(int i = 0; i < ArraySize(m_orders); i++) {
        if(m_orders[i].isComplete) completedOrders++;
    }
    
    return completedOrders >= m_levelManager.GetNumOrders();
}

//+------------------------------------------------------------------+
//| Check if can advance to next level                                |
//+------------------------------------------------------------------+
bool COrderManager::CanAdvanceLevel() const {
    if(!m_isInitialized || !m_levelManager) return false;
    
    int successfulOrders = 0;
    for(int i = 0; i < ArraySize(m_orders); i++) {
        if(m_orders[i].isComplete && m_orders[i].isProfit) 
            successfulOrders++;
    }
    
    return successfulOrders >= m_levelManager.GetNumOrders();
}

//+------------------------------------------------------------------+
//| Check and update status of all orders                             |
//+------------------------------------------------------------------+
void COrderManager::CheckOrdersStatus() {
    if(!m_isInitialized) return;
    
    for(int i = 0; i < ArraySize(m_orders); i++) {
        if(!m_orders[i].isComplete) {
            UpdateOrderStatus(m_orders[i].ticket);
        }
    }
}

//+------------------------------------------------------------------+
//| Update status of a single order                                   |
//+------------------------------------------------------------------+
bool COrderManager::UpdateOrderStatus(int ticket) {
    if(!OrderSelect(ticket, SELECT_BY_TICKET)) return false;
    
    for(int i = 0; i < ArraySize(m_orders); i++) {
        if(m_orders[i].ticket == ticket && !m_orders[i].isComplete) {
            if(OrderCloseTime() != 0) {  // Order is closed
                m_orders[i].isComplete = true;
                m_orders[i].isProfit = OrderProfit() > 0;
                m_orderCount--;
                
                // Notify level manager
                m_levelManager.OnOrderComplete(m_orders[i].isProfit);
            }
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Validate order parameters                                         |
//+------------------------------------------------------------------+
bool COrderManager::ValidateOrder(int type, double lots, double price,
                               double sl, double tp) {
    if(type != OP_BUY && type != OP_SELL) {
        Print("Invalid order type");
        return false;
    }
    
    if(lots < MarketInfo(m_symbol, MODE_MINLOT) ||
       lots > MarketInfo(m_symbol, MODE_MAXLOT)) {
        Print("Invalid lot size");
        return false;
    }
    
    double minStop = MarketInfo(m_symbol, MODE_STOPLEVEL) * Point;
    
    if(type == OP_BUY) {
        if(MathAbs(price - Ask) < minStop) {
            Print("Invalid buy price");
            return false;
        }
        if(MathAbs(Ask - sl) < minStop) {
            Print("Invalid buy stop loss");
            return false;
        }
        if(MathAbs(tp - Ask) < minStop) {
            Print("Invalid buy take profit");
            return false;
        }
    }
    else {
        if(MathAbs(Bid - price) < minStop) {
            Print("Invalid sell price");
            return false;
        }
        if(MathAbs(sl - Bid) < minStop) {
            Print("Invalid sell stop loss");
            return false;
        }
        if(MathAbs(Bid - tp) < minStop) {
            Print("Invalid sell take profit");
            return false;
        }
    }
    
    return true;
}
