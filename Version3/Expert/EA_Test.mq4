//+------------------------------------------------------------------+
//| EA_Test.mq4 - Automated test EA for WinAPI GUI DLL integration   |
//+------------------------------------------------------------------+
#property strict

#import "full_demo_interface.dll"
void CreatePersistentWindow(int parentHandle, string testamentPath);
void ClosePersistentWindow();
void PersistentWindowHeartbeat();
#import

int handle = 0;
int magic = 0;
string testamentFile = "";
string testamentPath = "";

int OnInit()
{
    // Get the chart window handle (HWND)
    handle = WindowHandle(Symbol(), Period());
    // Generate a random magic number for this instance
    magic = MathRand();
    testamentFile = "testament_" + IntegerToString(magic) + ".txt";
    string dataPath = TerminalInfoString(TERMINAL_DATA_PATH);
    testamentPath = dataPath + "\\MQL4\\Files\\" + testamentFile;
    Print("[EA_Test] Chart HWND: ", handle);
    Print("[EA_Test] Magic: ", magic);
    Print("[EA_Test] Testament path: ", testamentPath);
    // Call the DLL function to create the persistent window, passing the full path
    CreatePersistentWindow(handle, testamentPath);
    Print("[EA_Test] CreatePersistentWindow called.");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    Print("[EA_Test] Deinit reason: ", reason);
    // Write testament file with goodbye message
    int fileHandle = FileOpen(testamentFile, FILE_WRITE|FILE_TXT);
    if(fileHandle >= 0) {
        FileWrite(fileHandle, "goodbye");
        FileClose(fileHandle);
        Print("[EA_Test] Testament file written: ", testamentPath);
    }
    // Explicitly close persistent window
    ClosePersistentWindow();
}

void OnTick()
{
    // Automated test: log tick and keep persistent window alive
    Print("[EA_Test] Tick: ", TimeCurrent());
    PersistentWindowHeartbeat();
    // Optionally, add more checks or interactions
}
