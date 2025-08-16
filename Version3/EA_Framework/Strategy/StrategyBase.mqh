//+------------------------------------------------------------------+
//|                                                   StrategyBase.mqh |
//|                                     Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"
#property strict

#include "../Base/Constants.mqh"
#include "../Base/Enums.mqh"
#include "../Base/Structures.mqh"
#include "../Technical/SignalManager.mqh"
#include "../Technical/MoneyManager.mqh"

//+------------------------------------------------------------------+
//| Strategy Base Class                                                |
//+------------------------------------------------------------------+
class CStrategyBase {
protected:
    // Core properties
    string            m_symbol;
    ENUM_TIMEFRAMES   m_timeframe;
    bool              m_isInitialized;
    
    // Strategy parameters
    SStrategyParams   m_params;
    string           m_strategyName;
    bool             m_isOptimizing;
    
    // Dependencies
    CSignalManager*   m_signalManager;
    CMoneyManager*    m_moneyManager;
    
    // Market data
    MqlRates         m_rates[];
    double           m_ma[];
    double           m_rsi[];
    double           m_atr[];
    
    // Indicator handles
    int              m_maHandle;
    int              m_rsiHandle;
    int              m_atrHandle;
    
    // Protected methods
    virtual bool      InitIndicators();
    virtual void     DeinitIndicators();
    virtual bool     LoadOptimizedParameters();
    virtual bool     SaveOptimizedParameters();
    bool             ValidateParameters();
    double           CalculateStopLoss(ENUM_ORDER_TYPE type);
    double           CalculateTakeProfit(ENUM_ORDER_TYPE type, double entry, double stopLoss);
    bool             UpdateMarketData();
    
public:
                     CStrategyBase();
    virtual         ~CStrategyBase();
    
    // Initialization
    virtual bool     Init(string symbol, ENUM_TIMEFRAMES timeframe,
                         CSignalManager* signalManager, CMoneyManager* moneyManager);
    virtual void     Deinit();
    
    // Strategy interface - must be implemented by derived classes
    virtual bool     Validate() = 0;                     // Validate strategy conditions
    virtual bool     CheckEntryConditions() = 0;         // Check entry conditions
    virtual bool     CheckExitConditions() = 0;          // Check exit conditions
    virtual double   GetEntryPrice(ENUM_ORDER_TYPE type) = 0;  // Get entry price
    
    // Common strategy methods
    virtual void     OnTick();
    virtual void     OnTimer();
    virtual double   GetLotSize(double stopLoss);
    virtual bool     IsTradeAllowed();
    
    // Signal processing
    virtual bool     ProcessSignals();
    virtual bool     ValidateSignal(SSignal &signal);
    virtual double   GetSignalStrength(SSignal &signal);
    
    // Parameter management
    virtual void     SetParameters(SStrategyParams &params);
    virtual bool     OptimizeParameters();
    
