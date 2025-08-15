//+------------------------------------------------------------------+
//| TrailingStop.mqh - Trailing stop logic for open trades           |
//+------------------------------------------------------------------+
#ifndef __TRAILINGSTOP_MQH__
#define __TRAILINGSTOP_MQH__

#include "OrderManager.mqh"
#include "Logger.mqh"

class TrailingStop {
public:
    static void TrailingStopLogic(double GoldenCandleMinSize) {
        for(int i=0; i<OrdersTotal(); ++i) {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
                if(OrderSymbol() == Symbol() && OrderMagicNumber() == 123456) {
                    double entry = OrderOpenPrice();
                    double sl = OrderStopLoss();
                    double price = (OrderType() == OP_BUY) ? Bid : Ask;
                    double ladderStep = GoldenCandleMinSize > 0 ? GoldenCandleMinSize : 100;
                    // Move SL to breakeven at 3rd ladder level (Buy)
                    if(OrderType() == OP_BUY && price >= entry + 3*ladderStep && sl < entry) {
                        bool mod = OrderManager::OrderModifyWithRetries(OrderTicket(), entry, entry, OrderTakeProfit(), 0, clrBlue);
                        if(mod) {
                            Logger::LogEvent("TRAIL", "Buy SL moved to breakeven (3rd level)");
                            if(!IsTesting()) Logger::ShowAlert("Buy SL moved to breakeven (3rd level)");
                        }
                    }
                    // Move SL to first ladder level at 6th ladder level (Buy)
                    if(OrderType() == OP_BUY && price >= entry + 6*ladderStep && sl < entry+ladderStep) {
                        bool mod = OrderManager::OrderModifyWithRetries(OrderTicket(), entry, entry+ladderStep, OrderTakeProfit(), 0, clrBlue);
                        if(mod) {
                            Logger::LogEvent("TRAIL", "Buy SL moved to first ladder level (6th level)");
                            if(!IsTesting()) Logger::ShowAlert("Buy SL moved to first ladder level (6th level)");
                        }
                    }
                    // Move SL to breakeven at 3rd ladder level (Sell)
                    if(OrderType() == OP_SELL && price <= entry - 3*ladderStep && sl > entry) {
                        bool mod = OrderManager::OrderModifyWithRetries(OrderTicket(), entry, entry, OrderTakeProfit(), 0, clrRed);
                        if(mod) {
                            Logger::LogEvent("TRAIL", "Sell SL moved to breakeven (3rd level)");
                            if(!IsTesting()) Logger::ShowAlert("Sell SL moved to breakeven (3rd level)");
                        }
                    }
                    // Move SL to first ladder level at 6th ladder level (Sell)
                    if(OrderType() == OP_SELL && price <= entry - 6*ladderStep && sl > entry-ladderStep) {
                        bool mod = OrderManager::OrderModifyWithRetries(OrderTicket(), entry, entry-ladderStep, OrderTakeProfit(), 0, clrRed);
                        if(mod) {
                            Logger::LogEvent("TRAIL", "Sell SL moved to first ladder level (6th level)");
                            if(!IsTesting()) Logger::ShowAlert("Sell SL moved to first ladder level (6th level)");
                        }
                    }
                }
            }
        }
    }
};

#endif // __TRAILINGSTOP_MQH__
