#include <chrono>
#include <fstream>
#include <string>
#include <sstream>
// Required for std::atomic
#include <atomic>
// Suicide timer for persistent window
std::atomic<unsigned long> g_lastHeartbeat(0);
// Required for std::atomic
#include <atomic>
// Atomic flag to signal window closure from EA
std::atomic<bool> g_windowCloseRequested(false);
// Required for WinAPI types and functions
#include <windows.h>
#include <commctrl.h>
// Step 1: Thread-safe persistent window creation and lifecycle management
#include <thread>
#include <vector>
#include "GuiElements.hpp"
#include <atomic>

std::atomic<bool> g_windowRunning(false);
HWND g_persistentWindow = NULL;
std::thread g_windowThread;

LRESULT CALLBACK PersistentWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
    case WM_CLOSE:
        DestroyWindow(hWnd);
        break;
    case WM_DESTROY:
        g_windowRunning = false;
        g_persistentWindow = NULL;
        PostQuitMessage(0);
        break;
    default:
        return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
}

// Helper to get testament filename from magic number
std::string getTestamentFilename(int magic) {
    std::ostringstream oss;
    oss << "testament_" << magic << ".txt";
    return oss.str();
}

void logWithTimestampToFile(const char* msg, const std::string& logFilePath) {
    // Also write to C:\Temp\dll_test_log.txt for audit
    std::string tempLogPath = "C:\\Temp\\dll_test_log.txt";
    auto now = std::chrono::system_clock::now();
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count();
    char buf[512];
    snprintf(buf, sizeof(buf), "[%lld ms] %s\n", ms, msg);
    std::ofstream logfile(logFilePath, std::ios::app);
    if (logfile.is_open()) {
        logfile << buf;
        logfile.close();
    }
    std::ofstream tempLog(tempLogPath, std::ios::app);
    if (tempLog.is_open()) {
        tempLog << buf;
        tempLog.close();
    }
}
// ...existing code...

