// GoldenCandleEA_Strategy.cpp
#include "GoldenCandleEA_Strategy.h"


// Golden Candle detection: looks for a candle where the size (high-low) is within min/max bounds
// and where the direction of the previous SAR (above/below) switches for this candle.
// For this stub, we only check size and return the first valid index from the right (most recent)
int DetectGoldenCandle(double* highs, double* lows, int len, double minSize, double maxSize) {
    for(int i = len-2; i >= 1; --i) { // skip the current forming candle (len-1), check historical
        double size = highs[i] - lows[i];
        if(size >= minSize && size <= maxSize) {
            // SAR direction switch logic would go here (requires SAR array)
            return i;
        }
    }
    return -1;
}


// EMA cross detection: returns 1 for bullish cross, -1 for bearish cross, 0 for none
// For this stub, we use a simple difference of two EMAs (not a full implementation)
double calcEMA(const double* prices, int len, int period, int shift) {
    if(len < period+shift) return 0.0;
    double alpha = 2.0 / (period+1);
    double ema = prices[len-1-shift];
    for(int i=len-2-shift; i>=len-period-shift; --i) {
        ema = alpha * prices[i] + (1-alpha) * ema;
    }
    return ema;
}

int DetectEMACross(double* prices, int len, int fastPeriod, int fastShift, int slowPeriod, int slowShift) {
    if(len < slowPeriod+slowShift+2) return 0;
    double fastPrev = calcEMA(prices, len-1, fastPeriod, fastShift);
    double slowPrev = calcEMA(prices, len-1, slowPeriod, slowShift);
    double fastCurr = calcEMA(prices, len, fastPeriod, fastShift);
    double slowCurr = calcEMA(prices, len, slowPeriod, slowShift);
    if(fastPrev < slowPrev && fastCurr > slowCurr) return 1; // bullish cross
    if(fastPrev > slowPrev && fastCurr < slowCurr) return -1; // bearish cross
    return 0;
}

void CalculateLadderLevels(double entry, double step, int levels, double* outLevels) {
    for(int i=0; i<levels; ++i) {
        outLevels[i] = entry + (i+1)*step;
    }
}
