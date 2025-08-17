// GoldenCandleEA_MoneyManagement.h
// Money management logic interface

#ifndef GOLDENCANDLEEA_MONEYMANAGEMENT_H
#define GOLDENCANDLEEA_MONEYMANAGEMENT_H

struct MoneyManagementParams {
    double lotTable[25];
    int lotTableSize;
    double rrTable[25];
    int rrTableSize;
    bool pauseTrading;
    int skipToLevel;
};

double GetCurrentLotSize(const MoneyManagementParams* params, int level);
double GetCurrentRR(const MoneyManagementParams* params, int level);
void PauseTrading(MoneyManagementParams* params);
void SkipToLevel(MoneyManagementParams* params, int level);

#endif // GOLDENCANDLEEA_MONEYMANAGEMENT_H
