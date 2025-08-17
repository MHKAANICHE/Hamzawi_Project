//+------------------------------------------------------------------+
//|                                           GoldenCandleStrategy.mqh |
//|                                           Copyright 2025, Golden Candle |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle"
#property strict

#include "../Base/Enums.mqh"
#include "../Base/Constants.mqh"
#include "../Base/Structures.mqh"
#include "../Base/StrategyBase.mqh"

// Forward declarations
class CStrategyBase;


//+------------------------------------------------------------------+
//| Golden Candle Strategy Parameters                                  |
//+------------------------------------------------------------------+
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
    
    // Candle pattern parameters
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
        bodyToWickRatio = 2.0;
        minCandleSize = 10;
        maxCandleSize = 100;
        minVolumeMultiplier = 1.5;
        volumeAvgPeriod = 20;
        trendMAPeriod = 50;
        trendStrength = 0.2;
        momentumPeriod = 14;
        momentumThreshold = 0.1;
    }
};

//+------------------------------------------------------------------+
//| Golden Candle Strategy Class                                       |
//+------------------------------------------------------------------+
class CGoldenCandleStrategy : public CStrategyBase {
private:
    // Strategy-specific parameters
    SGoldenCandleParams m_gcParams;
    
    // Additional indicators
    int              m_trendMAHandle;
    int              m_momentumHandle;
    double           m_trendMA[];
    double           m_momentum[];
    
    // Market data
    MqlRates m_rates[];       // Price data array

    // Private methods
    bool             IsGoldenCandle(int index);
    bool             IsVolumeValid(int index);
    bool             IsTrendValid(int index);
    bool             IsMomentumValid(int index);
    double           CalculateTrendStrength(int index);
    virtual bool     InitIndicators();
    virtual void     DeinitIndicators();
    
public:
                     CGoldenCandleStrategy();
                    ~CGoldenCandleStrategy();
    
    // Required implementations
    virtual bool     Validate();
    virtual bool     CheckEntryConditions();
    virtual bool     CheckExitConditions();
    virtual double   GetEntryPrice(ENUM_ORDER_TYPE type);
    
