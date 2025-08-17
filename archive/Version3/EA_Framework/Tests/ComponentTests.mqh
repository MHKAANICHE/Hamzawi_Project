//+------------------------------------------------------------------+
//|                                              ComponentTests.mqh |
//|                                     Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"
#property strict



#include "../Base/StateManager.mqh"
#include "../Technical/SignalManager.mqh"
#include "../Technical/TradeManager.mqh"
#include "../Technical/MoneyManager.mqh"
#include "../Strategy/GoldenCandleStrategy.mqh"
#include "../Tests/TestFramework.mqh"


//+------------------------------------------------------------------+
//| Component Test Class                                               |
//+------------------------------------------------------------------+
class CComponentTests {
private:
    CTestFramework*   m_framework;
    
    // Test components
    CStateManager*    m_stateManager;
    CSignalManager*   m_signalManager;
    CTradeManager*    m_tradeManager;
    CMoneyManager*    m_moneyManager;
    CGoldenCandleStrategy* m_strategy;
    
    // Private test methods
    void             TestStateManager();
    void             TestSignalManager();
    void             TestTradeManager();
    void             TestMoneyManager();
    void             TestStrategy();
    
    // Utility methods
    void             SetupTestEnvironment();
    void             CleanupTestEnvironment();
    
public:
                     CComponentTests(bool verbose = true);
                    ~CComponentTests();
    
