// GoldenCandleEA_Alerts.cpp
#include "GoldenCandleEA_Alerts.h"
#include <stdio.h>

void ShowAlert(const char* message) {
    // TODO: Implement alert popup (Win32 or other)
    printf("ALERT: %s\n", message);
}

void LogAlert(const char* type, const char* message, const char* userAction) {
    // TODO: Write alert to log file or display in GUI
    printf("ALERT LOG [%s] %s | Action: %s\n", type, message, userAction);
}
