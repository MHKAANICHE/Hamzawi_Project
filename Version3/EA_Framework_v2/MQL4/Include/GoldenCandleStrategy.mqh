//+------------------------------------------------------------------+
//|                                       GoldenCandleStrategy.mqh |
//|                              Copyright 2025, Golden Candle Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle Team"
#property strict

#include "GoldenCandle.mqh"
#include "ReferenceLineManager.mqh"
#include "OrderManager.mqh"

//+------------------------------------------------------------------+
//| Strategy class integrating Golden Candle system                    |
//+------------------------------------------------------------------+
class CGoldenCandleStrategy {
private:
    string               m_symbol;
    ENUM_TIMEFRAMES     m_timeframe;
    
    // Components
    CGoldenCandle*      m_goldenCandle;
    CReferenceLineManager* m_refLineManager;
    COrderManager*      m_orderManager;
    
    // Strategy state
    double              m_lastSignalPrice;
    datetime            m_lastSignalTime;
    bool                m_isValidSetup;
    
    // Internal validation
    bool                ValidateMarketConditions();
    bool                ValidateSignalCandle(int shift);
    
public:
                        CGoldenCandleStrategy();
                       ~CGoldenCandleStrategy();
    
    // Initialization
    bool                Init(string symbol, ENUM_TIMEFRAMES tf);
    
    // Strategy operations
    bool                OnTick();
    bool                ProcessSignal(int shift);
    
    // Market entry
    bool                ValidateEntry(double price, bool isBuy);
    bool                ExecuteEntry(double price, bool isBuy);
    
    // State checks
    bool                IsValidSetup()  const { return m_isValidSetup; }
    datetime            LastSignalTime() const { return m_lastSignalTime; }
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CGoldenCandleStrategy::CGoldenCandleStrategy() {
    m_symbol = NULL;
    m_timeframe = PERIOD_CURRENT;
    m_goldenCandle = new CGoldenCandle();
    m_refLineManager = new CReferenceLineManager();
    m_orderManager = NULL;  // Will be set during Init
    m_lastSignalPrice = 0;
    m_lastSignalTime = 0;
    m_isValidSetup = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CGoldenCandleStrategy::~CGoldenCandleStrategy() {
    if(m_goldenCandle != NULL) {
        delete m_goldenCandle;
        m_goldenCandle = NULL;
    }
    if(m_refLineManager != NULL) {
        delete m_refLineManager;
        m_refLineManager = NULL;
    }
    // Don't delete m_orderManager, it's managed externally
}

//+------------------------------------------------------------------+
//| Initialize the strategy                                            |
//+------------------------------------------------------------------+
bool CGoldenCandleStrategy::Init(string symbol, ENUM_TIMEFRAMES tf) {
    if(symbol == "" || m_goldenCandle == NULL || m_refLineManager == NULL) 
        return false;
    
    m_symbol = symbol;
    m_timeframe = tf;
    
    // Initialize components
    if(!m_goldenCandle.Init(symbol)) {
        Print("Failed to initialize Golden Candle validator");
        return false;
    }
    
    if(!m_refLineManager.Init(symbol, m_goldenCandle)) {
        Print("Failed to initialize Reference Line Manager");
        return false;
    }
    
    m_isValidSetup = true;
    return true;
}

//+------------------------------------------------------------------+
//| Main tick processing                                              |
//+------------------------------------------------------------------+
bool CGoldenCandleStrategy::OnTick() {
    if(!m_isValidSetup) return false;
    
    // Check for new signals
    if(ProcessSignal(1)) {  // Check previous completed candle
        // Signal found, validate market conditions
        if(ValidateMarketConditions()) {
            // Update reference line
            double signalPrice = iClose(m_symbol, m_timeframe, 1);
            bool isBuy = true;  // Determine based on signal direction
            
            m_refLineManager.SetReferenceLine(signalPrice, isBuy);
            m_lastSignalPrice = signalPrice;
            m_lastSignalTime = iTime(m_symbol, m_timeframe, 1);
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Process potential signal candle                                    |
//+------------------------------------------------------------------+
bool CGoldenCandleStrategy::ProcessSignal(int shift) {
    if(!ValidateSignalCandle(shift)) return false;
    
    // Get candle data
    double open = iOpen(m_symbol, m_timeframe, shift);
    double high = iHigh(m_symbol, m_timeframe, shift);
    double low = iLow(m_symbol, m_timeframe, shift);
    double close = iClose(m_symbol, m_timeframe, shift);
    
    // Validate Golden Candle structure
    return m_goldenCandle.ValidateCandle(open, high, low, close);
}

//+------------------------------------------------------------------+
//| Validate current market conditions                                 |
//+------------------------------------------------------------------+
bool CGoldenCandleStrategy::ValidateMarketConditions() {
    if(m_orderManager != NULL && m_orderManager.HasOpenPositions())
        return false;
        
    // Add additional market condition checks here
    // - Spread validation
    // - Time of day
    // - Market volatility
    // etc.
    
    return true;
}

//+------------------------------------------------------------------+
//| Validate signal candle                                            |
//+------------------------------------------------------------------+
bool CGoldenCandleStrategy::ValidateSignalCandle(int shift) {
    if(shift <= 0) return false;
    
    datetime candleTime = iTime(m_symbol, m_timeframe, shift);
    if(candleTime <= m_lastSignalTime) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Validate entry conditions                                          |
//+------------------------------------------------------------------+
bool CGoldenCandleStrategy::ValidateEntry(double price, bool isBuy) {
    if(!m_isValidSetup || !m_goldenCandle || !m_refLineManager) 
        return false;
    
    // Get reference line price
    double refPrice = m_refLineManager.GetReferencePrice();
    if(refPrice == 0) return false;
    
    // Validate entry level
    return m_goldenCandle.ValidateEntryLevel(price, refPrice);
}

//+------------------------------------------------------------------+
//| Execute market entry                                              |
//+------------------------------------------------------------------+
bool CGoldenCandleStrategy::ExecuteEntry(double price, bool isBuy) {
    if(!ValidateEntry(price, isBuy) || m_orderManager == NULL)
        return false;
    
    // Calculate entry parameters
    double refPrice = m_refLineManager.GetReferencePrice();
    double baseSize = m_goldenCandle.GetBaseSize();
    
    // Set stop loss and take profit
    double stopLoss = isBuy ? refPrice - baseSize : refPrice + baseSize;
    double takeProfit = isBuy ? refPrice + baseSize * 2 : refPrice - baseSize * 2;
    
    // Open position
    return m_orderManager.OpenPosition(
        isBuy ? OP_BUY : OP_SELL,
        0.1,  // Base lot size
        price,
        stopLoss,
        takeProfit,
        LEVEL_1_MAIN
    );
}
