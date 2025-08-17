//+------------------------------------------------------------------+
//| ManualOrder.mqh - Manual order placement logic                   |
//+------------------------------------------------------------------+
#ifndef __MANUALORDER_MQH__
#define __MANUALORDER_MQH__

#include "OrderManager.mqh"
#include "Logger.mqh"

class ManualOrder {
public:
    static void PlaceManualOrder(ManualOrderParams &mop) {
        int orderType = mop.orderType;
        double lot = NormalizeDouble(mop.lotSize, 2);
        double entry = mop.entryPrice;
        int digits = MarketInfo(Symbol(), MODE_DIGITS);
        double sl = NormalizeDouble(mop.stopLoss, digits);
        double tp = NormalizeDouble(mop.takeProfit, digits);
        double stopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(Symbol(), MODE_POINT);
        double minLot = MarketInfo(Symbol(), MODE_MINLOT);
        double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
        if(lot < minLot || lot > maxLot) {
            string msg = "Lot size " + DoubleToStr(lot,2) + " out of broker limits (min=" + DoubleToStr(minLot,2) + ", max=" + DoubleToStr(maxLot,2) + ")";
            Logger::LogEvent("ERROR", msg);
            if(!IsTesting()) Logger::ShowAlert(msg);
            return;
        }
        int ticket = -1;
        if(orderType == 0) { // Market order
            int cmd = (entry >= Ask) ? OP_BUY : OP_SELL;
            double price = (cmd == OP_BUY) ? Ask : Bid;
            ticket = OrderManager::PlaceOrderWithRetries(Symbol(), cmd, lot, price, 3, sl, tp, "ManualOrder", 123456, clrViolet);
            if(ticket < 0 && GetLastError() == 130) {
                // Adjust stops and retry once
                if(cmd == OP_BUY) {
                    sl = price - stopLevel;
                    tp = price + stopLevel;
                } else {
                    sl = price + stopLevel;
                    tp = price - stopLevel;
                }
                ticket = OrderManager::PlaceOrderWithRetries(Symbol(), cmd, lot, price, 3, sl, tp, "ManualOrder", 123456, clrViolet);
                string msg = "OrderSend error 130: Adjusted stops and retried. SL=" + DoubleToStr(sl,2) + ", TP=" + DoubleToStr(tp,2);
                Logger::LogEvent("ERROR", msg);
                if(!IsTesting()) Logger::ShowAlert(msg);
            }
        } else if(orderType == 1) { // Pending order
            int cmd = (entry >= Ask) ? OP_BUYSTOP : OP_SELLSTOP;
            ticket = OrderManager::PlaceOrderWithRetries(Symbol(), cmd, lot, entry, 3, sl, tp, "ManualOrder", 123456, clrViolet);
            if(ticket < 0 && GetLastError() == 130) {
                // Adjust stops and retry once
                if(cmd == OP_BUYSTOP) {
                    sl = entry - stopLevel;
                    tp = entry + stopLevel;
                } else {
                    sl = entry + stopLevel;
                    tp = entry - stopLevel;
                }
                ticket = OrderManager::PlaceOrderWithRetries(Symbol(), cmd, lot, entry, 3, sl, tp, "ManualOrder", 123456, clrViolet);
                string msg = "OrderSend error 130: Adjusted stops and retried. SL=" + DoubleToStr(sl,2) + ", TP=" + DoubleToStr(tp,2);
                Logger::LogEvent("ERROR", msg);
                if(!IsTesting()) Logger::ShowAlert(msg);
            }
        }
        if(ticket > 0) {
            Logger::LogEvent("USER", "Manual order placed: type=" + IntegerToString(orderType) + ", lot=" + DoubleToStr(lot,2) + ", entry=" + DoubleToStr(entry,2) + ", SL=" + DoubleToStr(sl,2) + ", TP=" + DoubleToStr(tp,2));
        } else {
            int err = GetLastError();
            if(err == 134) {
                Logger::LogEvent("ERROR", "OrderSend failed: Not enough money");
                if(!IsTesting()) Logger::ShowAlert("OrderSend failed: Not enough money");
            } else if(err == 135) {
                Logger::LogEvent("ERROR", "OrderSend failed: Not enough equity");
                if(!IsTesting()) Logger::ShowAlert("OrderSend failed: Not enough equity");
            } else {
                string msg = "OrderSend failed: Error code " + IntegerToString(err);
                Logger::LogEvent("ERROR", msg);
                if(!IsTesting()) Logger::ShowAlert(msg);
            }
        }
    }
};

#endif // __MANUALORDER_MQH__
