//+------------------------------------------------------------------+
//|                                            MoneyManager.mqh |
//|                              Copyright 2025, Golden Candle Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle Team"
#property strict

// Money Management Constants
#define BASE_LOT_SIZE     0.01
#define MAX_LOT_SIZE      0.18
#define MAX_LEVEL         25

// Level-based lot size progression
static double LotSizeProgression[] = {
    0.01,  // Levels 1-6
    0.02,  // Levels 7-10
    0.03,  // Levels 11-12
    0.04,  // Levels 13-14
    0.05,  // Levels 15-16
    0.06,  // Level 17
    0.07,  // Level 18
    0.08,  // Level 19
    0.09,  // Level 20
    0.10,  // Level 21
    0.12,  // Level 22
    0.14,  // Level 23
    0.16,  // Level 24
    0.18   // Level 25
};

// Risk:Reward ratios for first 6 levels
static double RiskRewardRatios[] = {
    2.0,   // Level 1
    3.0,   // Level 2
    4.0,   // Level 3
    5.0,   // Level 4
    6.0,   // Level 5
    7.0    // Level 6
};

//+------------------------------------------------------------------+
//| Money Management Class                                             |
//+------------------------------------------------------------------+
class CMoneyManager {
private:
    string         m_symbol;
    double         m_baseLot;
    double         m_maxRiskPercent;
    bool           m_initialized;
    
    // Internal calculations
    double         CalculatePositionValue(double lots, double distance);
    bool           ValidateLotSize(double lots);
    
public:
                   CMoneyManager();
                  ~CMoneyManager();
    
    // Initialization
    bool           Init(string symbol, double baseLot = BASE_LOT_SIZE,
                       double maxRisk = 2.0);
    
    // Lot size calculations
    double         GetLevelLotSize(int level);
    double         GetSplitLotSize(int level, int part);
    double         AdjustLotSize(double lots);
    
    // Risk calculations
    bool           ValidateRisk(double lots, double distance);
    double         CalculateMaxLots(double distance);
    
    // Level-based calculations
    double         GetLevelRiskReward(int level);
    int            GetSplitCount(int level);
    
