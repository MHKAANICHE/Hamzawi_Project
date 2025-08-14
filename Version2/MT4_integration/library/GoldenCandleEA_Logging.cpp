// GoldenCandleEA_Logging.cpp
#include "GoldenCandleEA_Logging.h"
#include <stdio.h>
#include <time.h>

void LogEvent(const char* type, const char* message) {
    // TODO: Write log to file or display in GUI
    // Example: log to console (for dev)
    time_t now = time(NULL);
    char timebuf[32];
    strftime(timebuf, sizeof(timebuf), "%Y-%m-%d %H:%M:%S", localtime(&now));
    printf("[%s] %s: %s\n", timebuf, type, message);
}
