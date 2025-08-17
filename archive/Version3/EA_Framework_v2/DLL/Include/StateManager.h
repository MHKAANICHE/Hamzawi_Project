#pragma once

#include <string>
#include <vector>
#include <map>
#include <functional>
#include "MarketTypes.h"

namespace GoldenCandle {

//+------------------------------------------------------------------+
//| Error and Event Types                                              |
//+------------------------------------------------------------------+
enum class ErrorSeverity {
    Info,
    Warning,
    Error,
    Critical
};

struct ErrorInfo {
    std::string message;
    ErrorSeverity severity;
    std::string component;
    int errorCode;
    std::string timestamp;
};

enum class EventType {
    MarketUpdate,
    SignalGenerated,
    OrderPlaced,
    OrderFilled,
    OrderCanceled,
    PositionClosed,
    StateChanged,
    ErrorOccurred
};

struct EventData {
    EventType type;
    std::string details;
    void* data;
};

//+------------------------------------------------------------------+
//| Trading State Types                                                |
//+------------------------------------------------------------------+
enum class TradingState {
    Initializing,
    Ready,
    Trading,
    WaitingSignal,
    OrderPending,
    PositionOpen,
    Suspended,
    Error
};

struct SystemState {
    TradingState tradingState;
    bool isBacktesting;
    bool isTradingEnabled;
    std::string currentSymbol;
    int currentTimeframe;
    double accountBalance;
    double currentEquity;
    int openPositions;
    int pendingOrders;
};

//+------------------------------------------------------------------+
//| State Manager Class                                                |
//+------------------------------------------------------------------+
class StateManager {
private:
    SystemState m_currentState;
    std::vector<ErrorInfo> m_errorLog;
    std::map<EventType, std::vector<std::function<void(const EventData&)>>> m_eventHandlers;
    bool m_initialized;
    
    // Internal methods
    void LogError(const ErrorInfo& error);
    void UpdateState(TradingState newState);
    std::string GetTimestamp() const;
    
public:
    StateManager();
    ~StateManager();
    
    // Initialization
    bool Initialize(const CoreConfig& config);
    void Reset();
    
    // State Management
    bool SetTradingState(TradingState state);
    TradingState GetTradingState() const;
    const SystemState& GetCurrentState() const;
    void UpdateSystemState(const SystemState& state);
    
    // Error Handling
    void ReportError(const std::string& message, 
                    ErrorSeverity severity,
                    const std::string& component,
                    int errorCode = 0);
    bool HasCriticalError() const;
    std::vector<ErrorInfo> GetErrors(ErrorSeverity minSeverity = ErrorSeverity::Info) const;
    void ClearErrors();
    
    // Event System
    void RegisterEventHandler(EventType type, 
                            std::function<void(const EventData&)> handler);
    void UnregisterEventHandler(EventType type);
    void FireEvent(const EventData& event);
    
    // State Validation
    bool CanTrade() const;
    bool CanPlaceOrder() const;
    bool IsInitialized() const { return m_initialized; }
    
    // Market State
    void UpdateMarketState(const MarketData& market);
    void UpdateAccountState(double balance, double equity);
    void UpdatePositionState(int openPositions, int pendingOrders);
};

} // namespace GoldenCandle
