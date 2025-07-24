//+------------------------------------------------------------------+
//|                                                      GoldenCandleEA.mq4 |
//|   Auto-generated based on client requirements and technical doc   |
//+------------------------------------------------------------------+
#property strict
#property copyright "MHKAANICHE"
#property link      ""
#property version   "1.00"
#property description "EA based on Parabolic SAR, EMA, and Golden Candle logic"

//--- Input parameters (extern for user adjustment)
extern double LotSize = 0.01;
extern double PSAR_Step = 0.001;
extern double PSAR_Max = 0.2;
extern int EMA1_Period = 1;
extern int EMA1_Shift = 0;
extern int EMA1_Method = MODE_EMA;
extern int EMA1_Applied = PRICE_CLOSE;
extern int EMA3_Period = 3;
extern int EMA3_Shift = 1;
extern int EMA3_Method = MODE_EMA;
extern int EMA3_Applied = PRICE_CLOSE;
extern color PSAR_Color = clrGreen;
extern color EMA1_Color = clrYellow;
extern color EMA3_Color = clrRed;
extern double GoldenCandleSize = 0; // 0 = auto-detect, else user-defined
extern color EntryLevelColor = clrGreen;
extern color SLLevelColor = clrRed;
extern color ProfitLevelColor = clrBlue;
extern int MagicNumber = 123456;

//--- Global variables
int ticket = -1;
bool inTrade = false;
int lastTradeType = -1; // 0 = buy, 1 = sell
int lotIndex = 0;
double lastEntryPrice = 0;
double lastSL = 0;
datetime lastEntryTime = 0; // Prevent multiple entries per bar

//--- Helper: Cap lotIndex to table size
void CapLotIndex() {
    if(lotIndex < 0) lotIndex = 0;
    if(lotIndex >= LOT_TABLE_SIZE) lotIndex = LOT_TABLE_SIZE-1;
}

//--- Lot progression table
#define LOT_TABLE_SIZE 25
const double LotTable[LOT_TABLE_SIZE] = {0.01,0.01,0.01,0.01,0.01,0.01,0.02,0.02,0.02,0.02,0.03,0.03,0.04,0.04,0.05,0.05,0.06,0.07,0.08,0.09,0.10,0.12,0.14,0.16,0.18};

//--- Helper function: Find Golden Candle
int FindGoldenCandle(int shift, bool isBuy) {
    for(int i=shift; i<Bars-1; i++) {
        double psarPrev = iSAR(NULL,0,PSAR_Step,PSAR_Max,i+1);
        double psarCurr = iSAR(NULL,0,PSAR_Step,PSAR_Max,i);
        double price = Close[i];
        if(isBuy && psarPrev > High[i+1] && psarCurr < Low[i]) return i;
        if(!isBuy && psarPrev < Low[i+1] && psarCurr > High[i]) return i;
    }
    return -1;
}

//--- Helper function: Calculate Entry Line
void CalculateEntryLine(int candleIdx, bool isBuy, double &entryLine, double &gcSize) {
    double high = High[candleIdx];
    double low = Low[candleIdx];
    gcSize = (GoldenCandleSize > 0) ? GoldenCandleSize : (high - low);
    if(isBuy)
        entryLine = high + 0.35 * gcSize;
    else
        entryLine = low - 0.35 * gcSize;
}

//--- Helper function: Check EMA cross
bool CheckEMACross(bool isBuy) {
    double ema1_prev = iMA(NULL,0,EMA1_Period,EMA1_Shift,EMA1_Method,EMA1_Applied,1);
    double ema3_prev = iMA(NULL,0,EMA3_Period,EMA3_Shift,EMA3_Method,EMA3_Applied,1);
    double ema1_curr = iMA(NULL,0,EMA1_Period,EMA1_Shift,EMA1_Method,EMA1_Applied,0);
    double ema3_curr = iMA(NULL,0,EMA3_Period,EMA3_Shift,EMA3_Method,EMA3_Applied,0);
    if(isBuy)
        return (ema1_prev < ema3_prev && ema1_curr > ema3_curr);
    else
        return (ema1_prev > ema3_prev && ema1_curr < ema3_curr);
}

