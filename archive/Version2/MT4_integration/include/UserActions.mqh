//+------------------------------------------------------------------+
//| UserActions.mqh - Handles user action utilities                  |
//+------------------------------------------------------------------+
#ifndef __USERACTIONS_MQH__
#define __USERACTIONS_MQH__

#include "Logger.mqh"

class UserActions {
public:
    static void IgnoreCurrentAlert() {
        Logger::LogEvent("USER", "User chose to ignore the current alert/signal.");
        if(!IsTesting()) Logger::ShowAlert("Current alert/signal ignored by user.");
    }
    static void AdjustMinGoldenCandleSize(double &GoldenCandleMinSize, double newMinSize) {
        GoldenCandleMinSize = newMinSize;
        string msg = "Minimum Golden Candle size adjusted to " + DoubleToStr(newMinSize, 2);
        Logger::LogEvent("USER", msg);
        if(!IsTesting()) Logger::ShowAlert(msg);
    }
};

#endif // __USERACTIONS_MQH__
