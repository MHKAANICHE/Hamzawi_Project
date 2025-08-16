#include "include/GoldenCandleStrategy.h"
#include <string.h>
#include <math.h>

bool CGoldenCandleStrategy::Init() {
    m_isInitialized = true;
    return true;
}

void CGoldenCandleStrategy::Deinit() {
    if(m_rates) {
        delete[] m_rates;
        m_rates = NULL;
    }
    m_ratesCount = 0;
    m_isInitialized = false;
}

bool CGoldenCandleStrategy::UpdateRates(MqlRates* rates, int count) {
    if(!rates || count <= 0) return false;
    
    // Reallocate rates array if needed
    if(m_ratesCount != count) {
        if(m_rates) delete[] m_rates;
        m_rates = new MqlRates[count];
        m_ratesCount = count;
    }
    
    // Copy rates data
    memcpy(m_rates, rates, sizeof(MqlRates) * count);
    return true;
}

bool CGoldenCandleStrategy::CheckEntryConditions() {
    if(!m_isInitialized || !m_rates || m_ratesCount < 2) return false;
    
    int index = 1; // Check previous candle
    
    // Calculate candle properties
    double bodySize = fabs(m_rates[index].close - m_rates[index].open);
    double upperWick = m_rates[index].high - (m_rates[index].close > m_rates[index].open ? m_rates[index].close : m_rates[index].open);
    double lowerWick = (m_rates[index].close < m_rates[index].open ? m_rates[index].close : m_rates[index].open) - m_rates[index].low;
    double totalWick = upperWick + lowerWick;
    double candleSize = m_rates[index].high - m_rates[index].low;
    
    // Check candle size
    if(candleSize < m_params.minCandleSize || candleSize > m_params.maxCandleSize) {
        return false;
    }
    
    // Check body to wick ratio
    if(totalWick > 0 && bodySize / totalWick < m_params.bodyToWickRatio) {
        return false;
    }
    
    // Basic volume check
    if(m_rates[index].tick_volume < m_rates[index + 1].tick_volume * m_params.minVolumeMultiplier) {
        return false;
    }
    
    // Set current signal
    m_currentSignal.Clear();
    m_currentSignal.type = m_rates[index].close > m_rates[index].open ? SIGNAL_GOLDEN_CANDLE_BUY : SIGNAL_GOLDEN_CANDLE_SELL;
    m_currentSignal.time = m_rates[index].time;
    m_currentSignal.price = m_rates[index].close;
    m_currentSignal.entryPrice = m_currentSignal.price;
    m_currentSignal.stopLoss = m_rates[index].low - m_params.baseSL;
    m_currentSignal.takeProfit = m_currentSignal.price + (m_currentSignal.price - m_currentSignal.stopLoss) * 2; // 1:2 RR ratio
    m_currentSignal.lots = DEFAULT_LOT_SIZE;
    
    return true;
}

bool CGoldenCandleStrategy::CheckExitConditions() {
    if(!m_isInitialized || !m_rates || m_ratesCount < 2) return false;
    
    // Simple reversal exit strategy
    bool isBullish = m_rates[1].close > m_rates[1].open;
    bool wasBullish = m_rates[2].close > m_rates[2].open;
    
    return isBullish != wasBullish; // Exit on pattern reversal
}

double CGoldenCandleStrategy::GetEntryPrice(ENUM_ORDER_TYPE type) {
    if(!m_isInitialized || !m_rates || m_ratesCount < 1) return 0.0;
    
    return m_rates[0].close + (type == ORDER_TYPE_BUY ? m_params.entryOffset : -m_params.entryOffset);
}
