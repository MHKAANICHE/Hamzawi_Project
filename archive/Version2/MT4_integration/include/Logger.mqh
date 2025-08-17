//+------------------------------------------------------------------+
//| Logger.mqh - Handles logging and alerting                       |
//+------------------------------------------------------------------+
#ifndef __LOGGER_MQH__
#define __LOGGER_MQH__

class Logger {
public:
    static void LogEvent(string type, string message) {
        Print("[" + type + "] " + message);
    }
    static void ShowAlert(string message) {
        Alert(message);
    }
    static void SendUserAlert(string message) {
        Alert(message); // Or use a custom notification method
    }
};

#endif // __LOGGER_MQH__
