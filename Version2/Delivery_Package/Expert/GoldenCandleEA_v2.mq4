// --- Helper: Place order with retries and error handling ---
int PlaceOrderWithRetries(string symbol, int cmd, double lot, double price, int slippage, double sl, double tp, string comment, int magic, color arrow_color) {
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
//+------------------------------------------------------------------+
//| GoldenCandleEA_v2.mq4                                            |
//| Version 2 - DLL Integration Skeleton                             |
//+------------------------------------------------------------------+


struct ManualOrderParams
{
    int orderType;
    double lotSize;
    double entryPrice;
    double stopLoss;
    double takeProfit;
};


#import "GoldenCandleEA.dll"
void HandleUserAction(int action, ManualOrderParams &params);
void ShowSettingsDialog();
void ShowTradeMonitor();
void ShowAlert(string message);
int CheckGoldenCandle(double &highs[], double &lows[], int len, double minSize, double maxSize);
int CheckEMACross(double &prices[], int len);
void UpdateLotProgression(int result);
double GetNextLotSize();
void SendUserAlert(string message);
void ShowEADialog();
bool IsTradingPaused();
bool IsSkipLevel();
bool IsManualOrder();
bool IsAdjustMinSize();
bool IsIgnoreAlert();
void GetManualOrderParams(double &lot, double &entry, double &sl, double &tp);
double GetNewMinSize();
#import

#property strict

// --- Global lot progression level
int gLotLevel = 0;
// --- Global pause flag
bool gPauseTrading = false;
#define ACTION_NONE 0
#define ACTION_PAUSE 1
#define ACTION_SKIP_LEVEL 2
#define ACTION_MANUAL_ORDER 3
#define ACTION_ADJUST_MIN_SIZE 4
#define ACTION_IGNORE_ALERT 5

// Extern inputs
extern double LotSize = 0.01;
extern double MaxSpread = 20;
extern double Slippage = 3;
extern double GoldenCandleMinSize = 100;
extern double GoldenCandleMaxSize = 10000;
extern double SharpeRatioTarget = 1.5;
extern int MagicNumber = 123456;
extern double RiskPercent = 1.0;
extern int MaxOrders = 5;
extern string AlertSound = "alert.wav";


// Show the EA dialog only on user request (e.g., timer or hotkey)
datetime lastDialogTime = 0;

int start() {

    // Call global trailing stop logic
    TrailingStopLogic();
    static bool shown = false;
    if(!shown) { ShowSettingsDialog(); shown = true; }

    // --- Patch: GUI dialog timing ---
    // Show the EA dialog every 60 seconds (as an example; in production, use hotkey/menu/button)
    if(TimeCurrent() - lastDialogTime > 60) {
        ShowEADialog();
        lastDialogTime = TimeCurrent();
    }

    // Check for user actions from GUI with error handling, robust flag reset, and logging
    bool pauseErr = false, skipErr = false, manualErr = false, minErr = false, ignoreErr = false;
    int err = 0;
    // Pause
    if (IsTradingPaused()) {
        gPauseTrading = true;
        LogEvent("USER", "User paused trading via GUI");
    } else {
        if (gPauseTrading) LogEvent("USER", "User resumed trading via GUI");
        gPauseTrading = false;
    }
    // Skip Level
    if (IsSkipLevel()) {
        if (!IsStopped()) {
            SkipLevel();
            LogEvent("USER", "User skipped to next lot progression level via GUI");
        } else {
            skipErr = true;
        }
    }
    // Manual Order
    if (IsManualOrder()) {
        double lot = 0, entry = 0, sl = 0, tp = 0;
        bool gotParams = false;
        err = 0;
        gotParams = true;
        GetManualOrderParams(lot, entry, sl, tp);
        if (lot <= 0) {
            LogEvent("ERROR", "Manual order: invalid lot size from DLL");
            gotParams = false;
        }
        if (gotParams) {
            ManualOrderParams mop;
            mop.orderType = 0; // Market
            mop.lotSize = lot;
            mop.entryPrice = entry;
            mop.stopLoss = sl;
            mop.takeProfit = tp;
            LogEvent("USER", "User placed manual order via GUI: lot=" + DoubleToStr(lot,2) + ", entry=" + DoubleToStr(entry,2) + ", sl=" + DoubleToStr(sl,2) + ", tp=" + DoubleToStr(tp,2));
            PlaceManualOrder(mop);
        } else {
            manualErr = true;
        }
    }
    // Adjust Min Size
    if (IsAdjustMinSize()) {
        double newMin = GetNewMinSize();
        if (newMin > 0) {
            AdjustMinGoldenCandleSize(newMin);
            LogEvent("USER", "User adjusted min Golden Candle size via GUI: " + DoubleToStr(newMin,2));
        } else {
            minErr = true;
            LogEvent("ERROR", "AdjustMinSize: invalid value from DLL");
        }
    }
    // Ignore Alert
    if (IsIgnoreAlert()) {
        IgnoreCurrentAlert();
        LogEvent("USER", "User ignored alert via GUI");
    }
    // Log any errors
    if (pauseErr) LogEvent("ERROR", "Pause action failed");
    if (skipErr) LogEvent("ERROR", "Skip level action failed");
    if (manualErr) LogEvent("ERROR", "Manual order action failed");
    if (minErr) LogEvent("ERROR", "Adjust min size action failed");
    if (ignoreErr) LogEvent("ERROR", "Ignore alert action failed");

    if(gPauseTrading) {
        LogEvent("INFO", "Trading is paused by user.");
        // Still manage open trades (trailing stop, exit, etc.), but skip new entries
        for(int i=0; i<OrdersTotal(); ++i) {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
                if(OrderSymbol() == Symbol() && OrderMagicNumber() == 123456) {
                    double entry = OrderOpenPrice();
                    double sl = OrderStopLoss();
                    double price = (OrderType() == OP_BUY) ? Bid : Ask;
                    double ladderStep = GoldenCandleMinSize > 0 ? GoldenCandleMinSize : 100;
                    // Move SL to breakeven at 3rd ladder level (Buy)
                    if(OrderType() == OP_BUY && price >= entry + 3*ladderStep && sl < entry) {
                        bool mod = OrderModify(OrderTicket(), entry, entry, OrderTakeProfit(), 0, clrBlue);
                        if(mod) {
                            LogEvent("TRAIL", "Buy SL moved to breakeven (3rd level)");
                            ShowAlert("Buy SL moved to breakeven (3rd level)");
                        }
                    }
                    // Move SL to first ladder level at 6th ladder level (Buy)
                    if(OrderType() == OP_BUY && price >= entry + 6*ladderStep && sl < entry+ladderStep) {
                        bool mod = OrderModify(OrderTicket(), entry, entry+ladderStep, OrderTakeProfit(), 0, clrBlue);
                        if(mod) {
                            LogEvent("TRAIL", "Buy SL moved to first ladder level (6th level)");
                        //#import "GoldenCandleEA.dll"
                        }
                    }
                    // Move SL to breakeven at 3rd ladder level (Sell)
                    if(OrderType() == OP_SELL && price <= entry - 3*ladderStep && sl > entry) {
                        bool mod = OrderModify(OrderTicket(), entry, entry, OrderTakeProfit(), 0, clrRed);
                        if(mod) {
                            LogEvent("TRAIL", "Sell SL moved to breakeven (3rd level)");
                            ShowAlert("Sell SL moved to breakeven (3rd level)");
                        }
                    }
                    // Move SL to first ladder level at 6th ladder level (Sell)
                    if(OrderType() == OP_SELL && price <= entry - 6*ladderStep && sl > entry-ladderStep) {
                        bool mod = OrderModify(OrderTicket(), entry, entry-ladderStep, OrderTakeProfit(), 0, clrRed);
                        if(mod) {
                            LogEvent("TRAIL", "Sell SL moved to first ladder level (6th level)");
                            ShowAlert("Sell SL moved to first ladder level (6th level)");
                        }
                        //#import
                }
            }
        }
        return 0;
    }

    // Gather price data
    double highs[10], lows[10], closes[10];
    for(int i=0; i<10; ++i) {
        highs[i] = High[i];
        lows[i] = Low[i];
        closes[i] = Close[i];
    }

        // Only one trade at a time
        int totalOrders = OrdersTotal();
        int openEATrades = 0;
        for(int i=0; i<OrdersTotal(); ++i) {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
                if(OrderSymbol() == Symbol() && OrderMagicNumber() == 123456) openEATrades++;
            }
        }
        if(openEATrades > 0) {
            LogEvent("INFO", "Trade already open for this EA. Skipping new entry.");
            return 0;
        }

        // Check if market is closed
        if(MarketInfo(Symbol(), MODE_TRADEALLOWED) == 0) {
            LogEvent("ERROR", "Market is closed. No trading allowed.");
            ShowAlert("Market is closed. No trading allowed.");
            return 0;
        }

        // Check max spread
        double spread = (Ask - Bid) / MarketInfo(Symbol(), MODE_POINT);
        if(spread > MaxSpread) {
            LogEvent("ERROR", "Spread too high. Skipping trade.");
            ShowAlert("Spread too high. Skipping trade.");
            return 0;
        }

    // DLL: Golden Candle detection
    int gcIdx = CheckGoldenCandle(highs, lows, 10, GoldenCandleMinSize, GoldenCandleMaxSize);
    if(gcIdx >= 0) {
        ShowAlert("Golden Candle detected!");
        // DLL: Get lot size and R:R for this level
        double lot = GetNextLotSize();
            double minLot = MarketInfo(Symbol(), MODE_MINLOT);
            double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
            if(lot < minLot || lot > maxLot) {
                string msg = "Lot size " + DoubleToStr(lot,2) + " out of broker limits (min=" + DoubleToStr(minLot,2) + ", max=" + DoubleToStr(maxLot,2) + ")";
                LogEvent("ERROR", msg);
                ShowAlert(msg);
                return 0;
            }
            lot = NormalizeDouble(lot, 2);
            lot = NormalizeDouble(lot, 2);
            lot = NormalizeDouble(lot, 2);
            lot = NormalizeDouble(lot, 2);
        // ... Use lot size in order logic ...
        // DLL: Log event
        LogEvent("TRADE", "Golden Candle entry signal");
        int gcIdx = CheckGoldenCandle(highs, lows, 10, GoldenCandleMinSize, GoldenCandleMaxSize);
        if(gcIdx >= 0) {
            double gcSize = highs[gcIdx] - lows[gcIdx];
            if(gcSize < GoldenCandleMinSize || gcSize > GoldenCandleMaxSize) {
                LogEvent("INFO", "Golden Candle size out of bounds. Skipping trade.");
                return 0;
            }
            ShowAlert("Golden Candle detected!");
            double lot = GetNextLotSize();
            double entry = closes[gcIdx];
            double sl = entry - gcSize;
            int digits = MarketInfo(Symbol(), MODE_DIGITS);
            double tp = NormalizeDouble(entry + 2*gcSize, digits);
            sl = NormalizeDouble(sl, digits);
            RemoveLadderLines();
            DrawLadderLines(entry, gcSize, true);
            DrawLadderLabels(entry, gcSize, true);
            DrawEntrySLLines(entry, sl);
            int ticket = PlaceOrderWithRetries(Symbol(), OP_BUY, lot, Ask, 3, sl, tp, "GoldenCandle", 123456, clrGreen);
            if(ticket < 0 && GetLastError() == 130) {
                // Adjust stops and retry once
                sl = Ask - MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(Symbol(), MODE_POINT);
                tp = Ask + MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(Symbol(), MODE_POINT);
                ticket = PlaceOrderWithRetries(Symbol(), OP_BUY, lot, Ask, 3, sl, tp, "GoldenCandle", 123456, clrGreen);
                string msg = "OrderSend error 130: Adjusted stops and retried. SL=" + DoubleToStr(sl,2) + ", TP=" + DoubleToStr(tp,2);
                LogEvent("ERROR", msg);
                ShowAlert(msg);
            }
            if(ticket > 0) {
                LogEvent("TRADE", "Buy order placed by Golden Candle");
            } else {
                int err = GetLastError();
                if(err == 134) {
                    LogEvent("ERROR", "OrderSend failed: Not enough money");
                    ShowAlert("OrderSend failed: Not enough money");
                } else if(err == 135) {
                    LogEvent("ERROR", "OrderSend failed: Not enough equity");
                    ShowAlert("OrderSend failed: Not enough equity");
                } else {
                    string msg = "OrderSend failed: Error code " + IntegerToString(err);
                    LogEvent("ERROR", msg);
                    ShowAlert(msg);
                }
            }
        }

        // --- Golden Candle Sell Entry (mirror logic for sell) ---
        int gcSellIdx = CheckGoldenCandle(highs, lows, 10, GoldenCandleMinSize, GoldenCandleMaxSize); // Placeholder: replace with sell detection logic if available
        if(gcSellIdx >= 0) {
            double gcSize = highs[gcSellIdx] - lows[gcSellIdx];
            if(gcSize < GoldenCandleMinSize || gcSize > GoldenCandleMaxSize) {
                LogEvent("INFO", "Golden Candle size out of bounds. Skipping sell trade.");
                return 0;
            }
            ShowAlert("Golden Candle sell detected!");
            double lot = GetNextLotSize();
            double entry = closes[gcSellIdx];
            double sl = entry + gcSize;
            int digits = MarketInfo(Symbol(), MODE_DIGITS);
            double tp = NormalizeDouble(entry - 2*gcSize, digits);
            sl = NormalizeDouble(sl, digits);
            RemoveLadderLines();
            DrawLadderLines(entry, gcSize, false);
            DrawLadderLabels(entry, gcSize, false);
            DrawEntrySLLines(entry, sl);
            int ticket = PlaceOrderWithRetries(Symbol(), OP_SELL, lot, Bid, 3, sl, tp, "GoldenCandleSell", 123456, clrRed);
            if(ticket < 0 && GetLastError() == 130) {
                // Adjust stops and retry once
                sl = Bid + MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(Symbol(), MODE_POINT);
                tp = Bid - MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(Symbol(), MODE_POINT);
                ticket = PlaceOrderWithRetries(Symbol(), OP_SELL, lot, Bid, 3, sl, tp, "GoldenCandleSell", 123456, clrRed);
                string msg = "OrderSend error 130: Adjusted stops and retried. SL=" + DoubleToStr(sl,2) + ", TP=" + DoubleToStr(tp,2);
                LogEvent("ERROR", msg);
                ShowAlert(msg);
            }
            if(ticket > 0) {
                LogEvent("TRADE", "Sell order placed by Golden Candle");
            } else {
                int err = GetLastError();
                if(err == 134) {
                    LogEvent("ERROR", "OrderSend failed: Not enough money");
                    ShowAlert("OrderSend failed: Not enough money");
                } else if(err == 135) {
                    LogEvent("ERROR", "OrderSend failed: Not enough equity");
                    ShowAlert("OrderSend failed: Not enough equity");
                } else {
                    string msg = "OrderSend failed: Error code " + IntegerToString(err);
                    LogEvent("ERROR", msg);
                    ShowAlert(msg);
                }
            }
        }

        // --- EMA Cross Buy Entry ---
        int emaCrossBuy = CheckEMACross(closes, 10);
        if(emaCrossBuy == 1) { // Bullish cross
            double lot = GetNextLotSize();
            double entry = Ask;
            double step = GoldenCandleMinSize > 0 ? GoldenCandleMinSize : 100;
            double sl = entry - step;
            int digits = MarketInfo(Symbol(), MODE_DIGITS);
            double tp = NormalizeDouble(entry + 2*step, digits);
            sl = NormalizeDouble(sl, digits);
            RemoveLadderLines();
            DrawLadderLines(entry, step, true);
            DrawLadderLabels(entry, step, true);
            DrawEntrySLLines(entry, sl);
            int ticket = PlaceOrderWithRetries(Symbol(), OP_BUY, lot, Ask, 3, sl, tp, "EMACrossBuy", 123456, clrBlue);
            if(ticket < 0 && GetLastError() == 130) {
                // Adjust stops and retry once
                sl = Ask - MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(Symbol(), MODE_POINT);
                tp = Ask + MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(Symbol(), MODE_POINT);
                ticket = PlaceOrderWithRetries(Symbol(), OP_BUY, lot, Ask, 3, sl, tp, "EMACrossBuy", 123456, clrBlue);
                string msg = "OrderSend error 130: Adjusted stops and retried. SL=" + DoubleToStr(sl,2) + ", TP=" + DoubleToStr(tp,2);
                LogEvent("ERROR", msg);
                ShowAlert(msg);
            }
            if(ticket > 0) {
                LogEvent("TRADE", "Buy order placed by EMA cross");
            } else {
                int err = GetLastError();
                if(err == 134) {
                    LogEvent("ERROR", "OrderSend failed: Not enough money");
                    ShowAlert("OrderSend failed: Not enough money");
                } else if(err == 135) {
                    LogEvent("ERROR", "OrderSend failed: Not enough equity");
                    ShowAlert("OrderSend failed: Not enough equity");
                } else {
                    string msg = "OrderSend failed: Error code " + IntegerToString(err);
                    LogEvent("ERROR", msg);
                    ShowAlert(msg);
                }
            }
        }

        // --- EMA Cross Sell Entry ---
        int emaCrossSell = CheckEMACross(closes, 10);
        if(emaCrossSell == -1) { // Bearish cross
            double lot = GetNextLotSize();
            double entry = Bid;
            double step = GoldenCandleMinSize > 0 ? GoldenCandleMinSize : 100;
            double sl = entry + step;
            int digits = MarketInfo(Symbol(), MODE_DIGITS);
            double tp = NormalizeDouble(entry - 2*step, digits);
            sl = NormalizeDouble(sl, digits);
            RemoveLadderLines();
            DrawLadderLines(entry, step, false);
            DrawLadderLabels(entry, step, false);
            DrawEntrySLLines(entry, sl);
            int ticket = PlaceOrderWithRetries(Symbol(), OP_SELL, lot, Bid, 3, sl, tp, "EMACrossSell", 123456, clrMagenta);
            if(ticket < 0 && GetLastError() == 130) {
                // Adjust stops and retry once
                sl = Bid + MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(Symbol(), MODE_POINT);
                tp = Bid - MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(Symbol(), MODE_POINT);
                ticket = PlaceOrderWithRetries(Symbol(), OP_SELL, lot, Bid, 3, sl, tp, "EMACrossSell", 123456, clrMagenta);
                string msg = "OrderSend error 130: Adjusted stops and retried. SL=" + DoubleToStr(sl,2) + ", TP=" + DoubleToStr(tp,2);
                LogEvent("ERROR", msg);
                ShowAlert(msg);
            }
            if(ticket > 0) {
                LogEvent("TRADE", "Sell order placed by EMA cross");
            } else {
                int err = GetLastError();
                if(err == 134) {
                    LogEvent("ERROR", "OrderSend failed: Not enough money");
                    ShowAlert("OrderSend failed: Not enough money");
                } else if(err == 135) {
                    LogEvent("ERROR", "OrderSend failed: Not enough equity");
                    ShowAlert("OrderSend failed: Not enough equity");
                } else {
                    string msg = "OrderSend failed: Error code " + IntegerToString(err);
                    LogEvent("ERROR", msg);
                    ShowAlert(msg);
                }
            }
        }
    }
    }
    //HandleUserAction(ACTION_PAUSE, 0);

    // Skip level
    //HandleUserAction(ACTION_SKIP_LEVEL, 0);

    // Manual order (example)
    //ManualOrderParams mop = {0, 0.01, Ask, Ask-100, Ask+200};
    //PlaceManualOrder(mop);

    // Adjust min size
    //AdjustMinGoldenCandleSize(150); // Example: set new min size to 150

    // Ignore alert
    //IgnoreCurrentAlert();

    // --- Ignore alert logic (stub, uncomment to test) ---
    //LogEvent("USER", "User chose to ignore alert");
    //ShowAlert("User chose to ignore alert");

    // DLL: Log all events and errors
    // LogEvent("INFO", "EA tick complete");
   
    return 0;
}

