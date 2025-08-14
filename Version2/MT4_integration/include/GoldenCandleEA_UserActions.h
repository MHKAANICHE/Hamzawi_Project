// GoldenCandleEA_UserActions.h
// User action enums and structures

#ifndef GOLDENCANDLEEA_USERACTIONS_H
#define GOLDENCANDLEEA_USERACTIONS_H

enum UserActionType {
    ACTION_NONE = 0,
    ACTION_PAUSE,
    ACTION_SKIP_LEVEL,
    ACTION_MANUAL_ORDER,
    ACTION_ADJUST_MIN_SIZE,
    ACTION_IGNORE_ALERT
};

struct ManualOrderParams {
    int orderType; // 0=Market, 1=Pending
    double lotSize;
    double entryPrice;
    double stopLoss;
    double takeProfit;
};

#endif // GOLDENCANDLEEA_USERACTIONS_H
