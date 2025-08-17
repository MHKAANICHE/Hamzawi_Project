#pragma once

#include <vector>
#include "MarketTypes.h"

namespace GoldenCandle {

//+------------------------------------------------------------------+
//| Technical Analysis Settings                                         |
//+------------------------------------------------------------------+
struct SARSettings {
    double step;            // SAR step (0.001)
    double maximum;         // SAR maximum (0.2)
    double initialStep;     // Initial step value
};

struct MASettings {
    int fastPeriod;        // Fast MA period (1)
    int fastShift;         // Fast MA shift (0)
    int slowPeriod;        // Slow MA period (3)
    int slowShift;         // Slow MA shift (1)
    int method;            // MA method (EMA)
};

//+------------------------------------------------------------------+
//| Technical Analysis Core Class                                      |
//+------------------------------------------------------------------+
class TechnicalCore {
private:
    bool m_initialized;
    SARSettings m_sarSettings;
    MASettings m_maSettings;
    
    // SAR state
    struct SARState {
        double currentValue;
        double extremePoint;
        double acceleration;
        bool isLong;
        bool isFirstTrend;
    } m_sarState;
    
    // MA state
    struct MAState {
        std::vector<double> fastBuffer;
        std::vector<double> slowBuffer;
        int lastCalculated;
    } m_maState;
    
    // Internal calculations
    double CalculateSAR(const CandleData& candle);
    double CalculateMA(const std::vector<double>& prices, int period, 
                      int shift, int method);
    bool ValidateSARSignal(const CandleData& candle, double sarValue);
    bool ValidateMACrossover(int shift);
    
public:
    TechnicalCore();
    ~TechnicalCore();
    
    // Initialization
    bool Initialize(const CoreConfig& config);
    void SetSARSettings(const SARSettings& settings);
    void SetMASettings(const MASettings& settings);
    
    // Technical Analysis
    bool UpdateIndicators(const MarketData& market);
    bool CheckSARSignal(const MarketData& market, SignalInfo& signal);
    bool CheckMASignal(const MarketData& market, SignalInfo& signal);
    
    // Golden Candle Validation
    bool ValidateGoldenCandle(const CandleData& candle, 
                            double baseSize, double entryLevel);
    bool ValidateEntryLevel(double price, double entryLevel);
    
    // State access
    double GetCurrentSAR() const { return m_sarState.currentValue; }
    bool GetSARTrend() const { return m_sarState.isLong; }
    bool IsInitialized() const { return m_initialized; }
};

} // namespace GoldenCandle
