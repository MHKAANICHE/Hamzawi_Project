#include "StateManager.h"
#include <chrono>
#include <iomanip>
#include <sstream>

namespace GoldenCandle {

StateManager::StateManager() : m_initialized(false) {
    Reset();
}

StateManager::~StateManager() {
    // Cleanup if needed
}

void StateManager::Reset() {
    m_currentState = SystemState();
    m_currentState.tradingState = TradingState::Initializing;
    m_currentState.isBacktesting = false;
    m_currentState.isTradingEnabled = false;
    m_errorLog.clear();
    m_eventHandlers.clear();
}

bool StateManager::Initialize(const CoreConfig& config) {
    if (m_initialized) return true;
    
    Reset();
    m_currentState.currentSymbol = config.symbol;
    m_currentState.currentTimeframe = config.timeframe;
    m_currentState.isBacktesting = config.isBacktesting;
    m_currentState.tradingState = TradingState::Ready;
    
    m_initialized = true;
    
    // Fire initialization event
    EventData event{EventType::StateChanged, "System initialized", nullptr};
    FireEvent(event);
    
    return true;
}

std::string StateManager::GetTimestamp() const {
    auto now = std::chrono::system_clock::now();
    auto time = std::chrono::system_clock::to_time_t(now);
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
        now.time_since_epoch()) % 1000;
    
    std::stringstream ss;
    ss << std::put_time(std::localtime(&time), "%Y-%m-%d %H:%M:%S")
       << '.' << std::setfill('0') << std::setw(3) << ms.count();
    return ss.str();
}

void StateManager::LogError(const ErrorInfo& error) {
    m_errorLog.push_back(error);
    
    // Fire error event
    EventData event{
        EventType::ErrorOccurred,
        error.message,
        const_cast<ErrorInfo*>(&m_errorLog.back())
    };
    FireEvent(event);
    
    // Update system state for critical errors
    if (error.severity == ErrorSeverity::Critical) {
        SetTradingState(TradingState::Error);
    }
}

void StateManager::ReportError(const std::string& message,
                             ErrorSeverity severity,
                             const std::string& component,
                             int errorCode) {
    ErrorInfo error{
        message,
        severity,
        component,
        errorCode,
        GetTimestamp()
    };
    LogError(error);
}

bool StateManager::HasCriticalError() const {
    for (const auto& error : m_errorLog) {
        if (error.severity == ErrorSeverity::Critical) {
            return true;
        }
    }
    return false;
}

std::vector<ErrorInfo> StateManager::GetErrors(ErrorSeverity minSeverity) const {
    std::vector<ErrorInfo> filteredErrors;
    for (const auto& error : m_errorLog) {
        if (static_cast<int>(error.severity) >= static_cast<int>(minSeverity)) {
            filteredErrors.push_back(error);
        }
    }
    return filteredErrors;
}

void StateManager::ClearErrors() {
    m_errorLog.clear();
}

bool StateManager::SetTradingState(TradingState state) {
    if (!m_initialized) return false;
    
    // Validate state transitions
    if (m_currentState.tradingState == TradingState::Error && 
        state != TradingState::Initializing) {
        return false;
    }
    
    if (state != m_currentState.tradingState) {
        TradingState oldState = m_currentState.tradingState;
        m_currentState.tradingState = state;
        
        // Fire state change event
        std::stringstream ss;
        ss << "Trading state changed from " << static_cast<int>(oldState)
           << " to " << static_cast<int>(state);
        EventData event{EventType::StateChanged, ss.str(), nullptr};
        FireEvent(event);
    }
    
    return true;
}

TradingState StateManager::GetTradingState() const {
    return m_currentState.tradingState;
}

const SystemState& StateManager::GetCurrentState() const {
    return m_currentState;
}

void StateManager::UpdateSystemState(const SystemState& state) {
    m_currentState = state;
}

void StateManager::RegisterEventHandler(EventType type,
                                     std::function<void(const EventData&)> handler) {
    m_eventHandlers[type].push_back(handler);
}

void StateManager::UnregisterEventHandler(EventType type) {
    m_eventHandlers.erase(type);
}

void StateManager::FireEvent(const EventData& event) {
    auto it = m_eventHandlers.find(event.type);
    if (it != m_eventHandlers.end()) {
        for (const auto& handler : it->second) {
            handler(event);
        }
    }
}

bool StateManager::CanTrade() const {
    return m_initialized &&
           m_currentState.isTradingEnabled &&
           m_currentState.tradingState != TradingState::Error &&
           m_currentState.tradingState != TradingState::Suspended &&
           m_currentState.tradingState != TradingState::Initializing;
}

bool StateManager::CanPlaceOrder() const {
    return CanTrade() &&
           (m_currentState.tradingState == TradingState::Ready ||
            m_currentState.tradingState == TradingState::Trading);
}

void StateManager::UpdateMarketState(const MarketData& market) {
    if (!m_initialized) return;
    
    // Fire market update event
    EventData event{
        EventType::MarketUpdate,
        "Market data updated",
        const_cast<MarketData*>(&market)
    };
    FireEvent(event);
}

void StateManager::UpdateAccountState(double balance, double equity) {
    if (!m_initialized) return;
    
    m_currentState.accountBalance = balance;
    m_currentState.currentEquity = equity;
}

void StateManager::UpdatePositionState(int openPositions, int pendingOrders) {
    if (!m_initialized) return;
    
    m_currentState.openPositions = openPositions;
    m_currentState.pendingOrders = pendingOrders;
}

} // namespace GoldenCandle