void PersistentWindowThread(HINSTANCE hInstance, HWND parent, std::string testamentFile) {
    // AUTOGEN: Begin auto-generated GUI code
    std::vector<GuiElement*> elements;
    int y = 10;
    // ...existing AUTOGEN code will be placed here...
    // AUTOGEN: End auto-generated GUI code
    // Log file path: same as testament file, but with .log extension
        INITCOMMONCONTROLSEX icc;
        icc.dwSize = sizeof(INITCOMMONCONTROLSEX);
        icc.dwICC = ICC_WIN95_CLASSES | ICC_BAR_CLASSES;
        InitCommonControlsEx(&icc);
    std::string logFilePath = testamentFile + ".log";
    logWithTimestampToFile("[DLL] Thread started.", logFilePath);
    logWithTimestampToFile("[DLL] Window creation attempted.", logFilePath);
    {
        char buf[512];
        snprintf(buf, sizeof(buf), "[DLL] Testament polling started. Path: %s", testamentFile.c_str());
        logWithTimestampToFile(buf, logFilePath);
    }
    logWithTimestampToFile("[DLL] Message loop started.", logFilePath);
    g_lastHeartbeat = GetTickCount();
    WNDCLASSW wc = {0};
    wc.lpfnWndProc = PersistentWndProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = L"MT4PersistentWindow";
    RegisterClassW(&wc);
    HWND hWnd = CreateWindowExW(0, wc.lpszClassName, L"MT4 Persistent Window", WS_OVERLAPPEDWINDOW,
        100, 100, 400, 200, parent, NULL, hInstance, NULL);
    g_persistentWindow = hWnd;
    g_windowRunning = true;
    ShowWindow(hWnd, SW_SHOW);
    UpdateWindow(hWnd);
    // AUTOGEN START
// Auto-generated C++ WinAPI GUI code from HTML sketch
    // Label: Name: for input input_name
    auto edit_input_name = new GuiEdit(L"Alice", 113); elements.push_back(edit_input_name); edit_input_name->Create(parent, 10, 10, 200, 24); y += 30;
    // Label: Name: for slider input_name
    // Label: Password: for password input_password
    auto pass_input_password = new GuiEdit(L"", 114, true); elements.push_back(pass_input_password); pass_input_password->Create(parent, 10, 10, 200, 24); y += 30;
    // Label: Password: for slider input_password
    // Label: Enable: for checkbox input_enable
    auto check_input_enable = new GuiCheckBox(L"input_enable", 115); elements.push_back(check_input_enable); check_input_enable->Create(parent, 10, 10, 100, 24); y += 30;
    // Label: Enable: for slider input_enable
    // Label: Option A: for slider radio_option_a
    // Label: Option B: for slider radio_option_b
    // Label: Value: for slider slider_value
    auto slider_slider_value = new GuiSlider(118, 0, 100, 50); elements.push_back(slider_slider_value); slider_slider_value->Create(parent, 10, 10, 200, 24); y += 30;
    // Label: Value: for slider slider_value
// AUTOGEN END

    HINSTANCE ctrlInstance = GetModuleHandle(NULL);
    // AUTOGEN: Create GUI elements from full_demo_interface.html
    HWND lblName = CreateWindowW(L"STATIC", L"Name:", WS_VISIBLE | WS_CHILD, 10, 10, 60, 24, hWnd, NULL, ctrlInstance, NULL);
    HWND editInput1 = CreateWindowW(L"EDIT", L"Alice", WS_VISIBLE | WS_CHILD | WS_BORDER | ES_AUTOHSCROLL, 80, 10, 120, 24, hWnd, (HMENU)1001, ctrlInstance, NULL);
    HWND lblPass = CreateWindowW(L"STATIC", L"Password:", WS_VISIBLE | WS_CHILD, 10, 40, 60, 24, hWnd, NULL, ctrlInstance, NULL);
    HWND editPass1 = CreateWindowW(L"EDIT", L"", WS_VISIBLE | WS_CHILD | WS_BORDER | ES_PASSWORD, 80, 40, 120, 24, hWnd, (HMENU)1002, ctrlInstance, NULL);
    HWND lblEnable = CreateWindowW(L"STATIC", L"Enable:", WS_VISIBLE | WS_CHILD, 10, 70, 60, 24, hWnd, NULL, ctrlInstance, NULL);
    HWND lblOptionA = CreateWindowW(L"STATIC", L"Option A:", WS_VISIBLE | WS_CHILD, 10, 100, 60, 24, hWnd, NULL, ctrlInstance, NULL);
        HWND checkEnable = CreateWindowW(L"BUTTON", L"", WS_VISIBLE | WS_CHILD | BS_AUTOCHECKBOX, 80, 70, 24, 24, hWnd, (HMENU)1003, ctrlInstance, NULL);
    HWND lblOptionB = CreateWindowW(L"STATIC", L"Option B:", WS_VISIBLE | WS_CHILD, 120, 100, 60, 24, hWnd, NULL, ctrlInstance, NULL);
        HWND radioA = CreateWindowW(L"BUTTON", L"", WS_VISIBLE | WS_CHILD | BS_AUTORADIOBUTTON, 80, 100, 24, 24, hWnd, (HMENU)1004, ctrlInstance, NULL);
    HWND lblSlider = CreateWindowW(L"STATIC", L"Value:", WS_VISIBLE | WS_CHILD, 10, 130, 60, 24, hWnd, NULL, ctrlInstance, NULL);
        HWND slider1 = CreateWindowW(L"msctls_trackbar32", NULL, WS_VISIBLE | WS_CHILD | TBS_AUTOTICKS, 80, 130, 200, 40, hWnd, (HMENU)1006, ctrlInstance, NULL);
        SendMessageW(slider1, TBM_SETRANGE, TRUE, MAKELPARAM(0, 100));
        SendMessageW(slider1, TBM_SETPOS, TRUE, 50);
        HWND radioB = CreateWindowW(L"BUTTON", L"", WS_VISIBLE | WS_CHILD | BS_AUTORADIOBUTTON, 200, 100, 24, 24, hWnd, (HMENU)1005, ctrlInstance, NULL);
    HWND lblCombo = CreateWindowW(L"STATIC", L"Choice:", WS_VISIBLE | WS_CHILD, 10, 160, 60, 24, hWnd, NULL, ctrlInstance, NULL);
    HWND combo1 = CreateWindowW(L"COMBOBOX", NULL, WS_VISIBLE | WS_CHILD | CBS_DROPDOWNLIST, 80, 160, 120, 100, hWnd, (HMENU)1007, ctrlInstance, NULL);
    SendMessageW(combo1, CB_ADDSTRING, 0, (LPARAM)L"Option 1");
    SendMessageW(combo1, CB_ADDSTRING, 0, (LPARAM)L"Option 2");
    SendMessageW(combo1, CB_ADDSTRING, 0, (LPARAM)L"Option 3");
    HWND lblList = CreateWindowW(L"STATIC", L"List:", WS_VISIBLE | WS_CHILD, 10, 190, 60, 24, hWnd, NULL, ctrlInstance, NULL);
    HWND list1 = CreateWindowW(L"LISTBOX", NULL, WS_VISIBLE | WS_CHILD | LBS_STANDARD, 80, 190, 120, 60, hWnd, (HMENU)1008, ctrlInstance, NULL);
    SendMessageW(list1, LB_ADDSTRING, 0, (LPARAM)L"Item 1");
    SendMessageW(list1, LB_ADDSTRING, 0, (LPARAM)L"Item 2");
    SendMessageW(list1, LB_ADDSTRING, 0, (LPARAM)L"Item 3");
    HWND btnOk = CreateWindowW(L"BUTTON", L"OK", WS_VISIBLE | WS_CHILD | BS_DEFPUSHBUTTON, 220, 10, 70, 24, hWnd, (HMENU)1010, ctrlInstance, NULL);
    HWND btnBuy = CreateWindowW(L"BUTTON", L"Buy", WS_VISIBLE | WS_CHILD, 220, 40, 70, 24, hWnd, (HMENU)1011, ctrlInstance, NULL);
    HWND btnSell = CreateWindowW(L"BUTTON", L"Sell", WS_VISIBLE | WS_CHILD, 220, 70, 70, 24, hWnd, (HMENU)1012, ctrlInstance, NULL);
    HWND btnCancel = CreateWindowW(L"BUTTON", L"Cancel", WS_VISIBLE | WS_CHILD, 220, 100, 70, 24, hWnd, (HMENU)1013, ctrlInstance, NULL);
    HWND progress1 = CreateWindowW(L"msctls_progress32", NULL, WS_VISIBLE | WS_CHILD, 10, 260, 280, 24, hWnd, (HMENU)1014, ctrlInstance, NULL);
    SendMessageW(progress1, PBM_SETPOS, 25, 0);
        // Add a group box for 'Settings Group' (HTML <div id="settings">)
        HWND groupSettings = CreateWindowW(L"BUTTON", L"Settings Group", WS_VISIBLE | WS_CHILD | BS_GROUPBOX, 220, 10, 150, 120, hWnd, (HMENU)1020, ctrlInstance, NULL);
    MSG msg;
    DWORD lastParentCheck = GetTickCount();
    // Only declare lastTestamentCheck once
    DWORD lastTestamentCheck = GetTickCount();
    while (g_windowRunning && GetMessage(&msg, NULL, 0, 0)) {
        // Suicide timer removed: persistent window will not close automatically
        // Testament file check every 1 second
        if (GetTickCount() - lastTestamentCheck > 1000) {
            lastTestamentCheck = GetTickCount();
            std::ifstream infile(testamentFile);
            std::string line;
            if (infile.is_open()) {
                logWithTimestampToFile("[DLL] Testament file exists, reading...", logFilePath);
                if (std::getline(infile, line)) {
                    char buf[512];
                    snprintf(buf, sizeof(buf), "[DLL] Testament file content: %s", line.c_str());
                    logWithTimestampToFile(buf, logFilePath);
                    if (line.find("goodbye") != std::string::npos) {
                        logWithTimestampToFile("[DLL] Persistent window closing due to testament file.", logFilePath);
                        if (hWnd) PostMessageW(hWnd, WM_CLOSE, 0, 0);
                        infile.close();
                        remove(testamentFile.c_str());
                        break;
                    }
                }
            } else {
                logWithTimestampToFile("[DLL] Testament file not found.", logFilePath);
            }
        }
        // Check for explicit close request on every loop
        if (g_windowCloseRequested) {
            OutputDebugStringA("[DLL] Persistent window closing due to explicit close request.\n");
            if (hWnd) PostMessageW(hWnd, WM_CLOSE, 0, 0);
            break;
        }
        // Parent window monitoring every 1 second
        if (GetTickCount() - lastParentCheck > 1000) {
            lastParentCheck = GetTickCount();
            if (parent && !IsWindow(parent)) {
                OutputDebugStringA("[DLL] Persistent window closing due to parent invalidation.\n");
                if (hWnd) PostMessageW(hWnd, WM_CLOSE, 0, 0);
                break;
            }
        }
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
        g_windowRunning = false;
        g_persistentWindow = NULL;
}

// DLL function to comfort (heartbeat) the persistent window
extern "C" __declspec(dllexport)
void PersistentWindowHeartbeat() {
    g_lastHeartbeat = GetTickCount();
}

// DLL function to explicitly close persistent window from EA
extern "C" __declspec(dllexport)
void ClosePersistentWindow() {
    g_windowCloseRequested = true;
}

extern "C" __declspec(dllexport)
void CreatePersistentWindow(int parentHandle, const char* testamentPath) {
    if (g_windowRunning) return; // Already running
    HINSTANCE hInstance = GetModuleHandle(NULL);
    HWND parent = (HWND)parentHandle;
    std::string testamentFile(testamentPath);
    g_windowThread = std::thread(PersistentWindowThread, hInstance, parent, testamentFile);
    g_windowThread.detach();
}

#include <windows.h>

// Safe modal input dialog using DialogBoxParamW
INT_PTR CALLBACK InputDialogProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam) {
    wchar_t* buffer = (wchar_t*)lParam;
    switch (message) {
    case WM_INITDIALOG:
        CreateWindowW(L"STATIC", L"Enter value:", WS_VISIBLE | WS_CHILD, 10, 10, 80, 20, hDlg, NULL, NULL, NULL);
        CreateWindowW(L"EDIT", L"", WS_VISIBLE | WS_CHILD | WS_BORDER | ES_AUTOHSCROLL, 100, 10, 120, 20, hDlg, (HMENU)1001, NULL, NULL);
        CreateWindowW(L"BUTTON", L"OK", WS_VISIBLE | WS_CHILD | BS_DEFPUSHBUTTON, 40, 50, 70, 25, hDlg, (HMENU)IDOK, NULL, NULL);
        CreateWindowW(L"BUTTON", L"Cancel", WS_VISIBLE | WS_CHILD, 130, 50, 70, 25, hDlg, (HMENU)IDCANCEL, NULL, NULL);
        return TRUE;
    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK) {
            GetDlgItemTextW(hDlg, 1001, buffer, 256);
            EndDialog(hDlg, IDOK);
            return TRUE;
        }
        if (LOWORD(wParam) == IDCANCEL) {
            EndDialog(hDlg, IDCANCEL);
            return TRUE;
        }
        break;
    }
    return FALSE;
}

