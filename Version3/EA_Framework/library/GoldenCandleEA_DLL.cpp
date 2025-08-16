#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include "include/Constants.h"
#include "include/Enums.h"
#include "include/Structures.h"
#include "include/GoldenCandleStrategy.h"

// DLL Export definitions
#define EXPORT extern "C" __declspec(dllexport)

// Global instance of the strategy
CGoldenCandleStrategy* g_strategy = NULL;

// DLL Entry point
BOOL APIENTRY DllMain(HANDLE hModule, DWORD reason, LPVOID lpReserved)
{
    switch(reason)
    {
        case DLL_PROCESS_ATTACH:
            g_strategy = new CGoldenCandleStrategy();
            break;
            
        case DLL_PROCESS_DETACH:
            if(g_strategy) {
                delete g_strategy;
                g_strategy = NULL;
            }
            break;
    }
    return TRUE;
}

// Exported functions
EXPORT bool __stdcall InitStrategy()
{
    if(!g_strategy) return false;
    return g_strategy->Init();
}

EXPORT void __stdcall DeinitStrategy()
{
    if(g_strategy) g_strategy->Deinit();
}

EXPORT bool __stdcall CheckEntryConditions()
{
    if(!g_strategy) return false;
    return g_strategy->CheckEntryConditions();
}

EXPORT bool __stdcall CheckExitConditions()
{
    if(!g_strategy) return false;
    return g_strategy->CheckExitConditions();
}

EXPORT double __stdcall GetEntryPrice(int orderType)
{
    if(!g_strategy) return 0.0;
    return g_strategy->GetEntryPrice((ENUM_ORDER_TYPE)orderType);
}

EXPORT void __stdcall SetGoldenCandleParams(SGoldenCandleParams* params)
{
    if(!g_strategy || !params) return;
    g_strategy->SetGoldenCandleParams(params);
}
