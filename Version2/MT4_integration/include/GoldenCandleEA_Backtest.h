// GoldenCandleEA_Backtest.h
// Backtest and optimization interface

#ifndef GOLDENCANDLEEA_BACKTEST_H
#define GOLDENCANDLEEA_BACKTEST_H

struct BacktestParams {
    double sharpeRatioTarget;
    char startDate[11]; // YYYY-MM-DD
    char endDate[11];   // YYYY-MM-DD
    // Add more as needed
};

void RunBacktest(const BacktestParams* params);

#endif // GOLDENCANDLEEA_BACKTEST_H