    // Strategy-specific methods
    void            SetGoldenCandleParams(SGoldenCandleParams &params);
    SGoldenCandleParams* GetGoldenCandleParams() { return &m_gcParams; }
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CGoldenCandleStrategy::CGoldenCandleStrategy() {
    m_strategyName = "GoldenCandle";
    m_gcParams.SetDefaults();
    
    ArraySetAsSeries(m_trendMA, true);
    ArraySetAsSeries(m_momentum, true);
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CGoldenCandleStrategy::~CGoldenCandleStrategy() {
    DeinitIndicators();
}

//+------------------------------------------------------------------+
//| Initialize strategy-specific indicators                            |
//+------------------------------------------------------------------+
bool CGoldenCandleStrategy::InitIndicators() {
    // Initialize base class indicators
    if(!CStrategyBase::InitIndicators()) return false;
    
    // Initialize strategy-specific indicators
    m_trendMAHandle = iMA(m_symbol, m_timeframe, m_gcParams.trendMAPeriod, 
                         0, MODE_EMA, PRICE_CLOSE);
                         
    m_momentumHandle = iMomentum(m_symbol, m_timeframe, 
                                m_gcParams.momentumPeriod, PRICE_CLOSE);
    
    return m_trendMAHandle != INVALID_HANDLE && 
           m_momentumHandle != INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| Deinitialize strategy-specific indicators                          |
//+------------------------------------------------------------------+
void CGoldenCandleStrategy::DeinitIndicators() {
    // Deinitialize base class indicators
    CStrategyBase::DeinitIndicators();
    
    // Deinitialize strategy-specific indicators
    if(m_trendMAHandle != INVALID_HANDLE) {
        IndicatorRelease(m_trendMAHandle);
        m_trendMAHandle = INVALID_HANDLE;
    }
    if(m_momentumHandle != INVALID_HANDLE) {
        IndicatorRelease(m_momentumHandle);
        m_momentumHandle = INVALID_HANDLE;
    }
}

//+------------------------------------------------------------------+
//| Validate strategy conditions                                       |
//+------------------------------------------------------------------+
bool CGoldenCandleStrategy::Validate() {
    if(!m_isInitialized) return false;
    
    // Update market data
    if(!UpdateMarketData()) return false;
    
    // Copy indicator data
    if(CopyBuffer(m_trendMAHandle, 0, 0, 100, m_trendMA) <= 0) return false;
    if(CopyBuffer(m_momentumHandle, 0, 0, 100, m_momentum) <= 0) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Check entry conditions                                            |
//+------------------------------------------------------------------+
bool CGoldenCandleStrategy::CheckEntryConditions() {
    if(!Validate()) return false;
    
    // Check for Golden Candle pattern
    if(!IsGoldenCandle(1)) return false;  // Check previous candle
    
    // Check volume conditions
    if(!IsVolumeValid(1)) return false;
    
    // Check trend conditions
    if(!IsTrendValid(1)) return false;
    
    // Check momentum conditions
    if(!IsMomentumValid(1)) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Check exit conditions                                             |
//+------------------------------------------------------------------+
bool CGoldenCandleStrategy::CheckExitConditions() {
    if(!Validate()) return false;
    
    // Exit on trend reversal
    if(m_trendMA[0] < m_trendMA[1] && m_currentPosition.type == ORDER_TYPE_BUY) {
        return true;
    }
    if(m_trendMA[0] > m_trendMA[1] && m_currentPosition.type == ORDER_TYPE_SELL) {
        return true;
    }
    
    // Exit on momentum reversal
    if(m_momentum[0] < m_momentum[1] && m_currentPosition.type == ORDER_TYPE_BUY) {
        return true;
    }
    if(m_momentum[0] > m_momentum[1] && m_currentPosition.type == ORDER_TYPE_SELL) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Get entry price for order                                         |
//+------------------------------------------------------------------+
double CGoldenCandleStrategy::GetEntryPrice(ENUM_ORDER_TYPE type) {
    return (type == ORDER_TYPE_BUY) ? 
           MarketInfo(m_symbol, MODE_ASK) :
           MarketInfo(m_symbol, MODE_BID);
}

//+------------------------------------------------------------------+
//| Check if candle meets Golden Candle criteria                      |
//+------------------------------------------------------------------+
bool CGoldenCandleStrategy::IsGoldenCandle(int index) {
    if(index < 0 || index >= ArraySize(m_rates)) return false;
    
    double bodySize = MathAbs(m_rates[index].close - m_rates[index].open);
    double upperWick = m_rates[index].high - MathMax(m_rates[index].open, m_rates[index].close);
    double lowerWick = MathMin(m_rates[index].open, m_rates[index].close) - m_rates[index].low;
    double totalWick = upperWick + lowerWick;
    
    // Check candle size
    double candleSize = m_rates[index].high - m_rates[index].low;
    if(candleSize < m_gcParams.minCandleSize * Point() || 
       candleSize > m_gcParams.maxCandleSize * Point()) {
        return false;
    }
    
    // Check body to wick ratio
    if(totalWick > 0 && bodySize / totalWick < m_gcParams.bodyToWickRatio) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if volume conditions are met                                |
//+------------------------------------------------------------------+
bool CGoldenCandleStrategy::IsVolumeValid(int index) {
    if(index < 0 || index >= ArraySize(m_rates)) return false;
    
    // Calculate average volume
    double avgVolume = 0;
    for(int i = index + 1; i < index + 1 + m_gcParams.volumeAvgPeriod; i++) {
        if(i >= ArraySize(m_rates)) break;
        avgVolume += m_rates[i].tick_volume;
    }
    avgVolume /= m_gcParams.volumeAvgPeriod;
    
    // Check if current volume is above minimum threshold
    return m_rates[index].tick_volume >= avgVolume * m_gcParams.minVolumeMultiplier;
}

//+------------------------------------------------------------------+
//| Check if trend conditions are met                                 |
//+------------------------------------------------------------------+
bool CGoldenCandleStrategy::IsTrendValid(int index) {
    if(index < 0 || index >= ArraySize(m_trendMA)) return false;
    
    // Calculate trend strength
    double strength = CalculateTrendStrength(index);
    
    return strength >= m_gcParams.trendStrength;
}

//+------------------------------------------------------------------+
//| Check if momentum conditions are met                              |
//+------------------------------------------------------------------+
bool CGoldenCandleStrategy::IsMomentumValid(int index) {
    if(index < 0 || index >= ArraySize(m_momentum)) return false;
    
    // Check momentum threshold
    return MathAbs(m_momentum[index] - m_momentum[index + 1]) >= m_gcParams.momentumThreshold;
}

//+------------------------------------------------------------------+
//| Calculate trend strength                                          |
//+------------------------------------------------------------------+
double CGoldenCandleStrategy::CalculateTrendStrength(int index) {
    if(index < 0 || index >= ArraySize(m_trendMA)) return 0;
    
    double strength = 0;
    int period = m_gcParams.trendMAPeriod / 2;
    
    for(int i = index; i < index + period && i < ArraySize(m_trendMA) - 1; i++) {
        if(m_trendMA[i] > m_trendMA[i + 1]) {
            strength += 1;
        } else if(m_trendMA[i] < m_trendMA[i + 1]) {
            strength -= 1;
        }
    }
    
    return MathAbs(strength) / period;
}

//+------------------------------------------------------------------+
//| Set Golden Candle strategy parameters                             |
//+------------------------------------------------------------------+
void CGoldenCandleStrategy::SetGoldenCandleParams(SGoldenCandleParams &params) {
    m_gcParams = params;
    if(m_isInitialized) {
        DeinitIndicators();
        InitIndicators();
    }
}
