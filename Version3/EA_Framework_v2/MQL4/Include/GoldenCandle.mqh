//+------------------------------------------------------------------+
//|                                               GoldenCandle.mqh |
//|                              Copyright 2025, Golden Candle Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle Team"
#property strict

// Golden Candle configuration constants
#define GC_BASE_SIZE           10000    // Base size in points
#define GC_ENTRY_LEVEL_PCT     35       // Entry level percentage
#define GC_ENTRY_LEVEL_POINTS  3500     // Entry level in points
#define GC_FIB_LEVELS_COUNT    5        // Number of Fibonacci levels

//+------------------------------------------------------------------+
//| Golden Candle validation and management class                      |
//+------------------------------------------------------------------+
class CGoldenCandle {
private:
    string   m_symbol;                  // Symbol being traded
    double   m_point;                   // Point value
    double   m_fibLevels[GC_FIB_LEVELS_COUNT];  // Fibonacci levels
    
    // Calculate Fibonacci levels for validation
    void     CalculateFibLevels(double basePrice);
    
    // Validate candle against Fibonacci levels
    bool     ValidateFibLevels(double high, double low);
    
public:
                     CGoldenCandle();
                    ~CGoldenCandle();
    
    // Initialization
    bool     Init(string symbol);
    
    // Validation methods
    bool     ValidateCandle(double open, double high, double low, double close);
    bool     ValidateEntryLevel(double price, double entryLevel);
    
    // Entry level calculations
    double   CalculateEntryLevel(double basePrice, bool isBuy);
    
    // Reference line management
    double   GetReferenceLinePrice(double signalPrice, bool isBuy);
    
    // Getters
    double   GetBaseSize()      const { return GC_BASE_SIZE * m_point; }
    double   GetEntryLevel()    const { return GC_ENTRY_LEVEL_POINTS * m_point; }
    double   GetEntryPercent()  const { return GC_ENTRY_LEVEL_PCT; }
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CGoldenCandle::CGoldenCandle() {
    m_symbol = NULL;
    m_point = 0;
    ArrayInitialize(m_fibLevels, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CGoldenCandle::~CGoldenCandle() {
}

//+------------------------------------------------------------------+
//| Initialize the Golden Candle validator                             |
//+------------------------------------------------------------------+
bool CGoldenCandle::Init(string symbol) {
    if(symbol == "") return false;
    
    m_symbol = symbol;
    m_point = MarketInfo(symbol, MODE_POINT);
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate Fibonacci levels for validation                          |
//+------------------------------------------------------------------+
void CGoldenCandle::CalculateFibLevels(double basePrice) {
    double baseSize = GetBaseSize();
    
    // Calculate standard Fibonacci ratios
    m_fibLevels[0] = basePrice;                    // 0%
    m_fibLevels[1] = basePrice + baseSize * 0.236; // 23.6%
    m_fibLevels[2] = basePrice + baseSize * 0.382; // 38.2%
    m_fibLevels[3] = basePrice + baseSize * 0.618; // 61.8%
    m_fibLevels[4] = basePrice + baseSize;         // 100%
}

//+------------------------------------------------------------------+
//| Validate candle against Fibonacci levels                           |
//+------------------------------------------------------------------+
bool CGoldenCandle::ValidateFibLevels(double high, double low) {
    double range = high - low;
    double baseSize = GetBaseSize();
    
    // Check if candle size is within acceptable range
    if(range < baseSize * 0.236 || range > baseSize * 1.618)
        return false;
    
    // Check distribution across Fibonacci levels
    int levelCount = 0;
    for(int i = 0; i < GC_FIB_LEVELS_COUNT - 1; i++) {
        if(high >= m_fibLevels[i] && low <= m_fibLevels[i+1])
            levelCount++;
    }
    
    // Must span at least 3 Fibonacci levels
    return levelCount >= 3;
}

//+------------------------------------------------------------------+
//| Validate entire candle structure                                   |
//+------------------------------------------------------------------+
bool CGoldenCandle::ValidateCandle(double open, double high, 
                                  double low, double close) {
    // Calculate base price (usually the open)
    double basePrice = open;
    
    // Calculate Fibonacci levels
    CalculateFibLevels(basePrice);
    
    // Validate candle size
    double size = high - low;
    if(size < GetBaseSize() * 0.8 || size > GetBaseSize() * 1.2)
        return false;
    
    // Check Fibonacci level distribution
    if(!ValidateFibLevels(high, low))
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Validate entry level against current price                         |
//+------------------------------------------------------------------+
bool CGoldenCandle::ValidateEntryLevel(double price, double entryLevel) {
    double diff = MathAbs(price - entryLevel);
    return diff <= GetEntryLevel() * 1.1; // 10% tolerance
}

//+------------------------------------------------------------------+
//| Calculate entry level based on base price                          |
//+------------------------------------------------------------------+
double CGoldenCandle::CalculateEntryLevel(double basePrice, bool isBuy) {
    double entryOffset = GetEntryLevel();
    return isBuy ? basePrice + entryOffset : basePrice - entryOffset;
}

//+------------------------------------------------------------------+
//| Get reference line price based on signal                           |
//+------------------------------------------------------------------+
double CGoldenCandle::GetReferenceLinePrice(double signalPrice, bool isBuy) {
    return CalculateEntryLevel(signalPrice, isBuy);
}
