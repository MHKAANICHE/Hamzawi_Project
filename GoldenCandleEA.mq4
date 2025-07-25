//--- Persistent flag: Only start trading after first Golden Candle appears
bool goldenCandleAppeared = false;
//--- Draw Golden Candle rectangle on chart
void DrawGoldenCandleRect(int candleIdx, bool isBuy) {
    string objName = (isBuy ? "GC_BUY_" : "GC_SELL_") + IntegerToString(candleIdx) + "_" + IntegerToString(Time[candleIdx]);
    color rectColor = isBuy ? clrLime : clrOrangeRed;
    double high = High[candleIdx];
    double low = Low[candleIdx];
    datetime time1 = Time[candleIdx+1];
    datetime time2 = Time[candleIdx];
    ObjectCreate(0, objName, OBJ_RECTANGLE, 0, time1, high, time2, low);
    ObjectSetInteger(0, objName, OBJPROP_COLOR, rectColor);
    ObjectSetInteger(0, objName, OBJPROP_BACK, true);
    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
    // Transparency is not supported in MT4, so OBJPROP_TRANSPARENCY is omitted
}
//--- Logging helper
string logFileName = "GoldenCandleEA_log.csv";

void LogEvent(string eventType, string details) {
    string logLine = TimeToStr(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "," + eventType + "," + details;
    Print(logLine);
    int handle = FileOpen(logFileName, FILE_CSV|FILE_WRITE|FILE_READ, ';');
    if(handle >= 0) {
        FileSeek(handle, 0, SEEK_END);
        FileWrite(handle, logLine);
        FileClose(handle);
    }
}

//--- Log EA setup (input parameters)
void LogEASetup() {
    string setup = "LotSize=" + DoubleToStr(LotSize,2) + ",PSAR_Step=" + DoubleToStr(PSAR_Step,3) + ",PSAR_Max=" + DoubleToStr(PSAR_Max,2) +
        ",EMA1_Period=" + IntegerToString(EMA1_Period) + ",EMA1_Shift=" + IntegerToString(EMA1_Shift) + ",EMA1_Method=" + IntegerToString(EMA1_Method) + ",EMA1_Applied=" + IntegerToString(EMA1_Applied) +
        ",EMA3_Period=" + IntegerToString(EMA3_Period) + ",EMA3_Shift=" + IntegerToString(EMA3_Shift) + ",EMA3_Method=" + IntegerToString(EMA3_Method) + ",EMA3_Applied=" + IntegerToString(EMA3_Applied) +
        ",GoldenCandleSize=" + DoubleToStr(GoldenCandleSize,Digits) + ",MagicNumber=" + IntegerToString(MagicNumber);
    LogEvent("SETUP", setup);
}
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


//--- Lot progression table
#define LOT_TABLE_SIZE 25
const double LotTable[LOT_TABLE_SIZE] = {0.01,0.01,0.01,0.01,0.01,0.01,0.02,0.02,0.02,0.02,0.03,0.03,0.04,0.04,0.05,0.05,0.06,0.07,0.08,0.09,0.10,0.12,0.14,0.16,0.18};

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

//--- Helper: Robust OrderSend with StopLevel check and enhanced logging
int RobustOrderSend(string symbol, int cmd, double lots, double price, int slippage, double sl, double tp, string comment, int magic, datetime expiry, color arrow_color) {
    int ticket = -1;
    double point = MarketInfo(symbol, MODE_POINT);
    int digits = MarketInfo(symbol, MODE_DIGITS);
    int stopLevel = MarketInfo(symbol, MODE_STOPLEVEL);
    double minDist = stopLevel * point;
    // Fallback: if StopLevel is zero, use 10 points (1 pip for 5-digit, 10 pips for 3-digit)
    if (minDist <= 0) {
        minDist = (point > 0.0001 ? 0.00010 : 0.01); // 1 pip for most FX, 10 pips for JPY pairs
        LogEvent("STOPLEVEL_FALLBACK", "Broker StopLevel=0, using default minDist=" + DoubleToStr(minDist, digits));
    }
    double origSL = sl, origTP = tp;
    // Adjust SL/TP if too close
    if(cmd == OP_BUY) {
        if(sl > 0 && (price - sl) < minDist) {
            sl = price - minDist;
            LogEvent("ADJUST_SL", "Buy SL too close. Adjusted from " + DoubleToStr(origSL, digits) + " to " + DoubleToStr(sl, digits) + ", StopLevel=" + DoubleToStr(minDist, digits));
        }
        if(tp > 0 && (tp - price) < minDist) {
            tp = price + minDist;
            LogEvent("ADJUST_TP", "Buy TP too close. Adjusted from " + DoubleToStr(origTP, digits) + " to " + DoubleToStr(tp, digits) + ", StopLevel=" + DoubleToStr(minDist, digits));
        }
    } else if(cmd == OP_SELL) {
        if(sl > 0 && (sl - price) < minDist) {
            sl = price + minDist;
            LogEvent("ADJUST_SL", "Sell SL too close. Adjusted from " + DoubleToStr(origSL, digits) + " to " + DoubleToStr(sl, digits) + ", StopLevel=" + DoubleToStr(minDist, digits));
        }
        if(tp > 0 && (price - tp) < minDist) {
            tp = price - minDist;
            LogEvent("ADJUST_TP", "Sell TP too close. Adjusted from " + DoubleToStr(origTP, digits) + " to " + DoubleToStr(tp, digits) + ", StopLevel=" + DoubleToStr(minDist, digits));
        }
    }
    for(int attempt=0; attempt<3 && ticket<0; attempt++) {
        ticket = OrderSend(symbol,cmd,lots,price,slippage,sl,tp,comment,magic,expiry,arrow_color);
        if(ticket<0) {
            int err = GetLastError();
            LogEvent("ORDER_SEND_FAIL", "Attempt="+IntegerToString(attempt+1)+",Cmd="+IntegerToString(cmd)+",Price="+DoubleToStr(price,digits)+",SL="+DoubleToStr(sl,digits)+",TP="+DoubleToStr(tp,digits)+",StopLevel="+DoubleToStr(minDist,digits)+",Error="+IntegerToString(err));
            if(err == 130) {
                LogEvent("ERROR_130", "Invalid stops: SL/TP too close. Price="+DoubleToStr(price,digits)+",SL="+DoubleToStr(sl,digits)+",TP="+DoubleToStr(tp,digits)+",StopLevel="+DoubleToStr(minDist,digits));
            }
            Sleep(500);
        }
    }
    return ticket;
}

//--- Main EA logic
int start() {
    static bool setupLogged = false;
    if(!setupLogged) { LogEASetup(); setupLogged = true; }
    if(Bars < 100) return 0;
    CapLotIndex();
    datetime currTime = Time[0];

    // Check for first Golden Candle apparition (buy or sell)
    if(!goldenCandleAppeared) {
        int firstBuyGC = FindGoldenCandle(1, true);
        int firstSellGC = FindGoldenCandle(1, false);
        if(firstBuyGC > 0 || firstSellGC > 0) {
            goldenCandleAppeared = true;
            LogEvent("FIRST_GC_APPARITION", "First Golden Candle detected at bar " + IntegerToString(firstBuyGC > 0 ? firstBuyGC : firstSellGC) + (firstBuyGC > 0 ? ",Type=Buy" : ",Type=Sell"));
        } else {
            // No Golden Candle yet, do not trade
            LogEvent("WAITING_GC", "No Golden Candle detected yet. Trading is paused.");
            return 0;
        }
    }

    if(inTrade && OrderSelect(ticket,SELECT_BY_TICKET)) {
        LogEvent("IN_TRADE", "Ticket="+IntegerToString(ticket)+",Type="+(lastTradeType==0?"Buy":"Sell")+",Entry="+DoubleToStr(lastEntryPrice,Digits)+",SL="+DoubleToStr(lastSL,Digits));
        // Trailing stop logic
        double entry = lastEntryPrice;
        double slValue = MathAbs(entry - lastSL);
        double price = Close[0];
        if(lastTradeType == 0) { // Buy
            if(price >= entry + 3*slValue && OrderStopLoss() < entry) {
                OrderModify(ticket,OrderOpenPrice(),entry,OrderTakeProfit(),0,SLLevelColor);
                LogEvent("TRAIL", "Buy trailing stop moved to "+DoubleToStr(entry,Digits));
            }
            if(price >= entry + 6*slValue && OrderStopLoss() < entry+slValue) {
                OrderModify(ticket,OrderOpenPrice(),entry+slValue,OrderTakeProfit(),0,SLLevelColor);
                LogEvent("TRAIL", "Buy trailing stop moved to "+DoubleToStr(entry+slValue,Digits));
            }
        } else if(lastTradeType == 1) { // Sell
            if(price <= entry - 3*slValue && OrderStopLoss() > entry) {
                OrderModify(ticket,OrderOpenPrice(),entry,OrderTakeProfit(),0,SLLevelColor);
                LogEvent("TRAIL", "Sell trailing stop moved to "+DoubleToStr(entry,Digits));
            }
            if(price <= entry - 6*slValue && OrderStopLoss() > entry-slValue) {
                OrderModify(ticket,OrderOpenPrice(),entry-slValue,OrderTakeProfit(),0,SLLevelColor);
                LogEvent("TRAIL", "Sell trailing stop moved to "+DoubleToStr(entry-slValue,Digits));
            }
        }
        // Exit conditions
        double psar = iSAR(NULL,0,PSAR_Step,PSAR_Max,0);
        if((lastTradeType==0 && psar > Close[0]) || (lastTradeType==1 && psar < Close[0]) || OrderStopLoss()==OrderClosePrice() || OrderTakeProfit()==OrderClosePrice()) {
            string closeType = (OrderStopLoss()==OrderClosePrice()) ? "SL" : (OrderTakeProfit()==OrderClosePrice() ? "TP" : "PSAR");
            LogEvent("EXIT", "Order closed. Type:"+(lastTradeType==0?"Buy":"Sell")+", at "+DoubleToStr(OrderClosePrice(),Digits)+", Reason="+closeType);
            bool wasSL = (OrderStopLoss()==OrderClosePrice());
            bool wasTP = (OrderTakeProfit()==OrderClosePrice());
            OrderClose(ticket,OrderLots(),OrderClosePrice(),3,clrViolet);
            inTrade = false;
            ticket = -1;
            if(wasSL) { lotIndex++; LogEvent("LOT_INDEX","Stop loss hit. Advancing lot index to "+IntegerToString(lotIndex)); }
            if(wasTP) { lotIndex = 0; LogEvent("LOT_INDEX","Take profit hit. Resetting lot index to 0."); }
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
            LogEvent("GOLDEN_CANDLE_BUY", "Detected at bar "+IntegerToString(gcIdx)+", Size:"+DoubleToStr(gcSize,Digits));
            DrawGoldenCandleRect(gcIdx, true);
            for(int i=gcIdx-1;i>=0;i--) {
                if(High[i] > entryLine) {
                    double sl = entryLine - gcSize;
                    double tp = entryLine + 2*gcSize;
                    ticket = RobustOrderSend(Symbol(),OP_BUY,LotTable[lotIndex],Ask,3,sl,tp,"Buy",MagicNumber,0,EntryLevelColor);
                    if(ticket>0) {
                        inTrade = true; lastTradeType=0; lastEntryPrice=entryLine; lastSL=sl; lastEntryTime=currTime;
                        DrawLevels(entryLine,sl,gcSize,true);
                        LogEvent("ENTRY", "Buy order opened at "+DoubleToStr(entryLine,Digits)+" SL:"+DoubleToStr(sl,Digits)+" TP:"+DoubleToStr(tp,Digits)+" Lot:"+DoubleToStr(LotTable[lotIndex],2));
                    } else {
                        LogEvent("ERROR", "OrderSend error (Buy): "+IntegerToString(GetLastError()));
                    }
                    break;
                }
            }
        } else {
            LogEvent("NO_GC_BUY", "No Golden Candle found for Buy entry.");
        }
        // First Sell Entry
        gcIdx = FindGoldenCandle(1,false);
        if(gcIdx > 0) {
            double entryLine, gcSize;
            CalculateEntryLine(gcIdx,false,entryLine,gcSize);
            LogEvent("GOLDEN_CANDLE_SELL", "Detected at bar "+IntegerToString(gcIdx)+", Size:"+DoubleToStr(gcSize,Digits));
            DrawGoldenCandleRect(gcIdx, false);
            for(int i=gcIdx-1;i>=0;i--) {
                if(Low[i] < entryLine) {
                    double sl = entryLine + gcSize;
                    double tp = entryLine - 2*gcSize;
                    ticket = RobustOrderSend(Symbol(),OP_SELL,LotTable[lotIndex],Bid,3,sl,tp,"Sell",MagicNumber,0,SLLevelColor);
                    if(ticket>0) {
                        inTrade = true; lastTradeType=1; lastEntryPrice=entryLine; lastSL=sl; lastEntryTime=currTime;
                        DrawLevels(entryLine,sl,gcSize,false);
                        LogEvent("ENTRY", "Sell order opened at "+DoubleToStr(entryLine,Digits)+" SL:"+DoubleToStr(sl,Digits)+" TP:"+DoubleToStr(tp,Digits)+" Lot:"+DoubleToStr(LotTable[lotIndex],2));
                    } else {
                        LogEvent("ERROR", "OrderSend error (Sell): "+IntegerToString(GetLastError()));
                    }
                    break;
                }
            }
        } else {
            LogEvent("NO_GC_SELL", "No Golden Candle found for Sell entry.");
        }
        // Second Buy Entry (EMA cross)
        if(CheckEMACross(true)) {
            double price = Ask;
            double fallbackSize = iATR(NULL,0,14,0);
            double size = (GoldenCandleSize>0?GoldenCandleSize:fallbackSize);
            double sl = price - size;
            double tp = price + 2*size;
            LogEvent("EMA_CROSS_BUY", "Buy cross detected at price "+DoubleToStr(price,Digits)+", Size:"+DoubleToStr(size,Digits));
            if(size<=0) {
                LogEvent("ERROR", "GoldenCandleSize/ATR not set for EMA Buy entry. Skipping.");
            } else {
                ticket = RobustOrderSend(Symbol(),OP_BUY,LotTable[lotIndex],Ask,3,sl,tp,"BuyEMA",MagicNumber,0,EntryLevelColor);
                if(ticket>0) {
                    inTrade = true; lastTradeType=0; lastEntryPrice=price; lastSL=sl; lastEntryTime=currTime;
                    DrawLevels(price,sl,size,true);
                    LogEvent("ENTRY", "BuyEMA order opened at "+DoubleToStr(price,Digits)+" SL:"+DoubleToStr(sl,Digits)+" TP:"+DoubleToStr(tp,Digits)+" Lot:"+DoubleToStr(LotTable[lotIndex],2));
                } else {
                    LogEvent("ERROR", "OrderSend error (BuyEMA): "+IntegerToString(GetLastError()));
                }
            }
        }
        // Second Sell Entry (EMA cross)
        if(CheckEMACross(false)) {
            double price = Bid;
            double fallbackSize = iATR(NULL,0,14,0);
            double size = (GoldenCandleSize>0?GoldenCandleSize:fallbackSize);
            double sl = price + size;
            double tp = price - 2*size;
            LogEvent("EMA_CROSS_SELL", "Sell cross detected at price "+DoubleToStr(price,Digits)+", Size:"+DoubleToStr(size,Digits));
            if(size<=0) {
                LogEvent("ERROR", "GoldenCandleSize/ATR not set for EMA Sell entry. Skipping.");
            } else {
                ticket = RobustOrderSend(Symbol(),OP_SELL,LotTable[lotIndex],Bid,3,sl,tp,"SellEMA",MagicNumber,0,SLLevelColor);
                if(ticket>0) {
                    inTrade = true; lastTradeType=1; lastEntryPrice=price; lastSL=sl; lastEntryTime=currTime;
                    DrawLevels(price,sl,size,false);
                    LogEvent("ENTRY", "SellEMA order opened at "+DoubleToStr(price,Digits)+" SL:"+DoubleToStr(sl,Digits)+" TP:"+DoubleToStr(tp,Digits)+" Lot:"+DoubleToStr(LotTable[lotIndex],2));
                } else {
                    LogEvent("ERROR", "OrderSend error (SellEMA): "+IntegerToString(GetLastError()));
                }
            }
        }
    }
    return 0;
}
//+------------------------------------------------------------------+
