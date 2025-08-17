#include "GoldenCandleStrategy.h"
#include <vector>
#include <algorithm>
#include <cmath>

// Internal state
static struct {
    GoldenCandleParams params;
    std::vector<double> sarValues;
    std::vector<double> fastMA;
    std::vector<double> slowMA;
    bool isInitialized;
} state;

// Technical indicators implementation
class ParabolicSAR {
private:
    SARState state;
    double stepValue;
    double maxValue;
    
public:
    ParabolicSAR() {
        state.isInitialized = false;
        state.isContinuous = false;
        state.consecutiveCount = 0;
        state.direction = SAR_UNKNOWN;
    }
    
    void Init(double step, double max) {
        stepValue = step;
        maxValue = max;
        state.accelerationFactor = step;
        state.isInitialized = false;
        state.isContinuous = false;
        state.consecutiveCount = 0;
        state.direction = SAR_UNKNOWN;
    }
    
    SARState GetState() const { return state; }
    
    double Calculate(double high, double low, double open, double close) {
        if (!state.isInitialized) {
            // Initialize SAR
            state.direction = close > open ? SAR_UP : SAR_DOWN;
            state.currentSAR = state.direction == SAR_UP ? low : high;
            state.extremePoint = state.direction == SAR_UP ? high : low;
            state.isInitialized = true;
            return state.currentSAR;
        }
        
        double prevSAR = state.currentSAR;
        SARDirection prevDirection = state.direction;
        
        // Calculate SAR
        state.currentSAR = prevSAR + state.accelerationFactor * (state.extremePoint - prevSAR);
        
        // Check for direction change
        bool directionChanged = false;
        
        if (state.direction == SAR_UP) {
            if (low < state.currentSAR) {
                // Change to downtrend
                state.direction = SAR_DOWN;
                state.currentSAR = state.extremePoint;
                state.extremePoint = low;
                state.accelerationFactor = stepValue;
                directionChanged = true;
            } else {
                // Continue uptrend
                if (high > state.extremePoint) {
                    state.extremePoint = high;
                    state.accelerationFactor = std::min(state.accelerationFactor + stepValue, maxValue);
                }
            }
        } else {
            if (high > state.currentSAR) {
                // Change to uptrend
                state.direction = SAR_UP;
                state.currentSAR = state.extremePoint;
                state.extremePoint = high;
                state.accelerationFactor = stepValue;
                directionChanged = true;
            } else {
                // Continue downtrend
                if (low < state.extremePoint) {
                    state.extremePoint = low;
                    state.accelerationFactor = std::min(state.accelerationFactor + stepValue, maxValue);
                }
            }
        }
        
        // Update continuous state
        if (directionChanged) {
            state.consecutiveCount = 0;
            state.isContinuous = false;
        } else {
            state.consecutiveCount++;
            state.isContinuous = state.consecutiveCount >= 3;
        }
        
        return state.currentSAR;
    }
};

class MovingAverage {
private:
    int period, shift;
    std::vector<double> values;
    
public:
    MovingAverage(int p, int s) : period(p), shift(s) {}
    
    double Calculate(const double& price) {
        values.push_back(price);
        if (values.size() > period) values.erase(values.begin());
        
        double sum = 0;
        for(const auto& v : values) sum += v;
        return sum / values.size();
    }
};

// Strategy implementation
static ParabolicSAR sar;
static MovingAverage* fastMA = nullptr;
static MovingAverage* slowMA = nullptr;

// DLL Exports implementation
DLL_EXPORT bool __stdcall InitStrategy() {
    if (state.isInitialized) return true;
    
    fastMA = new MovingAverage(state.params.fastMAPeriod, state.params.fastMAShift);
    slowMA = new MovingAverage(state.params.slowMAPeriod, state.params.slowMAShift);
    sar.Init(state.params.sarStep, state.params.sarMaximum);
    
    state.isInitialized = true;
    return true;
}

DLL_EXPORT void __stdcall DeinitStrategy() {
    delete fastMA;
    delete slowMA;
    state.isInitialized = false;
}

struct PriceData {
    double open;
    double high;
    double low;
    double close;
};

