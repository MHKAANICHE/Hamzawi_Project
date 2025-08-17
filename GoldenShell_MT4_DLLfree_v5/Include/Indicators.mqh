#property strict
#ifndef __INDICATORS_MQH__
#define __INDICATORS_MQH__

struct SignalInfo
{
   int    dir;         // +1 buy, -1 sell, 0 none
   bool   valid;       // golden candle & rules satisfied
   datetime time;      // base candle time
   double baseClose;   // close price of signal candle
   double entryPrice;  // baseClose +/- EntryOffset
};

// Compute SAR/MA and Golden Candle validation
bool ComputeSignal(SignalInfo &out,
                   double sar_step,double sar_max,
                   int fastP,int fastShift,int slowP,int slowShift,
                   int baseSLPips,int entryPercent)
{
   out.dir = 0; out.valid=false; out.time=0; out.baseClose=0; out.entryPrice=0;

   int shift=1; // use closed candle
   double sar = iSAR(Symbol(), PERIOD_M1, sar_step, sar_max, shift);
   double maFast = iMA(Symbol(), PERIOD_M1, fastP, fastShift, MODE_EMA, PRICE_CLOSE, shift);
   double maSlow = iMA(Symbol(), PERIOD_M1, slowP, slowShift, MODE_EMA, PRICE_CLOSE, shift);

   double close = iClose(Symbol(), PERIOD_M1, shift);

   // Direction from SAR + MA cross flavor
   int dir = 0;
   if(close > sar && maFast > maSlow) dir = +1;
   if(close < sar && maFast < maSlow) dir = -1;

   if(dir==0) return false;

   // Golden candle validation
   double entryOffsetPts = (baseSLPips * entryPercent)/100.0;
   double entryOffsetPrice = entryOffsetPts * Point;
   double entry = (dir>0) ? (close + entryOffsetPrice) : (close - entryOffsetPrice);

   out.dir = dir;
   out.valid = true;
   out.time = iTime(Symbol(), PERIOD_M1, shift);
   out.baseClose = close;
   out.entryPrice = NormalizeDouble(entry, Digits);
   return true;
}

#endif
