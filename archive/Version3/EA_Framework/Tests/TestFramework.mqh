//+------------------------------------------------------------------+
//|                                                TestFramework.mqh |
//|                                     Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"
#property strict

//+------------------------------------------------------------------+
//| Test Framework Class                                               |
//+------------------------------------------------------------------+
class CTestFramework {
private:
    int               m_totalTests;
    int               m_passedTests;
    int               m_failedTests;
    string            m_currentSuite;
    string            m_currentTest;
    bool              m_isVerbose;
    
    // Private methods
    void             LogResult(bool passed, string message);
    void             LogError(string expected, string actual);
    string           GetFormattedTime();
    
public:
                     CTestFramework(bool verbose = true);
                    ~CTestFramework();
    
    // Test management
    void             BeginTestSuite(string name);
    void             EndTestSuite();
    void             BeginTest(string name);
    void             EndTest();
    
    // Assertions
    void             Assert(bool condition, string message);
    void             AssertEqual(string expected, string actual, string message);
    void             AssertEqual(double expected, double actual, double tolerance, string message);
    void             AssertEqual(int expected, int actual, string message);
    void             AssertNotEqual(double expected, double actual, double tolerance, string message);
    void             AssertGreaterThan(double value1, double value2, string message);
    void             AssertLessThan(double value1, double value2, string message);
    
    // Results
    void             PrintResults();
    int              GetPassedTests() { return m_passedTests; }
    int              GetFailedTests() { return m_failedTests; }
    int              GetTotalTests()  { return m_totalTests; }
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CTestFramework::CTestFramework(bool verbose = true) {
    m_totalTests = 0;
    m_passedTests = 0;
    m_failedTests = 0;
    m_currentSuite = "";
    m_currentTest = "";
    m_isVerbose = verbose;
}

//+------------------------------------------------------------------+
//| Begin a test suite                                                |
//+------------------------------------------------------------------+
void CTestFramework::BeginTestSuite(string name) {
    m_currentSuite = name;
    if(m_isVerbose) {
        Print("===== Beginning Test Suite: ", name, " =====");
    }
}

//+------------------------------------------------------------------+
//| End a test suite                                                  |
//+------------------------------------------------------------------+
void CTestFramework::EndTestSuite() {
    if(m_isVerbose) {
        Print("===== End Test Suite: ", m_currentSuite, " =====\n");
    }
    m_currentSuite = "";
}

//+------------------------------------------------------------------+
//| Begin a test case                                                 |
//+------------------------------------------------------------------+
void CTestFramework::BeginTest(string name) {
    m_currentTest = name;
    m_totalTests++;
    if(m_isVerbose) {
        Print("Running test: ", name);
    }
}

//+------------------------------------------------------------------+
//| End a test case                                                   |
//+------------------------------------------------------------------+
void CTestFramework::EndTest() {
    m_currentTest = "";
}

//+------------------------------------------------------------------+
//| Assert a condition                                                |
//+------------------------------------------------------------------+
void CTestFramework::Assert(bool condition, string message) {
    if(condition) {
        m_passedTests++;
        LogResult(true, message);
    } else {
        m_failedTests++;
        LogResult(false, message);
    }
}

//+------------------------------------------------------------------+
//| Assert equality between strings                                   |
//+------------------------------------------------------------------+
void CTestFramework::AssertEqual(string expected, string actual, string message) {
    if(expected == actual) {
        m_passedTests++;
        LogResult(true, message);
    } else {
        m_failedTests++;
        LogResult(false, message);
        LogError(expected, actual);
    }
}

//+------------------------------------------------------------------+
//| Assert equality between doubles                                   |
//+------------------------------------------------------------------+
void CTestFramework::AssertEqual(double expected, double actual, double tolerance, string message) {
    if(MathAbs(expected - actual) <= tolerance) {
        m_passedTests++;
        LogResult(true, message);
    } else {
        m_failedTests++;
        LogResult(false, message);
        LogError(DoubleToString(expected), DoubleToString(actual));
    }
}

//+------------------------------------------------------------------+
//| Assert equality between integers                                  |
//+------------------------------------------------------------------+
void CTestFramework::AssertEqual(int expected, int actual, string message) {
    if(expected == actual) {
        m_passedTests++;
        LogResult(true, message);
    } else {
        m_failedTests++;
        LogResult(false, message);
        LogError(IntegerToString(expected), IntegerToString(actual));
    }
}

//+------------------------------------------------------------------+
//| Log test result                                                   |
//+------------------------------------------------------------------+
void CTestFramework::LogResult(bool passed, string message) {
    if(!m_isVerbose) return;
    
    string result = passed ? "PASSED" : "FAILED";
    string timestamp = GetFormattedTime();
    string testInfo = StringFormat("[%s] %s: %s - %s", 
                                 timestamp,
                                 result,
                                 m_currentTest,
                                 message);
    Print(testInfo);
}

//+------------------------------------------------------------------+
//| Log error details                                                 |
//+------------------------------------------------------------------+
void CTestFramework::LogError(string expected, string actual) {
    if(!m_isVerbose) return;
    
    Print("  Expected: ", expected);
    Print("  Actual:   ", actual);
}

//+------------------------------------------------------------------+
//| Get formatted timestamp                                           |
//+------------------------------------------------------------------+
string CTestFramework::GetFormattedTime() {
    datetime time = TimeCurrent();
    return TimeToString(time, TIME_DATE|TIME_SECONDS);
}

//+------------------------------------------------------------------+
//| Print test results summary                                        |
//+------------------------------------------------------------------+
void CTestFramework::PrintResults() {
    Print("\n===== Test Results =====");
    Print("Total Tests:  ", m_totalTests);
    Print("Passed Tests: ", m_passedTests);
    Print("Failed Tests: ", m_failedTests);
    Print("Pass Rate:    ", 
          m_totalTests > 0 ? 
          DoubleToString(((double)m_passedTests/m_totalTests) * 100, 2) + "%" :
          "N/A");
    Print("======================\n");
}