extern "C" __declspec(dllexport)
int ShowSafeInputDialog(char* buffer, int bufferLen) {
    // Try minimal custom input dialog first
    wchar_t wbuffer[256] = {0};
    MultiByteToWideChar(CP_ACP, 0, buffer, -1, wbuffer, 256);
    HINSTANCE hInstance = GetModuleHandle(NULL);
    int result = DialogBoxParamW(hInstance, NULL, NULL, InputDialogProc, (LPARAM)wbuffer);
    if(result == IDOK) {
        // Convert back to char*
        WideCharToMultiByte(CP_ACP, 0, wbuffer, -1, buffer, bufferLen, NULL, NULL);
        return IDOK;
    }
    // Fallback: MessageBox for confirmation
    int msgResult = MessageBoxA(NULL, "DLL: Please confirm action.", "MT4 DLL Modal Fallback", MB_OKCANCEL | MB_ICONQUESTION);
    if(msgResult == IDOK) {
        strncpy(buffer, "Confirmed", bufferLen);
    } else {
        strncpy(buffer, "Cancelled", bufferLen);
    }
    return msgResult;
}

// Deprecated: Do not use persistent windows or threads in MT4 DLLs
extern "C" __declspec(dllexport) void CreateDemoGui(HWND parent) {
    MessageBoxW(NULL, L"Use ShowSafeInputDialog for robust MT4 integration.", L"DLL Info", MB_OK | MB_ICONINFORMATION);
}

