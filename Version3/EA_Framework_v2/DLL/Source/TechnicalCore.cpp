#include "TechnicalCore.h"
#include <cmath>
#include <algorithm>

namespace GoldenCandle {

TechnicalCore::TechnicalCore() : m_initialized(false) {
    // Initialize SAR state
    m_sarState.currentValue = 0.0;
    m_sarState.extremePoint = 0.0;
    m_sarState.acceleration = 0.0;
    m_sarState.isLong = true;
    m_sarState.isFirstTrend = true;
    
    // Initialize MA state
    m_maState.lastCalculated = 0;
}

TechnicalCore::~TechnicalCore() {
    // Cleanup if needed
}

bool TechnicalCore::Initialize(const CoreConfig& config) {
    if (m_initialized) return true;
    
    // Set default SAR settings
    m_sarSettings.step = 0.001;
    m_sarSettings.maximum = 0.2;
    m_sarSettings.initialStep = 0.02;
    
    // Set default MA settings
    m_maSettings.fastPeriod = 1;
    m_maSettings.fastShift = 0;
    m_maSettings.slowPeriod = 3;
    m_maSettings.slowShift = 1;
    m_maSettings.method = 1; // EMA
    
    m_initialized = true;
    return true;
}

void TechnicalCore::SetSARSettings(const SARSettings& settings) {
    m_sarSettings = settings;
}

void TechnicalCore::SetMASettings(const MASettings& settings) {
    m_maSettings = settings;
}

double TechnicalCore::CalculateSAR(const CandleData& candle) {
    if (m_sarState.isFirstTrend) {
        m_sarState.isFirstTrend = false;
        m_sarState.isLong = candle.close > candle.open;
        m_sarState.currentValue = m_sarState.isLong ? candle.low : candle.high;
        m_sarState.extremePoint = m_sarState.isLong ? candle.high : candle.low;
        m_sarState.acceleration = m_sarSettings.initialStep;
        return m_sarState.currentValue;
    }
    
    // Calculate new SAR value
    double newSAR = m_sarState.currentValue + 
                    m_sarState.acceleration * 
                    (m_sarState.extremePoint - m_sarState.currentValue);
    
    // Update extreme point
    if (m_sarState.isLong) {
        if (candle.high > m_sarState.extremePoint) {
            m_sarState.extremePoint = candle.high;
            m_sarState.acceleration = std::min(m_sarState.acceleration + 
                                             m_sarSettings.step,
                                             m_sarSettings.maximum);
        }
    } else {
        if (candle.low < m_sarState.extremePoint) {
            m_sarState.extremePoint = candle.low;
            m_sarState.acceleration = std::min(m_sarState.acceleration + 
                                             m_sarSettings.step,
                                             m_sarSettings.maximum);
        }
    }
    
    return newSAR;
}

double TechnicalCore::CalculateMA(const std::vector<double>& prices, 
                                int period, int shift, int method) {
    if (prices.size() < period + shift) return 0.0;
    
    double ma = 0.0;
    switch (method) {
        case 0: // Simple MA
            for (int i = shift; i < period + shift; i++) {
                ma += prices[prices.size() - 1 - i];
            }
            ma /= period;
            break;
            
        case 1: // Exponential MA
            double alpha = 2.0 / (period + 1.0);
            ma = prices[prices.size() - 1 - shift];
            for (int i = shift + 1; i < period + shift; i++) {
                ma = (prices[prices.size() - 1 - i] * alpha) + 
                     (ma * (1.0 - alpha));
            }
            break;
    }
    
    return ma;
}

bool TechnicalCore::UpdateIndicators(const MarketData& market) {
    if (!m_initialized) return false;
    
    // Update SAR
    double newSAR = CalculateSAR(market.currentCandle);
    
    // Check for SAR trend change
    bool oldTrend = m_sarState.isLong;
    if (oldTrend && newSAR > market.currentCandle.low) {
        m_sarState.isLong = false;
        m_sarState.extremePoint = market.currentCandle.low;
        m_sarState.acceleration = m_sarSettings.initialStep;
    } else if (!oldTrend && newSAR < market.currentCandle.high) {
        m_sarState.isLong = true;
        m_sarState.extremePoint = market.currentCandle.high;
        m_sarState.acceleration = m_sarSettings.initialStep;
    }
    
    m_sarState.currentValue = newSAR;
    
    // Update MA buffers
    std::vector<double> prices;
    for (const auto& candle : market.priceHistory) {
        prices.push_back(candle.close);
    }
    
    if (prices.size() >= std::max(m_maSettings.fastPeriod + m_maSettings.fastShift,
                                 m_maSettings.slowPeriod + m_maSettings.slowShift)) {
        double fastMA = CalculateMA(prices, m_maSettings.fastPeriod,
                                  m_maSettings.fastShift, m_maSettings.method);
        double slowMA = CalculateMA(prices, m_maSettings.slowPeriod,
                                  m_maSettings.slowShift, m_maSettings.method);
                                  
        m_maState.fastBuffer.push_back(fastMA);
        m_maState.slowBuffer.push_back(slowMA);
        
        // Keep buffer size manageable
        if (m_maState.fastBuffer.size() > 100) {
            m_maState.fastBuffer.erase(m_maState.fastBuffer.begin());
            m_maState.slowBuffer.erase(m_maState.slowBuffer.begin());
        }
    }
    
    return true;
}

bool TechnicalCore::CheckSARSignal(const MarketData& market, SignalInfo& signal) {
    if (!m_initialized) return false;
    
    signal.type = SignalType::None;
    
    // Check if SAR trend has changed
    if (m_sarState.isLong && market.currentCandle.close > m_sarState.currentValue) {
        signal.type = SignalType::Buy;
        signal.price = market.currentCandle.close;
        signal.confidence = 1.0;
    } else if (!m_sarState.isLong && 
               market.currentCandle.close < m_sarState.currentValue) {
        signal.type = SignalType::Sell;
        signal.price = market.currentCandle.close;
        signal.confidence = 1.0;
    }
    
    return true;
}

bool TechnicalCore::CheckMASignal(const MarketData& market, SignalInfo& signal) {
    if (!m_initialized || m_maState.fastBuffer.size() < 2 || 
        m_maState.slowBuffer.size() < 2) 
        return false;
    
    signal.type = SignalType::None;
    
    // Check for MA crossover
    bool currentCrossUp = m_maState.fastBuffer.back() > m_maState.slowBuffer.back();
    bool prevCrossUp = m_maState.fastBuffer[m_maState.fastBuffer.size()-2] > 
                      m_maState.slowBuffer[m_maState.slowBuffer.size()-2];
    
    if (currentCrossUp && !prevCrossUp) {
        signal.type = SignalType::Buy;
        signal.price = market.currentCandle.close;
        signal.confidence = 0.8;
    } else if (!currentCrossUp && prevCrossUp) {
        signal.type = SignalType::Sell;
        signal.price = market.currentCandle.close;
        signal.confidence = 0.8;
    }
    
    return true;
}

bool TechnicalCore::ValidateGoldenCandle(const CandleData& candle,
                                       double baseSize, double entryLevel) {
    if (!m_initialized) return false;
    
    // Calculate candle properties
    double bodySize = std::abs(candle.close - candle.open);
    double upperWick = candle.high - std::max(candle.open, candle.close);
    double lowerWick = std::min(candle.open, candle.close) - candle.low;
    
    // Golden Candle validation rules
    bool isValidBody = bodySize >= baseSize;
    bool isValidWicks = upperWick <= bodySize * 0.5 && 
                       lowerWick <= bodySize * 0.5;
    bool isValidTrend = (candle.close > candle.open && m_sarState.isLong) ||
                       (candle.close < candle.open && !m_sarState.isLong);
    
    return isValidBody && isValidWicks && isValidTrend;
}

bool TechnicalCore::ValidateEntryLevel(double price, double entryLevel) {
    return std::abs(price - entryLevel) <= entryLevel * 0.001; // 0.1% tolerance
}

} // namespace GoldenCandle