//--- Helper function: Draw chart levels
void DrawLevels(double entry, double sl, double slValue, bool isBuy) {
    string prefix = isBuy ? "B_" : "S_";
    ObjectCreate(0,prefix+"Entry",OBJ_HLINE,0,0,entry); ObjectSetInteger(0,prefix+"Entry",OBJPROP_COLOR,EntryLevelColor);
    ObjectCreate(0,prefix+"SL",OBJ_HLINE,0,0,sl); ObjectSetInteger(0,prefix+"SL",OBJPROP_COLOR,SLLevelColor);
    for(int i=1;i<=7;i++) {
        double level = isBuy ? entry + i*slValue : entry - i*slValue;
        ObjectCreate(0,prefix+"L"+i,OBJ_HLINE,0,0,level); ObjectSetInteger(0,prefix+"L"+i,OBJPROP_COLOR,ProfitLevelColor);
    }
}

//--- Main EA logic
int start() {
    if(Bars < 100) return 0;
    CapLotIndex();
    datetime currTime = Time[0];

    // Helper: Robust OrderSend with retry (max 3 attempts)
    int RobustOrderSend(string symbol, int cmd, double lots, double price, int slippage, double sl, double tp, string comment, int magic, datetime expiry, color arrow_color) {
        int ticket = -1;
        for(int attempt=0; attempt<3 && ticket<0; attempt++) {
            ticket = OrderSend(symbol,cmd,lots,price,slippage,sl,tp,comment,magic,expiry,arrow_color);
            if(ticket<0) {
                Print("OrderSend attempt ", attempt+1, " failed (", comment, "): ", GetLastError());
                Sleep(500);
            }
        }
        return ticket;
    }
    if(inTrade && OrderSelect(ticket,SELECT_BY_TICKET)) {
        // Trailing stop logic
        double entry = lastEntryPrice;
        double slValue = MathAbs(entry - lastSL);
        double price = Close[0];
        if(lastTradeType == 0) { // Buy
            if(price >= entry + 3*slValue && OrderStopLoss() < entry) OrderModify(ticket,OrderOpenPrice(),entry,OrderTakeProfit(),0,SLLevelColor);
            if(price >= entry + 6*slValue && OrderStopLoss() < entry+slValue) OrderModify(ticket,OrderOpenPrice(),entry+slValue,OrderTakeProfit(),0,SLLevelColor);
        } else if(lastTradeType == 1) { // Sell
            if(price <= entry - 3*slValue && OrderStopLoss() > entry) OrderModify(ticket,OrderOpenPrice(),entry,OrderTakeProfit(),0,SLLevelColor);
            if(price <= entry - 6*slValue && OrderStopLoss() > entry-slValue) OrderModify(ticket,OrderOpenPrice(),entry-slValue,OrderTakeProfit(),0,SLLevelColor);
        }
        // Exit conditions
        double psar = iSAR(NULL,0,PSAR_Step,PSAR_Max,0);
        if((lastTradeType==0 && psar > Close[0]) || (lastTradeType==1 && psar < Close[0]) || OrderStopLoss()==OrderClosePrice() || OrderTakeProfit()==OrderClosePrice()) {
            Print("Order closed. Type:", lastTradeType==0?"Buy":"Sell", " at ", OrderClosePrice());
            bool wasSL = (OrderStopLoss()==OrderClosePrice());
            bool wasTP = (OrderTakeProfit()==OrderClosePrice());
            OrderClose(ticket,OrderLots(),OrderClosePrice(),3,clrViolet);
            inTrade = false;
            ticket = -1;
            if(wasSL) { lotIndex++; Print("Stop loss hit. Advancing lot index to ", lotIndex); }
            if(wasTP) { lotIndex = 0; Print("Take profit hit. Resetting lot index to 0."); }
            CapLotIndex();
        }
        return 0;
    }
    // Entry logic
    if(!inTrade && lastEntryTime != currTime) {
        // First Buy Entry
        int gcIdx = FindGoldenCandle(1,true);
        if(gcIdx > 0) {
            double entryLine, gcSize;
            CalculateEntryLine(gcIdx,true,entryLine,gcSize);
            for(int i=gcIdx-1;i>=0;i--) {
                if(High[i] > entryLine) {
                    double sl = entryLine - gcSize;
                    double tp = entryLine + 2*gcSize;
                    ticket = RobustOrderSend(Symbol(),OP_BUY,LotTable[lotIndex],Ask,3,sl,tp,"Buy",MagicNumber,0,EntryLevelColor);
                    if(ticket>0) {
                        inTrade = true; lastTradeType=0; lastEntryPrice=entryLine; lastSL=sl; lastEntryTime=currTime;
                        DrawLevels(entryLine,sl,gcSize,true);
                        Print("Buy order opened at ", entryLine, " SL:", sl, " TP:", tp, " Lot:", LotTable[lotIndex]);
                    } else {
                        Print("OrderSend error (Buy): ", GetLastError());
                    }
                    break;
                }
            }
        } else {
            Print("No Golden Candle found for Buy entry.");
        }
        // First Sell Entry
        gcIdx = FindGoldenCandle(1,false);
        if(gcIdx > 0) {
            double entryLine, gcSize;
            CalculateEntryLine(gcIdx,false,entryLine,gcSize);
            for(int i=gcIdx-1;i>=0;i--) {
                if(Low[i] < entryLine) {
                    double sl = entryLine + gcSize;
                    double tp = entryLine - 2*gcSize;
                    ticket = RobustOrderSend(Symbol(),OP_SELL,LotTable[lotIndex],Bid,3,sl,tp,"Sell",MagicNumber,0,SLLevelColor);
                    if(ticket>0) {
                        inTrade = true; lastTradeType=1; lastEntryPrice=entryLine; lastSL=sl; lastEntryTime=currTime;
                        DrawLevels(entryLine,sl,gcSize,false);
                        Print("Sell order opened at ", entryLine, " SL:", sl, " TP:", tp, " Lot:", LotTable[lotIndex]);
                    } else {
                        Print("OrderSend error (Sell): ", GetLastError());
                    }
                    break;
                }
            }
        } else {
            Print("No Golden Candle found for Sell entry.");
        }
        // Second Buy Entry (EMA cross)
        if(CheckEMACross(true)) {
            double price = Ask;
            // Fallback: If GoldenCandleSize is not set, use ATR(14) as a reasonable proxy for volatility
            double fallbackSize = iATR(NULL,0,14,0);
            double size = (GoldenCandleSize>0?GoldenCandleSize:fallbackSize);
            double sl = price - size;
            double tp = price + 2*size;
            if(size<=0) {
                Print("GoldenCandleSize/ATR not set for EMA Buy entry. Skipping.");
            } else {
                ticket = RobustOrderSend(Symbol(),OP_BUY,LotTable[lotIndex],Ask,3,sl,tp,"BuyEMA",MagicNumber,0,EntryLevelColor);
                if(ticket>0) {
                    inTrade = true; lastTradeType=0; lastEntryPrice=price; lastSL=sl; lastEntryTime=currTime;
                    DrawLevels(price,sl,size,true);
                    Print("BuyEMA order opened at ", price, " SL:", sl, " TP:", tp, " Lot:", LotTable[lotIndex]);
                } else {
                    Print("OrderSend error (BuyEMA): ", GetLastError());
                }
            }
        }
        // Second Sell Entry (EMA cross)
        if(CheckEMACross(false)) {
            double price = Bid;
            // Fallback: If GoldenCandleSize is not set, use ATR(14) as a reasonable proxy for volatility
            double fallbackSize = iATR(NULL,0,14,0);
            double size = (GoldenCandleSize>0?GoldenCandleSize:fallbackSize);
            double sl = price + size;
            double tp = price - 2*size;
            if(size<=0) {
                Print("GoldenCandleSize/ATR not set for EMA Sell entry. Skipping.");
            } else {
                ticket = RobustOrderSend(Symbol(),OP_SELL,LotTable[lotIndex],Bid,3,sl,tp,"SellEMA",MagicNumber,0,SLLevelColor);
                if(ticket>0) {
                    inTrade = true; lastTradeType=1; lastEntryPrice=price; lastSL=sl; lastEntryTime=currTime;
                    DrawLevels(price,sl,size,false);
                    Print("SellEMA order opened at ", price, " SL:", sl, " TP:", tp, " Lot:", LotTable[lotIndex]);
                } else {
                    Print("OrderSend error (SellEMA): ", GetLastError());
                }
            }
        }
    }
    return 0;
}
//+------------------------------------------------------------------+
