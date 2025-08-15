//+------------------------------------------------------------------+
//| FullDemoEA.mq4 - Example EA to call WinAPI GUI DLL               |
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
    // Call the DLL function to create the GUI
    CreateDemoGui(handle);
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    // Optionally, add cleanup logic here
}

void OnTick()
{
    // Your trading logic here
}