// --- Logging stub ---
void LogEvent(string category, string message) {
    Print("[", category, "] ", message);
}


// --- User action: ignore alert ---
void IgnoreCurrentAlert() {
    LogEvent("USER", "User chose to ignore the current alert/signal.");
    ShowAlert("Current alert/signal ignored by user.");
}
// --- User action: adjust minimum Golden Candle size ---
void AdjustMinGoldenCandleSize(double newMinSize) {
    GoldenCandleMinSize = newMinSize;
    string msg = "Minimum Golden Candle size adjusted to " + DoubleToStr(newMinSize, 2);
    LogEvent("USER", msg);
    ShowAlert(msg);
}
// --- User action: manual order ---
void PlaceManualOrder(ManualOrderParams &mop) {
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
        LogEvent("ERROR", msg);
        ShowAlert(msg);
        return;
    }
    int ticket = -1;
    if(orderType == 0) { // Market order
        int cmd = (entry >= Ask) ? OP_BUY : OP_SELL;
        double price = (cmd == OP_BUY) ? Ask : Bid;
        ticket = PlaceOrderWithRetries(Symbol(), cmd, lot, price, 3, sl, tp, "ManualOrder", 123456, clrViolet);
        if(ticket < 0 && GetLastError() == 130) {
            // Adjust stops and retry once
            if(cmd == OP_BUY) {
                sl = price - stopLevel;
                tp = price + stopLevel;
            } else {
                sl = price + stopLevel;
                tp = price - stopLevel;
            }
            ticket = PlaceOrderWithRetries(Symbol(), cmd, lot, price, 3, sl, tp, "ManualOrder", 123456, clrViolet);
            string msg = "OrderSend error 130: Adjusted stops and retried. SL=" + DoubleToStr(sl,2) + ", TP=" + DoubleToStr(tp,2);
            LogEvent("ERROR", msg);
            ShowAlert(msg);
        }
    } else if(orderType == 1) { // Pending order
        int cmd = (entry >= Ask) ? OP_BUYSTOP : OP_SELLSTOP;
        ticket = PlaceOrderWithRetries(Symbol(), cmd, lot, entry, 3, sl, tp, "ManualOrder", 123456, clrViolet);
        if(ticket < 0 && GetLastError() == 130) {
            // Adjust stops and retry once
            if(cmd == OP_BUYSTOP) {
                sl = entry - stopLevel;
                tp = entry + stopLevel;
            } else {
                sl = entry + stopLevel;
                tp = entry - stopLevel;
            }
            ticket = PlaceOrderWithRetries(Symbol(), cmd, lot, entry, 3, sl, tp, "ManualOrder", 123456, clrViolet);
            string msg = "OrderSend error 130: Adjusted stops and retried. SL=" + DoubleToStr(sl,2) + ", TP=" + DoubleToStr(tp,2);
            LogEvent("ERROR", msg);
            ShowAlert(msg);
        }
    }
    if(ticket > 0) {
        LogEvent("USER", "Manual order placed: type=" + IntegerToString(orderType) + ", lot=" + DoubleToStr(lot,2) + ", entry=" + DoubleToStr(entry,2) + ", SL=" + DoubleToStr(sl,2) + ", TP=" + DoubleToStr(tp,2));
    } else {
        int err = GetLastError();
        if(err == 134) {
            LogEvent("ERROR", "OrderSend failed: Not enough money");
            ShowAlert("OrderSend failed: Not enough money");
        } else if(err == 135) {
            LogEvent("ERROR", "OrderSend failed: Not enough equity");
            ShowAlert("OrderSend failed: Not enough equity");
        } else {
            string msg = "OrderSend failed: Error code " + IntegerToString(err);
            LogEvent("ERROR", msg);
            ShowAlert(msg);
        }
    }
}
// --- User action: skip level ---
void SkipLevel() {
    gLotLevel++;
    LogEvent("USER", "User skipped to next lot progression level: " + IntegerToString(gLotLevel));
}
// --- Ladder label helpers ---
void RemoveLadderLabels() {
    for(int i=1; i<=7; ++i) {
        string label = "LadderLabel_" + IntegerToString(i);
        if(ObjectFind(0, label) >= 0) ObjectDelete(0, label);
    }
}

