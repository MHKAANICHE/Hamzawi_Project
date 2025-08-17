    // Close order with retries and error handling
    static bool CloseWithRetries(int ticket, double lots, double price, int slippage, color arrow_color) {
        int retry146 = 0, retry136 = 0, retry138 = 0;
        int err = 0;
        bool result = false;
        do {
            result = OrderClose(ticket, lots, price, slippage, arrow_color);
            err = GetLastError();
            if(!result && err == 146) { // Trade context busy
                Sleep(500);
                retry146++;
            } else if(!result && (err == 136 || err == 138)) { // Off quotes or requote
                Sleep(500);
                retry136 += (err == 136) ? 1 : 0;
                retry138 += (err == 138) ? 1 : 0;
            } else {
                break;
            }
        } while(retry146 < 3 && retry136 < 3 && retry138 < 3);
        return result;
    }

    // Delete pending order with retries and error handling
    static bool DeleteWithRetries(int ticket) {
        int retry146 = 0, retry136 = 0, retry138 = 0;
        int err = 0;
        bool result = false;
        do {
            result = OrderDelete(ticket);
            err = GetLastError();
            if(!result && err == 146) { // Trade context busy
                Sleep(500);
                retry146++;
            } else if(!result && (err == 136 || err == 138)) { // Off quotes or requote
                Sleep(500);
                retry136 += (err == 136) ? 1 : 0;
                retry138 += (err == 138) ? 1 : 0;
            } else {
                break;
            }
        } while(retry146 < 3 && retry136 < 3 && retry138 < 3);
        return result;
    }
    // Order selection and property access helpers
    static bool Select(int index, int select, int pool) {
        return OrderSelect(index, select, pool);
    }
    static int Ticket() {
        return OrderTicket();
    }
    static int Type() {
        return OrderType();
    }
    static string Symbol() {
        return OrderSymbol();
    }
    static int MagicNumber() {
        return OrderMagicNumber();
    }
    static double OpenPrice() {
        return OrderOpenPrice();
    }
    static double StopLoss() {
        return OrderStopLoss();
    }
    static double TakeProfit() {
        return OrderTakeProfit();
    }
//+------------------------------------------------------------------+
//| OrderManager.mqh - Handles all order-related operations          |
//+------------------------------------------------------------------+
#ifndef __ORDERMANAGER_MQH__
#define __ORDERMANAGER_MQH__

class OrderManager {
public:
    // Place order with retries and error handling
    static int PlaceOrderWithRetries(string symbol, int cmd, double lot, double price, int slippage, double sl, double tp, string comment, int magic, color arrow_color) {
        int ticket = -1;
        int retry146 = 0, retry136 = 0, retry138 = 0;
        int err = 0;
        do {
            ticket = OrderSend(symbol, cmd, lot, price, slippage, sl, tp, comment, magic, 0, arrow_color);
            err = GetLastError();
            if(ticket < 0 && err == 146) { // Trade context busy
                Sleep(500);
                retry146++;
            } else if(ticket < 0 && (err == 136 || err == 138)) { // Off quotes or requote
                Sleep(500);
                price = (cmd == OP_BUY || cmd == OP_BUYSTOP) ? Ask : Bid;
                retry136 += (err == 136) ? 1 : 0;
                retry138 += (err == 138) ? 1 : 0;
            } else {
                break;
            }
        } while(retry146 < 3 && retry136 < 3 && retry138 < 3);
        return ticket;
    }

    // Modify order with retries and error handling
    static bool OrderModifyWithRetries(int ticket, double price, double stoploss, double takeprofit, datetime expiration, color arrow_color) {
        int retry146 = 0, retry136 = 0, retry138 = 0;
        int err = 0;
        bool result = false;
        do {
            result = OrderModify(ticket, price, stoploss, takeprofit, expiration, arrow_color);
            err = GetLastError();
            if(!result && err == 146) { // Trade context busy
                Sleep(500);
                retry146++;
            } else if(!result && (err == 136 || err == 138)) { // Off quotes or requote
                Sleep(500);
                retry136 += (err == 136) ? 1 : 0;
                retry138 += (err == 138) ? 1 : 0;
            } else {
                break;
            }
        } while(retry146 < 3 && retry136 < 3 && retry138 < 3);
        return result;
    }
};

#endif // __ORDERMANAGER_MQH__
