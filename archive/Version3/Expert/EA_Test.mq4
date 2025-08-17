//+------------------------------------------------------------------+
//| EA_Test.mq4 - Automated test EA for WinAPI GUI DLL integration   |
//+------------------------------------------------------------------+

#property strict

#import "full_demo_interface.dll"
void CreateDemoBootstrapWindow(int parentHandle, string logPath);
#import

int handle = 0;
int magic = 0;
string testamentFile = "";
string testamentPath = "";

// Modular initialization
void InitPersistentWindow()
{
    handle = WindowHandle(Symbol(), Period());
    magic = MathRand();
    testamentFile = "testament_" + IntegerToString(magic) + ".txt";
    string dataPath = TerminalInfoString(TERMINAL_DATA_PATH);
    testamentPath = dataPath + "\\MQL4\\Files\\" + testamentFile;
    Print("[EA_Test] Chart HWND: ", handle);
    Print("[EA_Test] Magic: ", magic);
    Print("[EA_Test] Testament path: ", testamentPath);
    // DLL call with error handling for v2
    bool dllCalled = false;
    if(handle > 0 && StringLen(testamentPath) > 0)
    {
        CreateDemoBootstrapWindow(handle, testamentPath);
        dllCalled = true;
        Print("[EA_Test] CreateDemoBootstrapWindow called.");
    }
    else
    {
        Print("[EA_Test] ERROR: Invalid handle or testament path.");
    }
}

// Modular cleanup
void CleanupPersistentWindow()
{
    Print("[EA_Test] Deinit reason: ", UninitializeReason());
    int fileHandle = FileOpen(testamentFile, FILE_WRITE|FILE_TXT);
    if(fileHandle >= 0)
    {
        FileWrite(fileHandle, "goodbye");
        FileClose(fileHandle);
        Print("[EA_Test] Testament file written: ", testamentPath);
    }
    else
    {
        Print("[EA_Test] ERROR: Could not write testament file: ", testamentPath);
    }
    // No explicit close for v2 demo window
    Print("[EA_Test] Cleanup complete for v2 demo window.");
}

int OnInit()
{
    InitPersistentWindow();
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    CleanupPersistentWindow();
}

void OnTick()
{
    Print("[EA_Test] Tick: ", TimeCurrent());

    // Read and parse testament file if it exists
    int fileHandle = FileOpen(testamentFile, FILE_READ|FILE_TXT);
    if(fileHandle >= 0)
    {
        string values = "";
        while(!FileIsEnding(fileHandle))
        {
            string line = FileReadString(fileHandle);
            if(StringLen(line) > 0)
                values += line + "\n";
        }
        FileClose(fileHandle);
        Print("[EA_Test] GUI values received:\n", values);

        // Optionally, parse each value for further logic
        string name = "", password = "", enable = "", option_a = "", option_b = "", slider = "", combo = "", list = "";
        string arr[];
        int n = StringSplit(values, '\n', arr);
        for(int i=0; i<n; i++)
        {
            if(StringFind(arr[i], "name=") == 0) name = StringSubstr(arr[i], 5);
            if(StringFind(arr[i], "password=") == 0) password = StringSubstr(arr[i], 9);
            if(StringFind(arr[i], "enable=") == 0) enable = StringSubstr(arr[i], 7);
            if(StringFind(arr[i], "option_a=") == 0) option_a = StringSubstr(arr[i], 9);
            if(StringFind(arr[i], "option_b=") == 0) option_b = StringSubstr(arr[i], 9);
            if(StringFind(arr[i], "slider=") == 0) slider = StringSubstr(arr[i], 7);
            if(StringFind(arr[i], "combo=") == 0) combo = StringSubstr(arr[i], 6);
            if(StringFind(arr[i], "list=") == 0) list = StringSubstr(arr[i], 5);
        }
        Print("[EA_Test] Parsed values: name=", name, ", password=", password, ", enable=", enable, ", option_a=", option_a, ", option_b=", option_b, ", slider=", slider, ", combo=", combo, ", list=", list);
    }
}

