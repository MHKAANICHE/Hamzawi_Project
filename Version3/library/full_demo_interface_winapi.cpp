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
// Step 1: Thread-safe persistent window creation and lifecycle management
#include <thread>
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
    // Log file path: same as testament file, but with .log extension
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
    MSG msg;
    DWORD lastParentCheck = GetTickCount();
    // Only declare lastTestamentCheck once
    DWORD lastTestamentCheck = GetTickCount();
    while (g_windowRunning && GetMessage(&msg, NULL, 0, 0)) {
        // Suicide timer: close window if not comforted within 5 seconds
        if (GetTickCount() - g_lastHeartbeat > 5000) {
            OutputDebugStringA("[DLL] Persistent window closing due to heartbeat timeout.\n");
            if (hWnd) PostMessageW(hWnd, WM_CLOSE, 0, 0);
            break;
        }
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
// AUTOGEN START
// Auto-generated C++ WinAPI GUI code from HTML sketch
// Required for std::vector
#include <vector>
// AUTOGEN region commented out due to invalid code. Uncomment and refactor when generator is fixed.
/*
std::vector<GuiElement*> elements;
int y = 10;
// Label: Name: for input input_name
auto edit_input_name = new GuiEdit(L"", 113); elements.push_back(edit_input_name); edit_input_name->Create(parent, 10, 10, 200, 24); y += 30;
*/
// AUTOGEN END

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

