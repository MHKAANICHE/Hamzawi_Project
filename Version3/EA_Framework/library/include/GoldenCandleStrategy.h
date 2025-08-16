#ifndef GOLDEN_CANDLE_STRATEGY_H
#define GOLDEN_CANDLE_STRATEGY_H

#include "Structures.h"
#include <cstddef>

// Strategy Parameters
struct SGoldenCandleParams {
    // SAR Parameters
    double sarStep;             // SAR Step (default 0.001)
    double sarMaximum;         // SAR Maximum (default 0.2)
    
    // Moving Averages
    int fastMAPeriod;         // Fast MA Period (default 1)
    int fastMAShift;          // Fast MA Shift (default 0)
    int slowMAPeriod;         // Slow MA Period (default 3)
    int slowMAShift;          // Slow MA Shift (default 1)
    
    // Entry Parameters
    int entryOffset;          // Entry offset in points (default 3500)
    int baseSL;              // Base stop loss in points (default 10000)
    
    // Pattern Parameters
    double bodyToWickRatio;    // Required ratio of body to wick
    double minCandleSize;      // Minimum candle size in points
    double maxCandleSize;      // Maximum candle size in points
    double minVolumeMultiplier;// Required volume multiplier
    int volumeAvgPeriod;      // Period for volume average
    int trendMAPeriod;        // Period for trend MA
    double trendStrength;      // Required trend strength
    int momentumPeriod;       // Period for momentum
    double momentumThreshold;  // Required momentum threshold
    
    void SetDefaults() {
        sarStep = 0.001;
        sarMaximum = 0.2;
        fastMAPeriod = 1;
        fastMAShift = 0;
        slowMAPeriod = 3;
        slowMAShift = 1;
        entryOffset = 3500;
        baseSL = 10000;
        bodyToWickRatio = 2.0;
        minCandleSize = 10.0;
        maxCandleSize = 100.0;
        minVolumeMultiplier = 1.5;
        volumeAvgPeriod = 20;
        trendMAPeriod = 50;
        trendStrength = 0.2;
        momentumPeriod = 14;
        momentumThreshold = 0.1;
    }
};

class CGoldenCandleStrategy {
private:
    MqlRates*           m_rates;
    int                 m_ratesCount;
    double              m_lastPrice;
    bool                m_isInitialized;
    SSignalInfo         m_currentSignal;
    SGoldenCandle       m_lastGoldenCandle;
    SGoldenCandleParams m_params;

public:
    CGoldenCandleStrategy() : m_rates(NULL), m_ratesCount(0), 
                             m_lastPrice(0.0), m_isInitialized(false) {}
    
    ~CGoldenCandleStrategy() {
        if(m_rates) {
            delete[] m_rates;
            m_rates = NULL;
        }
    }

    bool Init();
    void Deinit();
    bool UpdateRates(MqlRates* rates, int count);
    bool CheckEntryConditions();
    bool CheckExitConditions();
    double GetEntryPrice(ENUM_ORDER_TYPE type);
    const SSignalInfo& GetCurrentSignal() const { return m_currentSignal; }
    const SGoldenCandle& GetLastGoldenCandle() const { return m_lastGoldenCandle; }
    void SetGoldenCandleParams(SGoldenCandleParams* params) { if(params) m_params = *params; }
};

#endif // GOLDEN_CANDLE_STRATEGY_H
