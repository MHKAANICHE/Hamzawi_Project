// GoldenCandleEA_UserActions.cpp
#include "GoldenCandleEA_UserActions.h"


// Handle user actions from GUI or EA

#include "GoldenCandleEA_MoneyManagement.h"
#include "GoldenCandleEA_Strategy.h"

// Global/shared parameters (in real code, these would be managed more robustly)
static MoneyManagementParams g_mmParams;
static StrategyParams g_strategyParams;

void HandleUserAction(UserActionType action, ManualOrderParams* params) {
    switch(action) {
        case ACTION_PAUSE:
            // Pause trading
            PauseTrading(&g_mmParams);
            printf("[UserAction] Trading paused by user.\n");
            break;
        case ACTION_SKIP_LEVEL:
            // Skip to next progression level
            SkipToLevel(&g_mmParams, g_mmParams.skipToLevel+2); // skip to next level (1-based)
            printf("[UserAction] Skipped to next lot progression level: %d.\n", g_mmParams.skipToLevel+1);
            break;
        case ACTION_MANUAL_ORDER:
            // Place manual order with provided params
            if(params) {
                printf("[UserAction] Manual order: type=%d, lot=%.2f, entry=%.2f, SL=%.2f, TP=%.2f\n",
                    params->orderType, params->lotSize, params->entryPrice, params->stopLoss, params->takeProfit);
                // Here you would call the order placement logic, e.g., send to MT4 via bridge
                // For now, just log
            }
            break;
        case ACTION_ADJUST_MIN_SIZE:
            // Adjust minimum Golden Candle size (simulate user input)
            g_strategyParams.goldenCandlePercent += 0.01; // Example: increment by 1%
            printf("[UserAction] Adjusted minimum Golden Candle percent to %.2f.\n", g_strategyParams.goldenCandlePercent);
            break;
        case ACTION_IGNORE_ALERT:
            // Ignore current alert, take no action
            printf("[UserAction] Alert ignored by user.\n");
            break;
        default:
            printf("[UserAction] Unknown action.\n");
            break;
    }
}
