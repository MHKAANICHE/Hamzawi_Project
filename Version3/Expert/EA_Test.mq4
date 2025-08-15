//+------------------------------------------------------------------+
//| EA_Test.mq4 - Automated test EA for WinAPI GUI DLL integration   |
//+------------------------------------------------------------------+
#property strict

#import "full_demo_interface.dll"
void CreateDemoGui(int parent);
#import

int handle = 0;

int OnInit()
{
    // Get the chart window handle (HWND)
    handle = WindowHandle(Symbol(), Period());
    Print("[EA_Test] Chart HWND: ", handle);
    // Call the DLL function to create the GUI
    CreateDemoGui(handle);
    Print("[EA_Test] CreateDemoGui called.");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    Print("[EA_Test] Deinit reason: ", reason);
    // Optionally, add cleanup logic here
}

void OnTick()
{
    // Automated test: log tick and check if GUI is present
    Print("[EA_Test] Tick: ", TimeCurrent());
    // Optionally, add more checks or interactions
}
