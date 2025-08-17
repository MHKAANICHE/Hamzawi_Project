// GoldenCandleEA_MoneyManagement.cpp
#include "GoldenCandleEA_MoneyManagement.h"


// Returns the lot size for the current progression level, or the first if out of bounds
double GetCurrentLotSize(const MoneyManagementParams* params, int level) {
    if(params->pauseTrading) return 0.0; // Trading paused
    if(level < 0) level = 0;
    if(level >= params->lotTableSize) level = params->lotTableSize-1;
    return params->lotTable[level];
}

// Returns the R:R for the current progression level, or the first if out of bounds
double GetCurrentRR(const MoneyManagementParams* params, int level) {
    if(level < 0) level = 0;
    if(level >= params->rrTableSize) level = params->rrTableSize-1;
    return params->rrTable[level];
}

// Pauses trading by setting the flag
void PauseTrading(MoneyManagementParams* params) {
    params->pauseTrading = true;
}

// Skips to a specific progression level (1-based for user, 0-based internal)
void SkipToLevel(MoneyManagementParams* params, int level) {
    if(level > 0 && level <= params->lotTableSize) params->skipToLevel = level-1;
}
