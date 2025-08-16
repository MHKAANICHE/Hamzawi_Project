//+------------------------------------------------------------------+
//|                                                   SignalManager.mqh |
//|                                     Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"
#property strict

#include "../Base/Constants.mqh"
#include "../Base/Enums.mqh"
#include "../Base/Structures.mqh"

//+------------------------------------------------------------------+
//| Signal Manager Class                                               |
//+------------------------------------------------------------------+
class CSignalManager {
private:
    SSignal           m_currentSignal;     // Current active signal
    SSignal           m_lastSignal;        // Last generated signal
    SIndicatorState   m_indicatorState;    // Current indicator states
    bool              m_isInitialized;     // Initialization flag
    
    // Indicator handles
    int               m_maHandle;          // Moving Average handle
    int               m_rsiHandle;         // RSI handle
    int               m_stochHandle;       // Stochastic handle
    
    // Private methods
    bool              ValidateSignal(SSignal &signal);
    void              UpdateIndicatorStates();
    double            CalculateSignalStrength(SSignal &signal);
    bool              CheckSignalConflict(SSignal &signal);
    void              ClearIndicatorHandles();
    
public:
                      CSignalManager();
                     ~CSignalManager();
    
    // Initialization methods
    bool              Init(string symbol, ENUM_TIMEFRAMES timeframe);
    void              Deinit();
    
    // Signal generation and management
    bool              UpdateSignals();
    SSignal*          GetCurrentSignal()   { return &m_currentSignal; }
    SSignal*          GetLastSignal()      { return &m_lastSignal; }
    bool              HasActiveSignal()     { return m_currentSignal.isValid; }
    
    // Signal validation
    bool              IsSignalValid(SSignal &signal);
    double            GetSignalReliability(SSignal &signal);
    string            GetSignalDescription(SSignal &signal);
    
    // Indicator state management
    bool              UpdateIndicators();
    SIndicatorState*  GetIndicatorState()  { return &m_indicatorState; }
    
    // Market analysis
    ENUM_MARKET_CONDITION AnalyzeMarketCondition();
    double            GetMarketVolatility();
    bool              IsTrendStrong();
    