static std::vector<PriceData> priceHistory;

DLL_EXPORT bool __stdcall UpdateIndicators(
    const double open[], const double high[], 
    const double low[], const double close[], 
    const double volume[], int bars) {
    
    if (!state.isInitialized) return false;
    
    // Update price history
    priceHistory.resize(bars);
    for(int i = 0; i < bars; i++) {
        priceHistory[i].open = open[i];
        priceHistory[i].high = high[i];
        priceHistory[i].low = low[i];
        priceHistory[i].close = close[i];
    }
    
    // Update indicators
    state.sarValues.clear();
    state.fastMA.clear();
    state.slowMA.clear();
    
    for(int i = bars - 1; i >= 0; i--) {
        state.sarValues.push_back(
            sar.Calculate(
                priceHistory[i].high,
                priceHistory[i].low,
                priceHistory[i].open,
                priceHistory[i].close
            )
        );
        state.fastMA.push_back(fastMA->Calculate(close[i]));
        state.slowMA.push_back(slowMA->Calculate(close[i]));
    }
    
    return true;
}

DLL_EXPORT bool __stdcall CheckBuySignal() {
    if (!state.isInitialized || state.sarValues.empty() || priceHistory.empty()) 
        return false;
    
    SARState sarState = sar.GetState();
    
    // Check SAR conditions
    bool directionChange = sarState.direction == SAR_UP && 
                          !sarState.isContinuous;
    
    bool priceAboveSAR = priceHistory[0].close > state.sarValues[0];
    
    // Check MA crossover
    bool maCrossover = state.fastMA[1] < state.slowMA[1] && 
                      state.fastMA[0] > state.slowMA[0];
    
    return directionChange && priceAboveSAR && maCrossover;
}

DLL_EXPORT bool __stdcall CheckSellSignal() {
    if (!state.isInitialized || state.sarValues.empty() || priceHistory.empty()) 
        return false;
    
    SARState sarState = sar.GetState();
    
    // Check SAR conditions
    bool directionChange = sarState.direction == SAR_DOWN && 
                          !sarState.isContinuous;
    
    bool priceBelowSAR = priceHistory[0].close < state.sarValues[0];
    
    // Check MA crossover
    bool maCrossover = state.fastMA[1] > state.slowMA[1] && 
                      state.fastMA[0] < state.slowMA[0];
    
    return directionChange && priceBelowSAR && maCrossover;
}

DLL_EXPORT double __stdcall CalculateEntryPrice(bool isBuy) {
    if (!state.isInitialized || state.sarValues.empty() || priceHistory.empty()) 
        return 0;
    
    double currentClose = priceHistory[0].close;
    return isBuy ? currentClose + state.params.entryOffset 
                 : currentClose - state.params.entryOffset;
}

DLL_EXPORT double __stdcall CalculateStopLoss(bool isBuy, double entryPrice) {
    return isBuy ? entryPrice - state.params.baseSL 
                 : entryPrice + state.params.baseSL;
}

DLL_EXPORT double __stdcall CalculateTakeProfit(int orderIndex, bool isBuy, 
                                               double entryPrice, double stopLoss) {
    double rr = 2.0; // Default R:R ratio
    
    // Adjust R:R based on level and order index
    if(state.params.currentLevel >= 7) {
        switch(orderIndex) {
            case 0: rr = 3.0; break;
            case 1: rr = 7.0; break;
            case 2: rr = 7.0; break;
        }
    }
    
    double distance = fabs(entryPrice - stopLoss);
    return isBuy ? entryPrice + (distance * rr)
                 : entryPrice - (distance * rr);
}

DLL_EXPORT void __stdcall SetParameters(const GoldenCandleParams* params) {
    if(!params) return;
    state.params = *params;
    
    if(state.isInitialized) {
        sar.Init(params->sarStep, params->sarMaximum);
        delete fastMA;
        delete slowMA;
        fastMA = new MovingAverage(params->fastMAPeriod, params->fastMAShift);
        slowMA = new MovingAverage(params->slowMAPeriod, params->slowMAShift);
    }
}
