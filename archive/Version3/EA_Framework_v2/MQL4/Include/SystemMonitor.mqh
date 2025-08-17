//+------------------------------------------------------------------+
//|                                          SystemMonitor.mqh |
//|                              Copyright 2025, Golden Candle Team |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Golden Candle Team"
#property strict

// Monitoring Constants
#define MAX_EXECUTION_TIME    100     // Maximum allowed execution time (ms)
#define MAX_ERROR_RATE       0.01    // Maximum allowed error rate (1%)
#define CONNECTION_TIMEOUT   5000    // Connection timeout (ms)
#define LOG_FILENAME        "GoldenCandle_System.log"

// Error tracking
#define ERROR_WINDOW_SIZE    100     // Number of operations to track
#define ERROR_RESET_HOURS    24      // Reset error counters every 24 hours

//+------------------------------------------------------------------+
//| System Monitor Class                                               |
//+------------------------------------------------------------------+
class CSystemMonitor {
private:
    bool           m_initialized;
    string         m_logPath;
    
    // Performance tracking
    uint           m_startTime;
    uint           m_lastCheckTime;
    
    // Error tracking
    int            m_errorCounts[];
    int            m_totalOperations;
    datetime       m_lastResetTime;
    
    // Connection state
    bool           m_isConnected;
    uint           m_lastPingTime;
    
    // Internal methods
    void           LogMessage(string message, int level = 0);
    void           CheckErrorReset();
    bool           ValidateConnection();
    
public:
                   CSystemMonitor();
                  ~CSystemMonitor();
    
    // Initialization
    bool           Init();
    
    // Monitoring operations
    void           StartOperation(string name);
    void           EndOperation(bool success = true);
    void           LogError(int errorCode, string context);
    
    // Performance tracking
    double         GetErrorRate();
    uint           GetExecutionTime();
    bool           IsConnectionValid();
    