    // Getters
    string           GetStrategyName()    { return m_strategyName; }
    SStrategyParams* GetParameters()      { return &m_params; }
    bool             IsOptimizing()       { return m_isOptimizing; }
    string           GetSymbol()          { return m_symbol; }
    ENUM_TIMEFRAMES  GetTimeframe()       { return m_timeframe; }
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CStrategyBase::CStrategyBase() {
    m_isInitialized = false;
    m_isOptimizing = false;
    m_strategyName = "BaseStrategy";
    
    m_maHandle = INVALID_HANDLE;
    m_rsiHandle = INVALID_HANDLE;
    m_atrHandle = INVALID_HANDLE;
    
    ArraySetAsSeries(m_rates, true);
    ArraySetAsSeries(m_ma, true);
    ArraySetAsSeries(m_rsi, true);
    ArraySetAsSeries(m_atr, true);
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CStrategyBase::~CStrategyBase() {
    Deinit();
}

//+------------------------------------------------------------------+
//| Initialize the strategy                                            |
//+------------------------------------------------------------------+
bool CStrategyBase::Init(string symbol, ENUM_TIMEFRAMES timeframe,
                        CSignalManager* signalManager, CMoneyManager* moneyManager) {
    if(m_isInitialized) return true;
    
    if(symbol == NULL || symbol == "") {
        Print("Invalid symbol provided");
        return false;
    }
    
    if(signalManager == NULL || moneyManager == NULL) {
        Print("Signal Manager and Money Manager are required");
        return false;
    }
    
    m_symbol = symbol;
    m_timeframe = timeframe;
    m_signalManager = signalManager;
    m_moneyManager = moneyManager;
    
    if(!InitIndicators()) {
        Print("Failed to initialize indicators");
        return false;
    }
    
    if(!LoadOptimizedParameters()) {
        m_params.SetDefaults();
    }
    
    if(!ValidateParameters()) {
        return false;
    }
    
    m_isInitialized = true;
    return true;
}

//+------------------------------------------------------------------+
//| Deinitialize the strategy                                         |
//+------------------------------------------------------------------+
void CStrategyBase::Deinit() {
    if(m_isInitialized) {
        DeinitIndicators();
        if(m_isOptimizing) {
            SaveOptimizedParameters();
        }
    }
    m_isInitialized = false;
}

//+------------------------------------------------------------------+
//| Initialize strategy indicators                                     |
//+------------------------------------------------------------------+
bool CStrategyBase::InitIndicators() {
    // Initialize base indicators
    m_maHandle = iMA(m_symbol, m_timeframe, m_params.maPeriod, 0, MODE_EMA, PRICE_CLOSE);
    m_rsiHandle = iRSI(m_symbol, m_timeframe, m_params.rsiPeriod, PRICE_CLOSE);
    m_atrHandle = iATR(m_symbol, m_timeframe, m_params.atrPeriod);
    
    return m_maHandle != INVALID_HANDLE && 
           m_rsiHandle != INVALID_HANDLE && 
           m_atrHandle != INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| Deinitialize strategy indicators                                   |
//+------------------------------------------------------------------+
void CStrategyBase::DeinitIndicators() {
    if(m_maHandle != INVALID_HANDLE) IndicatorRelease(m_maHandle);
    if(m_rsiHandle != INVALID_HANDLE) IndicatorRelease(m_rsiHandle);
    if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
}

//+------------------------------------------------------------------+
//| Update market data                                                |
//+------------------------------------------------------------------+
bool CStrategyBase::UpdateMarketData() {
    // Update price data
    if(CopyRates(m_symbol, m_timeframe, 0, 100, m_rates) <= 0) return false;
    
    // Update indicator data
    if(CopyBuffer(m_maHandle, 0, 0, 100, m_ma) <= 0) return false;
    if(CopyBuffer(m_rsiHandle, 0, 0, 100, m_rsi) <= 0) return false;
    if(CopyBuffer(m_atrHandle, 0, 0, 100, m_atr) <= 0) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Process strategy signals                                           |
//+------------------------------------------------------------------+
bool CStrategyBase::ProcessSignals() {
    if(!m_isInitialized || !UpdateMarketData()) return false;
    
    // Get current signal
    SSignal* signal = m_signalManager.GetCurrentSignal();
    if(signal == NULL) return false;
    
    // Validate signal
    if(!ValidateSignal(signal)) return false;
    
    // Calculate signal strength
    signal.strength = GetSignalStrength(signal);
    
    return true;
}

//+------------------------------------------------------------------+
//| Validate a trading signal                                         |
//+------------------------------------------------------------------+
bool CStrategyBase::ValidateSignal(SSignal &signal) {
    if(signal.type == SIGNAL_NONE) return false;
    
    // Check signal age
    if(TimeCurrent() - signal.timestamp > m_params.maxSignalAge) {
        return false;
    }
    
    // Check signal strength
    if(signal.strength < m_params.minSignalStrength) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate signal strength                                         |
//+------------------------------------------------------------------+
double CStrategyBase::GetSignalStrength(SSignal &signal) {
    double strength = 0;
    
    // Trend alignment
    if((signal.type == SIGNAL_BUY && m_ma[0] > m_ma[1]) ||
       (signal.type == SIGNAL_SELL && m_ma[0] < m_ma[1])) {
        strength += 0.3;  // 30% for trend alignment
    }
    
    // RSI confirmation
    if((signal.type == SIGNAL_BUY && m_rsi[0] < 30) ||
       (signal.type == SIGNAL_SELL && m_rsi[0] > 70)) {
        strength += 0.3;  // 30% for RSI confirmation
    }
    
    // Volatility check
    double avgATR = 0;
    for(int i = 0; i < 10; i++) {
        avgATR += m_atr[i];
    }
    avgATR /= 10;
    
    if(m_atr[0] < avgATR) {
        strength += 0.2;  // 20% for normal volatility
    }
    
    // Volume confirmation
    if(m_rates[0].tick_volume > m_rates[1].tick_volume) {
        strength += 0.2;  // 20% for volume confirmation
    }
    
    return MathMin(strength, 1.0);
}

//+------------------------------------------------------------------+
//| Calculate stop loss level                                         |
//+------------------------------------------------------------------+
double CStrategyBase::CalculateStopLoss(ENUM_ORDER_TYPE type) {
    double atr = m_atr[0];
    double stopDistance = atr * m_params.stopLossATRMultiplier;
    
    return (type == ORDER_TYPE_BUY) ? 
           MarketInfo(m_symbol, MODE_BID) - stopDistance :
           MarketInfo(m_symbol, MODE_ASK) + stopDistance;
}

//+------------------------------------------------------------------+
//| Calculate take profit level                                       |
//+------------------------------------------------------------------+
double CStrategyBase::CalculateTakeProfit(ENUM_ORDER_TYPE type, double entry, double stopLoss) {
    double stopDistance = MathAbs(entry - stopLoss);
    double tpDistance = stopDistance * m_params.takeProfitRatio;
    
    return (type == ORDER_TYPE_BUY) ? 
           entry + tpDistance :
           entry - tpDistance;
}

//+------------------------------------------------------------------+
//| Get position size based on risk                                   |
//+------------------------------------------------------------------+
double CStrategyBase::GetLotSize(double stopLoss) {
    return m_moneyManager.CalculatePositionSize(m_symbol, stopLoss);
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                       |
//+------------------------------------------------------------------+
bool CStrategyBase::IsTradeAllowed() {
    if(!m_isInitialized) return false;
    
    // Check spread
    double spread = MarketInfo(m_symbol, MODE_SPREAD) * MarketInfo(m_symbol, MODE_POINT);
    if(spread > m_params.maxSpread) return false;
    
    // Check volatility
    if(m_atr[0] > m_params.maxVolatility) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Set strategy parameters                                           |
//+------------------------------------------------------------------+
void CStrategyBase::SetParameters(SStrategyParams &params) {
    m_params = params;
    if(m_isInitialized) {
        DeinitIndicators();
        InitIndicators();
    }
}

//+------------------------------------------------------------------+
//| Validate strategy parameters                                       |
//+------------------------------------------------------------------+
bool CStrategyBase::ValidateParameters() {
    if(m_params.maPeriod <= 0) return false;
    if(m_params.rsiPeriod <= 0) return false;
    if(m_params.atrPeriod <= 0) return false;
    if(m_params.stopLossATRMultiplier <= 0) return false;
    if(m_params.takeProfitRatio <= 0) return false;
    if(m_params.maxSpread <= 0) return false;
    if(m_params.maxVolatility <= 0) return false;
    if(m_params.minSignalStrength <= 0 || m_params.minSignalStrength > 1) return false;
    if(m_params.maxSignalAge <= 0) return false;
    
    return true;
}