    // Configuration
    void              SetIndicatorParameters(int maPeriod, int rsiPeriod, int stochPeriod);
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CSignalManager::CSignalManager() {
    m_isInitialized = false;
    m_maHandle = INVALID_HANDLE;
    m_rsiHandle = INVALID_HANDLE;
    m_stochHandle = INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CSignalManager::~CSignalManager() {
    Deinit();
}

//+------------------------------------------------------------------+
//| Initialize the Signal Manager                                      |
//+------------------------------------------------------------------+
bool CSignalManager::Init(string symbol, ENUM_TIMEFRAMES timeframe) {
    if(m_isInitialized) return true;
    
    // Initialize indicator handles
    m_maHandle = iMA(symbol, timeframe, 20, 0, MODE_EMA, PRICE_CLOSE);
    m_rsiHandle = iRSI(symbol, timeframe, 14, PRICE_CLOSE);
    m_stochHandle = iStochastic(symbol, timeframe, 5, 3, 3, MODE_SMA, 0);
    
    // Validate indicator handles
    if(m_maHandle == INVALID_HANDLE || 
       m_rsiHandle == INVALID_HANDLE || 
       m_stochHandle == INVALID_HANDLE) {
        Print("Failed to initialize indicators");
        return false;
    }
    
    m_isInitialized = true;
    return true;
}

//+------------------------------------------------------------------+
//| Deinitialize the Signal Manager                                    |
//+------------------------------------------------------------------+
void CSignalManager::Deinit() {
    ClearIndicatorHandles();
    m_isInitialized = false;
}

//+------------------------------------------------------------------+
//| Update all signals                                                |
//+------------------------------------------------------------------+
bool CSignalManager::UpdateSignals() {
    if(!m_isInitialized) return false;
    
    // Store last signal
    m_lastSignal = m_currentSignal;
    
    // Update indicator states
    UpdateIndicatorStates();
    
    // Create new signal
    SSignal newSignal;
    newSignal.timestamp = TimeCurrent();
    
    // Check for buy conditions
    if(m_indicatorState.rsiValue < 30 && 
       m_indicatorState.stochMainValue < 20 &&
       m_indicatorState.maDirection == DIRECTION_UP) {
        newSignal.type = SIGNAL_BUY;
        newSignal.strength = CalculateSignalStrength(newSignal);
    }
    // Check for sell conditions
    else if(m_indicatorState.rsiValue > 70 && 
            m_indicatorState.stochMainValue > 80 &&
            m_indicatorState.maDirection == DIRECTION_DOWN) {
        newSignal.type = SIGNAL_SELL;
        newSignal.strength = CalculateSignalStrength(newSignal);
    }
    
    // Validate and set new signal
    if(ValidateSignal(newSignal)) {
        m_currentSignal = newSignal;
        m_currentSignal.isValid = true;
        return true;
    }
    
    m_currentSignal.Clear();
    return false;
}

//+------------------------------------------------------------------+
//| Update indicator states                                           |
//+------------------------------------------------------------------+
void CSignalManager::UpdateIndicatorStates() {
    double maValues[];
    ArraySetAsSeries(maValues, true);
    CopyBuffer(m_maHandle, 0, 0, 3, maValues);
    
    double rsiValues[];
    ArraySetAsSeries(rsiValues, true);
    CopyBuffer(m_rsiHandle, 0, 0, 1, rsiValues);
    
    double stochValues[];
    ArraySetAsSeries(stochValues, true);
    CopyBuffer(m_stochHandle, 0, 0, 1, stochValues);
    
    // Update MA direction
    m_indicatorState.maDirection = (maValues[0] > maValues[1]) ? DIRECTION_UP : DIRECTION_DOWN;
    m_indicatorState.rsiValue = rsiValues[0];
    m_indicatorState.stochMainValue = stochValues[0];
}

//+------------------------------------------------------------------+
//| Calculate signal strength                                         |
//+------------------------------------------------------------------+
double CSignalManager::CalculateSignalStrength(SSignal &signal) {
    double strength = 0;
    
    // RSI contribution
    if(signal.type == SIGNAL_BUY) {
        strength += (30 - m_indicatorState.rsiValue) / 30.0;
    } else if(signal.type == SIGNAL_SELL) {
        strength += (m_indicatorState.rsiValue - 70) / 30.0;
    }
    
    // Stochastic contribution
    if(signal.type == SIGNAL_BUY) {
        strength += (20 - m_indicatorState.stochMainValue) / 20.0;
    } else if(signal.type == SIGNAL_SELL) {
        strength += (m_indicatorState.stochMainValue - 80) / 20.0;
    }
    
    // MA trend alignment
    if((signal.type == SIGNAL_BUY && m_indicatorState.maDirection == DIRECTION_UP) ||
       (signal.type == SIGNAL_SELL && m_indicatorState.maDirection == DIRECTION_DOWN)) {
        strength *= 1.2; // 20% boost for trend alignment
    }
    
    return MathMin(strength, 1.0);
}

//+------------------------------------------------------------------+
//| Validate a signal                                                 |
//+------------------------------------------------------------------+
bool CSignalManager::ValidateSignal(SSignal &signal) {
    if(signal.type == SIGNAL_NONE) return false;
    if(signal.strength < MIN_SIGNAL_STRENGTH) return false;
    if(CheckSignalConflict(signal)) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Check for signal conflicts                                        |
//+------------------------------------------------------------------+
bool CSignalManager::CheckSignalConflict(SSignal &signal) {
    // Check if new signal contradicts recent signal
    if(m_lastSignal.isValid && 
       TimeCurrent() - m_lastSignal.timestamp < MIN_SIGNAL_INTERVAL) {
        if(signal.type != m_lastSignal.type) return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Clear indicator handles                                           |
//+------------------------------------------------------------------+
void CSignalManager::ClearIndicatorHandles() {
    if(m_maHandle != INVALID_HANDLE) {
        IndicatorRelease(m_maHandle);
        m_maHandle = INVALID_HANDLE;
    }
    if(m_rsiHandle != INVALID_HANDLE) {
        IndicatorRelease(m_rsiHandle);
        m_rsiHandle = INVALID_HANDLE;
    }
    if(m_stochHandle != INVALID_HANDLE) {
        IndicatorRelease(m_stochHandle);
        m_stochHandle = INVALID_HANDLE;
    }
}
