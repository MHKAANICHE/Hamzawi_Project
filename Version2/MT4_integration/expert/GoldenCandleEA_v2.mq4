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


#import "GoldenCandleEA_GUI.dll"
void HandleUserAction(int action, ManualOrderParams &params);
void ShowSettingsDialog();
void ShowTradeMonitor();
// ...existing code...
int CheckGoldenCandle(double &highs[], double &lows[], int len, double minSize, double maxSize);
int CheckEMACross(double &prices[], int len);
void UpdateLotProgression(int result);
double GetNextLotSize();
// ...existing code...
void ShowEADialog();
bool IsTradingPaused();
bool IsSkipLevel();
bool IsManualOrder();
bool IsAdjustMinSize();
bool IsIgnoreAlert();
void GetManualOrderParams(double &lot, double &entry, double &sl, double &tp);
double GetNewMinSize();
#import

// --- TrailingStop include ---
#include "TrailingStop.mqh"
// --- ChartUtils include ---
#include "ChartUtils.mqh"
// --- ManualOrder include ---
#include "ManualOrder.mqh"
// --- UserActions include ---
#include "UserActions.mqh"
// --- MoneyManager include ---
#include "MoneyManager.mqh"
// --- SignalGenerator include ---
#include "SignalGenerator.mqh"
// --- Logger include ---
#include "Logger.mqh"
// --- OrderManager include ---
#include "OrderManager.mqh"


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
    TrailingStop::TrailingStopLogic(GoldenCandleMinSize);
    static bool shown = false;
    if(!shown && !IsTesting()) { ShowSettingsDialog(); shown = true; }

    // --- Patch: GUI dialog timing ---
    // Show the EA dialog every 60 seconds (as an example; in production, use hotkey/menu/button)
    if(TimeCurrent() - lastDialogTime > 60 && !IsTesting()) {
        ShowEADialog();
        lastDialogTime = TimeCurrent();
    }

    // Check for user actions from GUI with error handling, robust flag reset, and logging
    bool pauseErr = false, skipErr = false, manualErr = false, minErr = false, ignoreErr = false;
    int err = 0;
    // Pause
    if ( !IsTesting() && IsTradingPaused()) {
        gPauseTrading = true;
    Logger::LogEvent("USER", "User paused trading via GUI");
    } else {
    if (gPauseTrading) Logger::LogEvent("USER", "User resumed trading via GUI");
        gPauseTrading = false;
    }
    // Skip Level
    if (!IsTesting() && IsSkipLevel()) {
        if (!IsStopped()) {
            UserActions::SkipLevel(gLotLevel);
            Logger::LogEvent("USER", "User skipped to next lot progression level via GUI");
        } else {
            skipErr = true;
        }
    }
    // Manual Order
    if (!IsTesting() && IsManualOrder()) {
        double lot = 0, entry = 0, sl = 0, tp = 0;
        bool gotParams = false;
        err = 0;
        gotParams = true;
        GetManualOrderParams(lot, entry, sl, tp);
        if (lot <= 0) {
            Logger::LogEvent("ERROR", "Manual order: invalid lot size from DLL");
            gotParams = false;
        }
        if (gotParams) {
            ManualOrderParams mop;
            mop.orderType = 0; // Market
            mop.lotSize = lot;
            mop.entryPrice = entry;
            mop.stopLoss = sl;
            mop.takeProfit = tp;
            Logger::LogEvent("USER", "User placed manual order via GUI: lot=" + DoubleToStr(lot,2) + ", entry=" + DoubleToStr(entry,2) + ", sl=" + DoubleToStr(sl,2) + ", tp=" + DoubleToStr(tp,2));
            ManualOrder::PlaceManualOrder(mop);
        } else {
            manualErr = true;
        }
    }
    // Adjust Min Size 
    if (!IsTesting() && IsAdjustMinSize()) {
        double newMin = GetNewMinSize();
        if (newMin > 0) {
            UserActions::AdjustMinGoldenCandleSize(GoldenCandleMinSize, newMin);
            Logger::LogEvent("USER", "User adjusted min Golden Candle size via GUI: " + DoubleToStr(newMin,2));
        } else {
            minErr = true;
            Logger::LogEvent("ERROR", "AdjustMinSize: invalid value from DLL");
        }
    }
    // Ignore Alert
    if (!IsTesting() && IsIgnoreAlert()) {
        UserActions::IgnoreCurrentAlert();
        Logger::LogEvent("USER", "User ignored alert via GUI");
    }
    // Log any errors
    if (pauseErr) Logger::LogEvent("ERROR", "Pause action failed");
    if (skipErr) Logger::LogEvent("ERROR", "Skip level action failed");
    if (manualErr) Logger::LogEvent("ERROR", "Manual order action failed");
    if (minErr) LogEvent("ERROR", "Adjust min size action failed");
    if (ignoreErr) LogEvent("ERROR", "Ignore alert action failed");

    if(!IsTesting() && gPauseTrading) {
        LogEvent("INFO", "Trading is paused by user.");
        // Still manage open trades (trailing stop, exit, etc.), but skip new entries
        for(int i=0; i<OrdersTotal(); ++i) {
            if(OrderManager::Select(i, SELECT_BY_POS, MODE_TRADES)) {
                if(OrderManager::Symbol() == Symbol() && OrderManager::MagicNumber() == 123456) {
                    double entry = OrderManager::OpenPrice();
                    double sl = OrderManager::StopLoss();
                    double price = (OrderManager::Type() == OP_BUY) ? Bid : Ask;
                    double ladderStep = GoldenCandleMinSize > 0 ? GoldenCandleMinSize : 100;
                    // Move SL to breakeven at 3rd ladder level (Buy)
                    if(OrderManager::Type() == OP_BUY && price >= entry + 3*ladderStep && sl < entry) {
                        bool mod = OrderManager::OrderModifyWithRetries(OrderManager::Ticket(), entry, entry, OrderManager::TakeProfit(), 0, clrBlue);
                        if(mod) {
                            LogEvent("TRAIL", "Buy SL moved to breakeven (3rd level)");
                            Logger::ShowAlert("Buy SL moved to breakeven (3rd level)");
                        }
                    }
                    // Move SL to first ladder level at 6th ladder level (Buy)
                    if(OrderManager::Type() == OP_BUY && price >= entry + 6*ladderStep && sl < entry+ladderStep) {
                        bool mod = OrderManager::OrderModifyWithRetries(OrderManager::Ticket(), entry, entry+ladderStep, OrderManager::TakeProfit(), 0, clrBlue);
                        if(mod) {
                            LogEvent("TRAIL", "Buy SL moved to first ladder level (6th level)");
                        //#import "GoldenCandleEA.dll"
                        }
                    }
                    // Move SL to breakeven at 3rd ladder level (Sell)
                    if(OrderManager::Type() == OP_SELL && price <= entry - 3*ladderStep && sl > entry) {
                        bool mod = OrderManager::OrderModifyWithRetries(OrderManager::Ticket(), entry, entry, OrderManager::TakeProfit(), 0, clrRed);
                        if(mod) {
                            LogEvent("TRAIL", "Sell SL moved to breakeven (3rd level)");
                            Logger::ShowAlert("Sell SL moved to breakeven (3rd level)");
                        }
                    }
                    // Move SL to first ladder level at 6th ladder level (Sell)
                    if(OrderManager::Type() == OP_SELL && price <= entry - 6*ladderStep && sl > entry-ladderStep) {
                        bool mod = OrderManager::OrderModifyWithRetries(OrderManager::Ticket(), entry, entry-ladderStep, OrderManager::TakeProfit(), 0, clrRed);
                        if(mod) {
                            LogEvent("TRAIL", "Sell SL moved to first ladder level (6th level)");
                            Logger::ShowAlert("Sell SL moved to first ladder level (6th level)");
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
            if(OrderManager::Select(i, SELECT_BY_POS, MODE_TRADES)) {
                if(OrderManager::Symbol() == Symbol() && OrderManager::MagicNumber() == 123456) openEATrades++;
            }
        }
        if(openEATrades > 0) {
            LogEvent("INFO", "Trade already open for this EA. Skipping new entry.");
            return 0;
        }

        // Check if market is closed
        if(MarketInfo(Symbol(), MODE_TRADEALLOWED) == 0) {
            LogEvent("ERROR", "Market is closed. No trading allowed.");
            if(!IsTesting()) Logger::ShowAlert("Market is closed. No trading allowed.");
            return 0;
        }

        // Check max spread
        double spread = (Ask - Bid) / MarketInfo(Symbol(), MODE_POINT);
        if(spread > MaxSpread) {
            LogEvent("ERROR", "Spread too high. Skipping trade.");
            if(!IsTesting()) Logger::ShowAlert("Spread too high. Skipping trade.");
            return 0;
        }

    // DLL: Golden Candle detection
    int gcIdx = SignalGenerator::CheckGoldenCandle(highs, lows, 10, GoldenCandleMinSize, GoldenCandleMaxSize);
    if(gcIdx >= 0) {
    if(!IsTesting()) Logger::ShowAlert("Golden Candle detected!");
        // DLL: Get lot size and R:R for this level
    double lot = MoneyManager::GetNextLotSize();
            double minLot = MarketInfo(Symbol(), MODE_MINLOT);
            double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
            if(lot < minLot || lot > maxLot) {
                string msg = "Lot size " + DoubleToStr(lot,2) + " out of broker limits (min=" + DoubleToStr(minLot,2) + ", max=" + DoubleToStr(maxLot,2) + ")";
                LogEvent("ERROR", msg);
                if(!IsTesting()) Logger::ShowAlert(msg);
                return 0;
            }
            lot = NormalizeDouble(lot, 2);
            lot = NormalizeDouble(lot, 2);
            lot = NormalizeDouble(lot, 2);
            lot = NormalizeDouble(lot, 2);
        // ... Use lot size in order logic ...
        // DLL: Log event
        Logger::LogEvent("TRADE", "Golden Candle entry signal");
        int gcIdx = SignalGenerator::CheckGoldenCandle(highs, lows, 10, GoldenCandleMinSize, GoldenCandleMaxSize);
        if(gcIdx >= 0) {
            double gcSize = highs[gcIdx] - lows[gcIdx];
            if(gcSize < GoldenCandleMinSize || gcSize > GoldenCandleMaxSize) {
                Logger::LogEvent("INFO", "Golden Candle size out of bounds. Skipping trade.");
                return 0;
            }
            if(!IsTesting()) Logger::ShowAlert("Golden Candle detected!");
            double lot = MoneyManager::GetNextLotSize();
            double entry = closes[gcIdx];
            double sl = entry - gcSize;
            int digits = MarketInfo(Symbol(), MODE_DIGITS);
            double tp = NormalizeDouble(entry + 2*gcSize, digits);
            sl = NormalizeDouble(sl, digits);
            ChartUtils::RemoveLadderLines();
            ChartUtils::DrawLadderLines(entry, gcSize, true);
            ChartUtils::DrawLadderLabels(entry, gcSize, true);
            ChartUtils::DrawEntrySLLines(entry, sl);
            int ticket = OrderManager::PlaceOrderWithRetries(Symbol(), OP_BUY, lot, Ask, 3, sl, tp, "GoldenCandle", 123456, clrGreen);
            if(ticket < 0 && GetLastError() == 130) {
                // Adjust stops and retry once
                sl = Ask - MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(Symbol(), MODE_POINT);
                tp = Ask + MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(Symbol(), MODE_POINT);
                ticket = OrderManager::PlaceOrderWithRetries(Symbol(), OP_BUY, lot, Ask, 3, sl, tp, "GoldenCandle", 123456, clrGreen);
                string msg = "OrderSend error 130: Adjusted stops and retried. SL=" + DoubleToStr(sl,2) + ", TP=" + DoubleToStr(tp,2);
                Logger::LogEvent("ERROR", msg);
                if(!IsTesting()) Logger::ShowAlert(msg);
            }
            if(ticket > 0) {
                Logger::LogEvent("TRADE", "Buy order placed by Golden Candle");
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

        // --- Golden Candle Sell Entry (mirror logic for sell) ---
        int gcSellIdx = SignalGenerator::CheckGoldenCandle(highs, lows, 10, GoldenCandleMinSize, GoldenCandleMaxSize); // Placeholder: replace with sell detection logic if available
        if(gcSellIdx >= 0) {
            double gcSize = highs[gcSellIdx] - lows[gcSellIdx];
            if(gcSize < GoldenCandleMinSize || gcSize > GoldenCandleMaxSize) {
                Logger::LogEvent("INFO", "Golden Candle size out of bounds. Skipping sell trade.");
                return 0;
            }
            if(!IsTesting()) Logger::ShowAlert("Golden Candle sell detected!");
            double lot = MoneyManager::GetNextLotSize();
            double entry = closes[gcSellIdx];
            double sl = entry + gcSize;
            int digits = MarketInfo(Symbol(), MODE_DIGITS);
            double tp = NormalizeDouble(entry - 2*gcSize, digits);
            sl = NormalizeDouble(sl, digits);
            ChartUtils::RemoveLadderLines();
            ChartUtils::DrawLadderLines(entry, gcSize, false);
            ChartUtils::DrawLadderLabels(entry, gcSize, false);
            ChartUtils::DrawEntrySLLines(entry, sl);
            int ticket = OrderManager::PlaceOrderWithRetries(Symbol(), OP_SELL, lot, Bid, 3, sl, tp, "GoldenCandleSell", 123456, clrRed);
            if(ticket < 0 && GetLastError() == 130) {
                // Adjust stops and retry once
                sl = Bid + MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(Symbol(), MODE_POINT);
                tp = Bid - MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(Symbol(), MODE_POINT);
                ticket = OrderManager::PlaceOrderWithRetries(Symbol(), OP_SELL, lot, Bid, 3, sl, tp, "GoldenCandleSell", 123456, clrRed);
                string msg = "OrderSend error 130: Adjusted stops and retried. SL=" + DoubleToStr(sl,2) + ", TP=" + DoubleToStr(tp,2);
                Logger::LogEvent("ERROR", msg);
                if(!IsTesting()) Logger::ShowAlert(msg);
            }
            if(ticket > 0) {
                Logger::LogEvent("TRADE", "Sell order placed by Golden Candle");
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

        // --- EMA Cross Buy Entry ---
    int emaCrossBuy = SignalGenerator::CheckEMACross(closes, 10);
    if(emaCrossBuy == 1) { // Bullish cross
        double lot = MoneyManager::GetNextLotSize();
        double entry = Ask;
        double step = GoldenCandleMinSize > 0 ? GoldenCandleMinSize : 100;
        double sl = entry - step;
        int digits = MarketInfo(Symbol(), MODE_DIGITS);
        double tp = NormalizeDouble(entry + 2*step, digits);
        sl = NormalizeDouble(sl, digits);
        ChartUtils::RemoveLadderLines();
        ChartUtils::DrawLadderLines(entry, step, true);
        ChartUtils::DrawLadderLabels(entry, step, true);
        ChartUtils::DrawEntrySLLines(entry, sl);
        int ticket = OrderManager::PlaceOrderWithRetries(Symbol(), OP_BUY, lot, Ask, 3, sl, tp, "EMACrossBuy", 123456, clrBlue);
        if(ticket < 0 && GetLastError() == 130) {
            // Adjust stops and retry once
            sl = Ask - MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(Symbol(), MODE_POINT);
            tp = Ask + MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(Symbol(), MODE_POINT);
            ticket = OrderManager::PlaceOrderWithRetries(Symbol(), OP_BUY, lot, Ask, 3, sl, tp, "EMACrossBuy", 123456, clrBlue);
            string msg = "OrderSend error 130: Adjusted stops and retried. SL=" + DoubleToStr(sl,2) + ", TP=" + DoubleToStr(tp,2);
            Logger::LogEvent("ERROR", msg);
            if(!IsTesting()) Logger::ShowAlert(msg);
        }
        if(ticket > 0) {
            Logger::LogEvent("TRADE", "Buy order placed by EMA cross");
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

        // --- EMA Cross Sell Entry ---
    int emaCrossSell = SignalGenerator::CheckEMACross(closes, 10);
    if(emaCrossSell == -1) { // Bearish cross
        double lot = MoneyManager::GetNextLotSize();
        double entry = Bid;
        double step = GoldenCandleMinSize > 0 ? GoldenCandleMinSize : 100;
        double sl = entry + step;
        int digits = MarketInfo(Symbol(), MODE_DIGITS);
        double tp = NormalizeDouble(entry - 2*step, digits);
        sl = NormalizeDouble(sl, digits);
        ChartUtils::RemoveLadderLines();
        ChartUtils::DrawLadderLines(entry, step, false);
        ChartUtils::DrawLadderLabels(entry, step, false);
        ChartUtils::DrawEntrySLLines(entry, sl);
        int ticket = OrderManager::PlaceOrderWithRetries(Symbol(), OP_SELL, lot, Bid, 3, sl, tp, "EMACrossSell", 123456, clrMagenta);
        if(ticket < 0 && GetLastError() == 130) {
            // Adjust stops and retry once
            sl = Bid + MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(Symbol(), MODE_POINT);
            tp = Bid - MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(Symbol(), MODE_POINT);
            ticket = OrderManager::PlaceOrderWithRetries(Symbol(), OP_SELL, lot, Bid, 3, sl, tp, "EMACrossSell", 123456, clrMagenta);
            string msg = "OrderSend error 130: Adjusted stops and retried. SL=" + DoubleToStr(sl,2) + ", TP=" + DoubleToStr(tp,2);
            Logger::LogEvent("ERROR", msg);
            if(!IsTesting()) Logger::ShowAlert(msg);
        }
        if(ticket > 0) {
            Logger::LogEvent("TRADE", "Sell order placed by EMA cross");
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
// ...moved to UserActions.mqh...
// --- User action: adjust minimum Golden Candle size ---
// ...moved to UserActions.mqh...
// --- User action: manual order ---
// ...moved to ManualOrder.mqh...
// --- User action: skip level ---
// ...moved to UserActions.mqh...
// --- Ladder label helpers ---
// ...moved to ChartUtils.mqh...

// --- Trailing stop logic (basic, for open trades) ---
// ...moved to TrailingStop.mqh...