#pragma once

#include <string>
#include <vector>
#include "MarketTypes.h"

namespace GoldenCandle {

// Forward declarations
class MoneyManagementCore;
class RiskManagementCore;
class PositionManagerCore;

//+------------------------------------------------------------------+
//| Core trading logic class                                           |
//+------------------------------------------------------------------+
class GoldenCandleCore {
private:
    // Dependencies
    MoneyManagementCore* m_moneyManager;
    RiskManagementCore* m_riskManager;
    PositionManagerCore* m_positionManager;

    // State tracking
    double m_lastSARValue;
    double m_lastMAFast;
    double m_lastMASlow;
    bool m_isValidSetup;
    
    // Configuration
    double m_sarStep;
    double m_sarMaximum;
    int m_maFastPeriod;
    int m_maSlowPeriod;
    
    // Internal validation
    bool ValidateGoldenCandle(const CandleData& candle) const;
    bool ValidateEntryConditions(const MarketData& market) const;
    
public:
    GoldenCandleCore();
    ~GoldenCandleCore();
    
    // Initialization
    bool Initialize(const CoreConfig& config);
    
    // Market analysis
    bool UpdateMarketState(const MarketData& market);
    bool CheckSARSignal(const MarketData& market, SignalInfo& signal);
    bool CheckMASignal(const MarketData& market, SignalInfo& signal);
    
    // Entry management
    bool ValidateEntry(const MarketData& market, const EntryPoint& entry);
    bool CalculateEntryLevels(const MarketData& market, 
                             std::vector<EntryLevel>& levels);
    
    // Position management
    bool OpenPosition(const EntryPoint& entry);
    bool UpdatePositions(const MarketData& market);
    bool ClosePosition(int ticket);
    
    // Risk management
    bool ValidateRisk(const EntryPoint& entry);
    double CalculateOptimalLotSize(const EntryPoint& entry);
    
    // State access
    bool IsValidSetup() const { return m_isValidSetup; }
    void GetCurrentState(CoreState& state) const;
};

} // namespace GoldenCandle
