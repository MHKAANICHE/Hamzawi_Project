#pragma once

#include <vector>
#include "MarketTypes.h"

namespace GoldenCandle {

//+------------------------------------------------------------------+
//| Money Management Configuration                                      |
//+------------------------------------------------------------------+
struct MoneySettings {
    double baseLot;          // Base lot size (0.01)
    double maxLot;           // Maximum lot size (0.18)
    double riskPercent;      // Risk percentage per trade
    int maxLevel;           // Maximum trading level (25)
    double accountMinimum;   // Minimum account balance
};

//+------------------------------------------------------------------+
//| Money Management Core Class                                        |
//+------------------------------------------------------------------+
class MoneyManagementCore {
private:
    MoneySettings m_settings;
    bool m_initialized;
    
    // Level tracking
    int m_currentLevel;
    std::vector<double> m_lotProgression;
    std::vector<double> m_rrRatios;
    
    // Internal calculations
    double CalculatePositionValue(double lots, double distance, 
                                const MarketData& market) const;
    bool ValidateLotSize(double lots, const MarketData& market) const;
    
    // Level management
    void InitializeLotProgression();
    void InitializeRiskRewardRatios();
    
public:
    MoneyManagementCore();
    ~MoneyManagementCore();
    
    // Initialization
    bool Initialize(const CoreConfig& config);
    void SetSettings(const MoneySettings& settings);
    
    // Position sizing
    double GetLevelLotSize(int level) const;
    double GetSplitLotSize(int level, int part) const;
    double CalculateOptimalLotSize(const EntryPoint& entry) const;
    
    // Risk calculations
    bool ValidatePositionSize(const EntryPoint& entry, 
                            const MarketData& market) const;
    double GetMaximumLotSize(double distance, 
                            const MarketData& market) const;
    
    // Level management
    bool AdvanceLevel();
    void ResetLevel();
    double GetLevelRiskReward(int level) const;
    int GetSplitCount(int level) const;
    
    // State access
    int GetCurrentLevel() const { return m_currentLevel; }
    bool IsInitialized() const { return m_initialized; }
};

} // namespace GoldenCandle