void DrawLadderLabels(double entry, double step, bool isBuy) {
    RemoveLadderLabels();
    for(int i=1; i<=7; ++i) {
        double price = isBuy ? entry + i*step : entry - i*step;
        string label = "LadderLabel_" + IntegerToString(i);
        ObjectCreate(0, label, OBJ_TEXT, 0, Time[0], price);
        ObjectSetText(label, IntegerToString(i), 10, "Arial", clrBlue);
    }
}
// --- Entry & SL line helpers ---
void RemoveEntrySLLines() {
    string names[2] = {"EntryLine", "SLLine"};
    for(int i=0; i<2; ++i) {
        if(ObjectFind(0, names[i]) >= 0) ObjectDelete(0, names[i]);
        string label = names[i] + "_Label";
        if(ObjectFind(0, label) >= 0) ObjectDelete(0, label);
    }
}

void DrawEntrySLLines(double entry, double sl) {
    RemoveEntrySLLines();
    ObjectCreate(0, "EntryLine", OBJ_HLINE, 0, 0, entry);
    ObjectSetInteger(0, "EntryLine", OBJPROP_COLOR, clrGreen);
    ObjectSetInteger(0, "EntryLine", OBJPROP_WIDTH, 2);
    ObjectCreate(0, "EntryLine_Label", OBJ_TEXT, 0, Time[0], entry);
    ObjectSetText("EntryLine_Label", "Entry", 10, "Arial", clrGreen);
    ObjectCreate(0, "SLLine", OBJ_HLINE, 0, 0, sl);
    ObjectSetInteger(0, "SLLine", OBJPROP_COLOR, clrRed);
    ObjectSetInteger(0, "SLLine", OBJPROP_WIDTH, 2);
    ObjectCreate(0, "SLLine_Label", OBJ_TEXT, 0, Time[0], sl);
    ObjectSetText("SLLine_Label", "SL", 10, "Arial", clrRed);
}
// --- Ladder line helpers ---
void RemoveLadderLines() {
    for(int i=0; i<=7; ++i) {
        string name = "Ladder_" + IntegerToString(i);
        if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
    }
}