    // System checks
    bool           ValidateSystemState();
    void           OnTick();
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CSystemMonitor::CSystemMonitor() {
    m_initialized = false;
    m_startTime = 0;
    m_lastCheckTime = 0;
    m_totalOperations = 0;
    m_lastResetTime = 0;
    m_isConnected = false;
    m_lastPingTime = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CSystemMonitor::~CSystemMonitor() {
    if(m_initialized) {
        LogMessage("System monitor shutdown");
    }
}

//+------------------------------------------------------------------+
//| Initialize System Monitor                                          |
//+------------------------------------------------------------------+
bool CSystemMonitor::Init() {
    m_logPath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL4\\Logs\\" + LOG_FILENAME;
    
    // Initialize error tracking
    ArrayResize(m_errorCounts, ERROR_WINDOW_SIZE);
    ArrayInitialize(m_errorCounts, 0);
    
    m_lastResetTime = TimeLocal();
    m_isConnected = IsConnected();
    m_lastPingTime = GetTickCount();
    
    m_initialized = true;
    
    LogMessage("System monitor initialized");
    return true;
}

//+------------------------------------------------------------------+
//| Log message to file                                               |
//+------------------------------------------------------------------+
void CSystemMonitor::LogMessage(string message, int level = 0) {
    if(!m_initialized) return;
    
    string prefix;
    switch(level) {
        case 1: prefix = "WARNING: "; break;
        case 2: prefix = "ERROR: "; break;
        default: prefix = "INFO: ";
    }
    
    string logEntry = TimeToString(TimeLocal(), TIME_DATE|TIME_MINUTES|TIME_SECONDS) +
                     " " + prefix + message;
    
    int handle = FileOpen(m_logPath, FILE_WRITE|FILE_READ|FILE_TXT);
    if(handle != INVALID_HANDLE) {
        FileSeek(handle, 0, SEEK_END);
        FileWriteString(handle, logEntry + "\n");
        FileClose(handle);
    }
}

//+------------------------------------------------------------------+
//| Check if error tracking needs reset                               |
//+------------------------------------------------------------------+
void CSystemMonitor::CheckErrorReset() {
    if(TimeLocal() - m_lastResetTime >= ERROR_RESET_HOURS * 3600) {
        ArrayInitialize(m_errorCounts, 0);
        m_totalOperations = 0;
        m_lastResetTime = TimeLocal();
        LogMessage("Error tracking reset");
    }
}

//+------------------------------------------------------------------+
//| Validate connection state                                         |
//+------------------------------------------------------------------+
bool CSystemMonitor::ValidateConnection() {
    uint currentTime = GetTickCount();
    
    // Check if we need to update connection state
    if(currentTime - m_lastPingTime >= CONNECTION_TIMEOUT) {
        m_isConnected = IsConnected();
        m_lastPingTime = currentTime;
    }
    
    return m_isConnected;
}

//+------------------------------------------------------------------+
//| Start monitoring operation                                        |
//+------------------------------------------------------------------+
void CSystemMonitor::StartOperation(string name) {
    if(!m_initialized) return;
    
    m_startTime = GetTickCount();
    LogMessage("Starting operation: " + name);
}

//+------------------------------------------------------------------+
//| End monitoring operation                                          |
//+------------------------------------------------------------------+
void CSystemMonitor::EndOperation(bool success = true) {
    if(!m_initialized) return;
    
    uint executionTime = GetExecutionTime();
    
    if(!success) {
        LogMessage("Operation failed. Execution time: " + 
                  IntegerToString(executionTime) + "ms", 1);
        
        // Track error
        m_errorCounts[m_totalOperations % ERROR_WINDOW_SIZE]++;
    }
    else if(executionTime > MAX_EXECUTION_TIME) {
        LogMessage("Operation exceeded time limit. Execution time: " + 
                  IntegerToString(executionTime) + "ms", 1);
    }
    
    m_totalOperations++;
    CheckErrorReset();
}

//+------------------------------------------------------------------+
//| Log error with context                                           |
//+------------------------------------------------------------------+
void CSystemMonitor::LogError(int errorCode, string context) {
    if(!m_initialized) return;
    
    string errorDesc = ErrorDescription(errorCode);
    LogMessage("Error " + IntegerToString(errorCode) + ": " + 
              errorDesc + " in " + context, 2);
}

//+------------------------------------------------------------------+
//| Calculate current error rate                                      |
//+------------------------------------------------------------------+
double CSystemMonitor::GetErrorRate() {
    if(!m_initialized || m_totalOperations == 0) return 0;
    
    int totalErrors = 0;
    int windowSize = MathMin(m_totalOperations, ERROR_WINDOW_SIZE);
    
    for(int i = 0; i < windowSize; i++) {
        totalErrors += m_errorCounts[i];
    }
    
    return (double)totalErrors / windowSize;
}

//+------------------------------------------------------------------+
//| Get operation execution time                                      |
//+------------------------------------------------------------------+
uint CSystemMonitor::GetExecutionTime() {
    if(!m_initialized || m_startTime == 0) return 0;
    return GetTickCount() - m_startTime;
}

//+------------------------------------------------------------------+
//| Check connection validity                                         |
//+------------------------------------------------------------------+
bool CSystemMonitor::IsConnectionValid() {
    return m_initialized && ValidateConnection();
}

//+------------------------------------------------------------------+
//| Validate overall system state                                     |
//+------------------------------------------------------------------+
bool CSystemMonitor::ValidateSystemState() {
    if(!m_initialized) return false;
    
    // Check connection
    if(!IsConnectionValid()) {
        LogMessage("System state check failed: No connection", 2);
        return false;
    }
    
    // Check error rate
    if(GetErrorRate() > MAX_ERROR_RATE) {
        LogMessage("System state check failed: Error rate too high", 2);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Regular system update                                             |
//+------------------------------------------------------------------+
void CSystemMonitor::OnTick() {
    if(!m_initialized) return;
    
    uint currentTime = GetTickCount();
    
    // Perform periodic checks
    if(currentTime - m_lastCheckTime >= CONNECTION_TIMEOUT) {
        ValidateConnection();
        ValidateSystemState();
        m_lastCheckTime = currentTime;
    }
}