    // Getters
    double         GetBaseLot()  const { return m_baseLot; }
    double         GetMaxLot()   const { return MAX_LOT_SIZE; }
    int            GetMaxLevel() const { return MAX_LEVEL; }
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CMoneyManager::CMoneyManager() {
    m_symbol = NULL;
    m_baseLot = BASE_LOT_SIZE;
    m_maxRiskPercent = 2.0;
    m_initialized = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CMoneyManager::~CMoneyManager() {
}

//+------------------------------------------------------------------+
//| Initialize Money Manager                                           |
//+------------------------------------------------------------------+
bool CMoneyManager::Init(string symbol, double baseLot = BASE_LOT_SIZE,
                        double maxRisk = 2.0) {
    if(symbol == "" || baseLot <= 0 || maxRisk <= 0) return false;
    
    m_symbol = symbol;
    m_baseLot = MathMin(baseLot, MAX_LOT_SIZE);
    m_maxRiskPercent = maxRisk;
    m_initialized = true;
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate position value                                           |
//+------------------------------------------------------------------+
double CMoneyManager::CalculatePositionValue(double lots, double distance) {
    if(!m_initialized || lots <= 0 || distance <= 0) return 0;
    
    double tickValue = MarketInfo(m_symbol, MODE_TICKVALUE);
    double tickSize = MarketInfo(m_symbol, MODE_TICKSIZE);
    
    return (distance / tickSize) * tickValue * lots;
}

//+------------------------------------------------------------------+
//| Validate lot size against broker limits                           |
//+------------------------------------------------------------------+
bool CMoneyManager::ValidateLotSize(double lots) {
    if(!m_initialized || lots <= 0) return false;
    
    double minLot = MarketInfo(m_symbol, MODE_MINLOT);
    double maxLot = MarketInfo(m_symbol, MODE_MAXLOT);
    double lotStep = MarketInfo(m_symbol, MODE_LOTSTEP);
    
    return lots >= minLot && lots <= maxLot &&
           MathAbs(MathMod(lots, lotStep)) < lotStep/2;
}

//+------------------------------------------------------------------+
//| Get lot size for level                                            |
//+------------------------------------------------------------------+
double CMoneyManager::GetLevelLotSize(int level) {
    if(!m_initialized || level <= 0 || level > MAX_LEVEL) 
        return m_baseLot;
    
    double lots;
    
    if(level <= 6) {
        lots = LotSizeProgression[0];
    }
    else if(level <= 10) {
        lots = LotSizeProgression[1];
    }
    else {
        int idx = (level - 9) / 2;  // Map to progression array
        lots = LotSizeProgression[MathMin(idx + 1, ArraySize(LotSizeProgression) - 1)];
    }
    
    return AdjustLotSize(lots);
}

//+------------------------------------------------------------------+
//| Get split lot size for level                                      |
//+------------------------------------------------------------------+
double CMoneyManager::GetSplitLotSize(int level, int part) {
    if(!m_initialized || level <= 6) return GetLevelLotSize(level);
    
    double totalLots = GetLevelLotSize(level);
    int splits = GetSplitCount(level);
    
    if(splits <= 1 || part <= 0 || part > splits) return totalLots;
    
    return AdjustLotSize(totalLots / splits);
}

//+------------------------------------------------------------------+
//| Adjust lot size to broker requirements                            |
//+------------------------------------------------------------------+
double CMoneyManager::AdjustLotSize(double lots) {
    if(!m_initialized) return m_baseLot;
    
    double lotStep = MarketInfo(m_symbol, MODE_LOTSTEP);
    lots = MathRound(lots / lotStep) * lotStep;
    
    if(!ValidateLotSize(lots)) return m_baseLot;
    
    return MathMin(lots, MAX_LOT_SIZE);
}

//+------------------------------------------------------------------+
//| Validate risk against account balance                             |
//+------------------------------------------------------------------+
bool CMoneyManager::ValidateRisk(double lots, double distance) {
    if(!m_initialized) return false;
    
    double positionValue = CalculatePositionValue(lots, distance);
    double accountBalance = AccountBalance();
    
    return (positionValue / accountBalance) * 100.0 <= m_maxRiskPercent;
}

//+------------------------------------------------------------------+
//| Calculate maximum allowed lots                                     |
//+------------------------------------------------------------------+
double CMoneyManager::CalculateMaxLots(double distance) {
    if(!m_initialized || distance <= 0) return m_baseLot;
    
    double accountBalance = AccountBalance();
    double maxRiskValue = accountBalance * m_maxRiskPercent / 100.0;
    
    double tickValue = MarketInfo(m_symbol, MODE_TICKVALUE);
    double tickSize = MarketInfo(m_symbol, MODE_TICKSIZE);
    
    double maxLots = maxRiskValue / ((distance / tickSize) * tickValue);
    return AdjustLotSize(MathMin(maxLots, MAX_LOT_SIZE));
}

//+------------------------------------------------------------------+
//| Get Risk:Reward ratio for level                                   |
//+------------------------------------------------------------------+
double CMoneyManager::GetLevelRiskReward(int level) {
    if(!m_initialized || level <= 0) return 2.0;  // Default 1:2
    
    if(level <= 6) {
        return RiskRewardRatios[level - 1];
    }
    
    // Progressive R:R for higher levels
    return 7.0 + (level - 6) * 0.5;  // Increases by 0.5 per level
}

//+------------------------------------------------------------------+
//| Get number of split orders for level                              |
//+------------------------------------------------------------------+
int CMoneyManager::GetSplitCount(int level) {
    if(!m_initialized || level <= 6) return 1;
    
    if(level <= 10) return 2;      // Split into 2
    if(level <= 14) return 3;      // Split into 3
    if(level <= 16) return 4;      // Split into 4
    return 5;                      // Split into 5 for higher levels
}
