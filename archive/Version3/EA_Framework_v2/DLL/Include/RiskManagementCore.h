#pragma once

#include <vector>
#include "MarketTypes.h"

namespace GoldenCandle {

//+------------------------------------------------------------------+
//| Risk Management Configuration                                       |
//+------------------------------------------------------------------+
struct RiskSettings {
    double maxDrawdown;      // Maximum drawdown percentage
    double dailyLossLimit;   // Maximum daily loss
    double marginMinimum;    // Minimum margin level
    int maxSpreadPoints;    // Maximum allowed spread
    double riskPercent;     // Risk percentage per trade
};

//+------------------------------------------------------------------+
//| Risk State Information                                             |
//+------------------------------------------------------------------+
struct RiskState {
    double currentDrawdown;
    double maxDrawdown;
    double dailyProfit;
    double marginLevel;
    bool isRiskExceeded;
    std::string lastError;
};

//+------------------------------------------------------------------+
//| Risk Management Core Class                                         |
//+------------------------------------------------------------------+
class RiskManagementCore {
private:
    RiskSettings m_settings;
    bool m_initialized;
    
    // Risk tracking
    double m_initialBalance;
    double m_dailyStartBalance;
    double m_worstDrawdown;
    
    // Daily tracking
    long m_lastCheckTime;
    std::vector<double> m_profitHistory;
    
    // Internal validation
    bool ValidateMarginLevel(double equity, double margin) const;
    bool ValidateDrawdown(double equity) const;
    bool ValidateDailyLoss(double currentBalance) const;
    bool ValidateSpread(const MarketData& market) const;
    
public:
    RiskManagementCore();
    ~RiskManagementCore();
    
    // Initialization
    bool Initialize(const CoreConfig& config);
    void SetSettings(const RiskSettings& settings);
    
    // Risk validation
    bool ValidateNewPosition(const EntryPoint& entry, 
                           const MarketData& market);
    bool ValidateAccountState(double balance, double equity, 
                            double margin);
    bool ValidateTradeConditions(const MarketData& market);
    
    // Risk tracking
    void UpdateState(double balance, double equity, double margin);
    void OnNewDay(double balance);
    
    // Risk metrics
    double GetCurrentDrawdown(double equity) const;
    double GetDailyProfit(double currentBalance) const;
    double GetMaxDrawdown() const { return m_worstDrawdown; }
    
    // State access
    void GetCurrentState(RiskState& state) const;
    bool IsInitialized() const { return m_initialized; }
};

} // namespace GoldenCandle