    void             RunAllTests();
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CComponentTests::CComponentTests(bool verbose = true) {
    m_framework = new CTestFramework(verbose);
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CComponentTests::~CComponentTests() {
    CleanupTestEnvironment();
    if(m_framework != NULL) delete m_framework;
}

//+------------------------------------------------------------------+
//| Run all component tests                                           |
//+------------------------------------------------------------------+
void CComponentTests::RunAllTests() {
    SetupTestEnvironment();
    
    TestStateManager();
    TestSignalManager();
    TestTradeManager();
    TestMoneyManager();
    TestStrategy();
    
    m_framework.PrintResults();
}

//+------------------------------------------------------------------+
//| Test State Manager                                                |
//+------------------------------------------------------------------+
void CComponentTests::TestStateManager() {
    m_framework.BeginTestSuite("State Manager Tests");
    
    // Test initialization
    m_framework.BeginTest("StateManager Initialization");
    m_framework.Assert(m_stateManager.Init(), "StateManager should initialize successfully");
    m_framework.EndTest();
    
    // Test trading state
    m_framework.BeginTest("Trading State Management");
    m_stateManager.SetTradingState(STATE_ACTIVE, "Test activation");
    m_framework.AssertEqual(STATE_ACTIVE, m_stateManager.GetTradingState(), "Trading state should be ACTIVE");
    m_framework.EndTest();
    
    // Test state validation
    m_framework.BeginTest("State Validation");
    m_framework.Assert(m_stateManager.ValidateState(), "State should be valid after initialization");
    m_stateManager.SetTradingState(STATE_STOPPED, "Test stop");
    m_framework.Assert(!m_stateManager.ValidateState(), "State should be invalid when stopped");
    m_framework.EndTest();
    
    m_framework.EndTestSuite();
}

//+------------------------------------------------------------------+
//| Test Signal Manager                                               |
//+------------------------------------------------------------------+
void CComponentTests::TestSignalManager() {
    m_framework.BeginTestSuite("Signal Manager Tests");
    
    // Test initialization
    m_framework.BeginTest("SignalManager Initialization");
    m_framework.Assert(m_signalManager.Init(Symbol(), PERIOD_H1), "SignalManager should initialize successfully");
    m_framework.EndTest();
    
    // Test signal generation
    m_framework.BeginTest("Signal Generation");
    m_framework.Assert(m_signalManager.UpdateSignals(), "Should be able to update signals");
    SSignal* signal = m_signalManager.GetCurrentSignal();
    m_framework.Assert(signal != NULL, "Should get a valid signal pointer");
    m_framework.EndTest();
    
    // Test signal validation
    m_framework.BeginTest("Signal Validation");
    if(signal != NULL) {
        signal.strength = 0.8;
        m_framework.Assert(m_signalManager.IsSignalValid(signal), "Signal with good strength should be valid");
        signal.strength = 0.2;
        m_framework.Assert(!m_signalManager.IsSignalValid(signal), "Signal with low strength should be invalid");
    }
    m_framework.EndTest();
    
    m_framework.EndTestSuite();
}

//+------------------------------------------------------------------+
//| Test Trade Manager                                                |
//+------------------------------------------------------------------+
void CComponentTests::TestTradeManager() {
    m_framework.BeginTestSuite("Trade Manager Tests");
    
    // Test initialization
    m_framework.BeginTest("TradeManager Initialization");
    m_framework.Assert(m_tradeManager.Init(Symbol(), MagicNumber, m_stateManager), 
                      "TradeManager should initialize successfully");
    m_framework.EndTest();
    
    // Test position management
    m_framework.BeginTest("Position Management");
    m_framework.Assert(!m_tradeManager.HasOpenPosition(), "Should have no position initially");
    double entry = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double stopLoss = entry - 100 * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    m_framework.Assert(m_tradeManager.OpenPosition(ORDER_TYPE_BUY, entry, stopLoss), 
                      "Should be able to open position");
    m_framework.Assert(m_tradeManager.HasOpenPosition(), "Should have position after opening");
    m_framework.Assert(m_tradeManager.ClosePosition(), "Should be able to close position");
    m_framework.EndTest();
    
    m_framework.EndTestSuite();
}

//+------------------------------------------------------------------+
//| Test Money Manager                                                |
//+------------------------------------------------------------------+
void CComponentTests::TestMoneyManager() {
    m_framework.BeginTestSuite("Money Manager Tests");
    
    // Test initialization
    m_framework.BeginTest("MoneyManager Initialization");
    m_framework.Assert(m_moneyManager.Init(m_stateManager), 
                      "MoneyManager should initialize successfully");
    m_framework.EndTest();
    
    // Test risk calculation
    m_framework.BeginTest("Risk Calculation");
    double balance = AccountBalance();
    double riskAmount = balance * 0.01; // 1% risk
    m_framework.Assert(m_moneyManager.ValidateTradeRisk(riskAmount), 
                      "1% risk should be valid");
    riskAmount = balance * 0.05; // 5% risk
    m_framework.Assert(!m_moneyManager.ValidateTradeRisk(riskAmount), 
                      "5% risk should be invalid");
    m_framework.EndTest();
    
    // Test position sizing
    m_framework.BeginTest("Position Sizing");
    double stopLoss = SymbolInfoDouble(Symbol(), SYMBOL_ASK) - 
                     100 * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    double lots = m_moneyManager.CalculatePositionSize(Symbol(), stopLoss);
    m_framework.Assert(lots > 0, "Should calculate valid position size");
    m_framework.Assert(lots <= SymbolInfoDouble(Symbol(), SYMBOL_MAXLOT), 
                      "Position size should not exceed maximum");
    m_framework.EndTest();
    
    m_framework.EndTestSuite();
}

//+------------------------------------------------------------------+
//| Test Strategy                                                     |
//+------------------------------------------------------------------+
void CComponentTests::TestStrategy() {
    m_framework.BeginTestSuite("Strategy Tests");
    
    // Test initialization
    m_framework.BeginTest("Strategy Initialization");
    m_framework.Assert(m_strategy.Init(Symbol(), PERIOD_H1, m_signalManager, m_moneyManager), 
                      "Strategy should initialize successfully");
    m_framework.EndTest();
    
    // Test pattern recognition
    m_framework.BeginTest("Pattern Recognition");
    SGoldenCandleParams params;
    params.SetDefaults();
    m_strategy.SetGoldenCandleParams(params);
    m_framework.Assert(m_strategy.Validate(), "Strategy validation should pass");
    m_framework.EndTest();
    
    // Test entry conditions
    m_framework.BeginTest("Entry Conditions");
    bool hasEntry = m_strategy.CheckEntryConditions();
    m_framework.Assert(m_strategy.IsTradeAllowed(), "Trading should be allowed after initialization");
    if(hasEntry) {
        double entryPrice = m_strategy.GetEntryPrice(ORDER_TYPE_BUY);
        m_framework.Assert(entryPrice > 0, "Should get valid entry price");
    }
    m_framework.EndTest();
    
    m_framework.EndTestSuite();
}

//+------------------------------------------------------------------+
//| Setup test environment                                            |
//+------------------------------------------------------------------+
void CComponentTests::SetupTestEnvironment() {
    // Create component instances
    m_stateManager = new CStateManager();
    m_signalManager = new CSignalManager();
    m_tradeManager = new CTradeManager();
    m_moneyManager = new CMoneyManager();
    m_strategy = new CGoldenCandleStrategy();
}

//+------------------------------------------------------------------+
//| Cleanup test environment                                          |
//+------------------------------------------------------------------+
void CComponentTests::CleanupTestEnvironment() {
    // Cleanup component instances
    if(m_strategy != NULL) {
        delete m_strategy;
        m_strategy = NULL;
    }
    if(m_moneyManager != NULL) {
        delete m_moneyManager;
        m_moneyManager = NULL;
    }
    if(m_tradeManager != NULL) {
        delete m_tradeManager;
        m_tradeManager = NULL;
    }
    if(m_signalManager != NULL) {
        delete m_signalManager;
        m_signalManager = NULL;
    }
    if(m_stateManager != NULL) {
        delete m_stateManager;
        m_stateManager = NULL;
    }
}