void DrawLadderLines(double entry, double step, bool isBuy) {
    color ladderColor = isBuy ? clrBlue : clrRed;
    for(int i=0; i<=7; ++i) {
        string name = "Ladder_" + IntegerToString(i);
        double price = isBuy ? entry + i*step : entry - i*step;
        ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
        ObjectSetInteger(0, name, OBJPROP_COLOR, ladderColor);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, i==0 ? 2 : 1);
    }
}

// --- Trailing stop logic (basic, for open trades) ---
void TrailingStopLogic() {
    for(int i=0; i<OrdersTotal(); ++i) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == 123456) {
                double entry = OrderOpenPrice();
                double sl = OrderStopLoss();
                double price = (OrderType() == OP_BUY) ? Bid : Ask;
                double ladderStep = GoldenCandleMinSize > 0 ? GoldenCandleMinSize : 100;
                // Move SL to breakeven at 3rd ladder level (Buy)
                if(OrderType() == OP_BUY && price >= entry + 3*ladderStep && sl < entry) {
                    bool mod = OrderModify(OrderTicket(), entry, entry, OrderTakeProfit(), 0, clrBlue);
                    if(mod) {
                        LogEvent("TRAIL", "Buy SL moved to breakeven (3rd level)");
                        ShowAlert("Buy SL moved to breakeven (3rd level)");
                    }
                }
                // Move SL to first ladder level at 6th ladder level (Buy)
                if(OrderType() == OP_BUY && price >= entry + 6*ladderStep && sl < entry+ladderStep) {
                    bool mod = OrderModify(OrderTicket(), entry, entry+ladderStep, OrderTakeProfit(), 0, clrBlue);
                    if(mod) {
                        LogEvent("TRAIL", "Buy SL moved to first ladder level (6th level)");
                        ShowAlert("Buy SL moved to first ladder level (6th level)");
                    }
                }
                // Move SL to breakeven at 3rd ladder level (Sell)
                if(OrderType() == OP_SELL && price <= entry - 3*ladderStep && sl > entry) {
                    bool mod = OrderModify(OrderTicket(), entry, entry, OrderTakeProfit(), 0, clrRed);
                    if(mod) {
                        LogEvent("TRAIL", "Sell SL moved to breakeven (3rd level)");
                        ShowAlert("Sell SL moved to breakeven (3rd level)");
                    }
                }
                // Move SL to first ladder level at 6th ladder level (Sell)
                if(OrderType() == OP_SELL && price <= entry - 6*ladderStep && sl > entry-ladderStep) {
                    bool mod = OrderModify(OrderTicket(), entry, entry-ladderStep, OrderTakeProfit(), 0, clrRed);
                    if(mod) {
                        LogEvent("TRAIL", "Sell SL moved to first ladder level (6th level)");
                        ShowAlert("Sell SL moved to first ladder level (6th level)");
                    }
                }
            }
        }
    }
}