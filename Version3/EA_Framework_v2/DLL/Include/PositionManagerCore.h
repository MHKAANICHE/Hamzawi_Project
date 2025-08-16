#pragma once

#include <vector>
#include "MarketTypes.h"

namespace GoldenCandle {

//+------------------------------------------------------------------+
//| Position Information Structure                                      |
//+------------------------------------------------------------------+
struct PositionInfo {
    int ticket;
    int type;
    double lots;
    double openPrice;
    double stopLoss;
    double takeProfit;
    int qualification;
    long openTime;
    bool isComplete;
    bool isProfit;
};

//+------------------------------------------------------------------+
//| Position Manager Configuration                                      |
//+------------------------------------------------------------------+
struct PositionSettings {
    int maxPositions;       // Maximum simultaneous positions
    int slippage;          // Maximum allowed slippage
    bool allowHedging;     // Allow hedge positions
    int magicNumber;       // EA identifier
};

//+------------------------------------------------------------------+
//| Position Manager Core Class                                         |
//+------------------------------------------------------------------+
class PositionManagerCore {
private:
    PositionSettings m_settings;
    bool m_initialized;
    
    // Position tracking
    std::vector<PositionInfo> m_positions;
    int m_activePositions;
    int m_currentLevel;
    
    // Internal validation
    bool ValidateNewPosition(const EntryPoint& entry, 
                           const MarketData& market) const;
    bool UpdatePositionState(PositionInfo& pos, 
                           const MarketData& market);
    
public:
    PositionManagerCore();
    ~PositionManagerCore();
    
    // Initialization
    bool Initialize(const CoreConfig& config);
    void SetSettings(const PositionSettings& settings);
    
    // Position operations
    int OpenPosition(const EntryPoint& entry, 
                    const MarketData& market);
    bool ModifyPosition(int ticket, double sl, double tp);
    bool ClosePosition(int ticket);
    bool CloseAllPositions();
    
    // Position updates
    void UpdatePositions(const MarketData& market);
    bool IsPositionComplete(int ticket) const;
    
    // Level management
    bool CanAdvanceLevel() const;
    bool AdvanceLevel();
    void ResetLevel();
    
    // Status checks
    bool HasOpenPositions() const { return m_activePositions > 0; }
    int GetCurrentLevel() const { return m_currentLevel; }
    double GetTotalProfit() const;
    
    // Position access
    bool GetPosition(int ticket, PositionInfo& pos) const;
    void GetAllPositions(std::vector<PositionInfo>& positions) const;
    bool IsInitialized() const { return m_initialized; }
};

} // namespace GoldenCandle
