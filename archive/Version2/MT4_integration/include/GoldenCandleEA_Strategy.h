// GoldenCandleEA_Strategy.h
// Strategy logic interface

#ifndef GOLDENCANDLEEA_STRATEGY_H
#define GOLDENCANDLEEA_STRATEGY_H

struct StrategyParams {
    double psarStep;
    double psarMax;
    int emaFastPeriod;
    int emaFastShift;
    int emaSlowPeriod;
    int emaSlowShift;
    double goldenCandlePercent;
    double ladderStep;
    int ladderLevels;
};

int DetectGoldenCandle(double* highs, double* lows, int len, double minSize, double maxSize);
int DetectEMACross(double* prices, int len, int fastPeriod, int fastShift, int slowPeriod, int slowShift);
void CalculateLadderLevels(double entry, double step, int levels, double* outLevels);

#endif // GOLDENCANDLEEA_STRATEGY_H
