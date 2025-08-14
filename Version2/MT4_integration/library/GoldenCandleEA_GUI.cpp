// GoldenCandleEA_GUI.cpp
// Win32 GUI implementation for Golden Candle EA user actions
// Patch 2: Expanded dialog for pause, skip, manual order, adjust min size, ignore alert

#include <windows.h>
#include "GoldenCandleEA_Interface.h"

// Global state for pause
static bool gPaused = false;
static bool gSkipLevel = false;
static bool gManualOrder = false;
static bool gAdjustMinSize = false;
// Manual order parameters
static double gManualLot = 0.01;
static double gManualEntry = 0.0;
static double gManualSL = 0.0;
static double gManualTP = 0.0;
// Adjust min size parameter
static double gNewMinSize = 0.0;
static bool gIgnoreAlert = false;
// Lot progression level for status
static int gLotLevel = 0;

// Forward declarations
INT_PTR CALLBACK DialogProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
INT_PTR CALLBACK ManualOrderProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
INT_PTR CALLBACK MinSizeProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);

// Exported function for EA to show the dialog
extern "C" __declspec(dllexport) void ShowEADialog() {
    DialogBoxParam(GetModuleHandle(NULL), MAKEINTRESOURCE(101), NULL, DialogProc, 0);
}

// Dialog procedure
INT_PTR CALLBACK DialogProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_INITDIALOG:
        SetDlgItemText(hwnd, 1001, gPaused ? "Resume Trading" : "Pause Trading");
        // Status display
        char status[128];
        wsprintf(status, "Status: %s | Lot Level: %d", gPaused ? "Paused" : "Active", gLotLevel);
        SetDlgItemText(hwnd, 1010, status);
        return TRUE;
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case 1001: // Pause/Resume
            gPaused = !gPaused;
            SetDlgItemText(hwnd, 1001, gPaused ? "Resume Trading" : "Pause Trading");
            EndDialog(hwnd, 0);
            return TRUE;
        case 1002: // Skip Level
            if(MessageBox(hwnd, "Are you sure you want to skip to the next lot progression level?", "Confirm Skip Level", MB_YESNO|MB_ICONQUESTION) == IDYES) {
                gLotLevel++;
                gSkipLevel = true;
            }
            EndDialog(hwnd, 0);
            return TRUE;
        case 1003: // Manual Order
            if(MessageBox(hwnd, "Are you sure you want to place a manual order?", "Confirm Manual Order", MB_YESNO|MB_ICONQUESTION) == IDYES) {
                if (DialogBoxParam(GetModuleHandle(NULL), MAKEINTRESOURCE(201), hwnd, ManualOrderProc, 0) == IDOK) {
                    gManualOrder = true;
                }
            }
            EndDialog(hwnd, 0);
            return TRUE;
        case 1004: // Adjust Min Size
            if (DialogBoxParam(GetModuleHandle(NULL), MAKEINTRESOURCE(202), hwnd, MinSizeProc, 0) == IDOK) {
                gAdjustMinSize = true;
            }
            EndDialog(hwnd, 0);
            return TRUE;
        case 1005: // Ignore Alert
            gIgnoreAlert = true;
            EndDialog(hwnd, 0);
            return TRUE;
        case IDCANCEL:
            EndDialog(hwnd, 0);
            return TRUE;
        }
        break;
    }
    return FALSE;
}




// Manual order input dialog procedure
INT_PTR CALLBACK ManualOrderProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_INITDIALOG:
        SetDlgItemText(hwnd, 2001, "0.01");
        SetDlgItemText(hwnd, 2002, "0.0");
        SetDlgItemText(hwnd, 2003, "0.0");
        SetDlgItemText(hwnd, 2004, "0.0");
        return TRUE;
    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK) {
            char buf[32];
            GetDlgItemText(hwnd, 2001, buf, 32); double lot = atof(buf);
            GetDlgItemText(hwnd, 2002, buf, 32); double entry = atof(buf);
            GetDlgItemText(hwnd, 2003, buf, 32); double sl = atof(buf);
            GetDlgItemText(hwnd, 2004, buf, 32); double tp = atof(buf);
            if (lot <= 0.0) {
                MessageBox(hwnd, "Lot size must be greater than 0.", "Input Error", MB_OK|MB_ICONERROR);
                return TRUE;
            }
            gManualLot = lot;
            gManualEntry = entry;
            gManualSL = sl;
            gManualTP = tp;
            EndDialog(hwnd, IDOK);
            return TRUE;
        }
        if (LOWORD(wParam) == IDCANCEL) {
            EndDialog(hwnd, IDCANCEL);
            return TRUE;
        }
        break;
    }
    return FALSE;
}

// Adjust min size input dialog procedure
INT_PTR CALLBACK MinSizeProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {

    switch (msg) {
    case WM_INITDIALOG:
        SetDlgItemText(hwnd, 2101, "0.0");
        return TRUE;
    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK) {
            char buf[32];
            GetDlgItemText(hwnd, 2101, buf, 32); double minSize = atof(buf);
            if (minSize <= 0.0) {
                MessageBox(hwnd, "Min size must be greater than 0.", "Input Error", MB_OK|MB_ICONERROR);
                return TRUE;
            }
            gNewMinSize = minSize;
            EndDialog(hwnd, IDOK);
            return TRUE;
        }
        if (LOWORD(wParam) == IDCANCEL) {
            EndDialog(hwnd, IDCANCEL);
            return TRUE;
        }
        break;
    }
    return FALSE;
}


// Exported functions for EA to query user actions
extern "C" __declspec(dllexport) bool IsTradingPaused() { return gPaused; }
extern "C" __declspec(dllexport) bool IsSkipLevel() { bool v = gSkipLevel; gSkipLevel = false; return v; }
extern "C" __declspec(dllexport) bool IsManualOrder() { bool v = gManualOrder; gManualOrder = false; return v; }
extern "C" __declspec(dllexport) void GetManualOrderParams(double* lot, double* entry, double* sl, double* tp) {
    *lot = gManualLot; *entry = gManualEntry; *sl = gManualSL; *tp = gManualTP;
}
extern "C" __declspec(dllexport) bool IsAdjustMinSize() { bool v = gAdjustMinSize; gAdjustMinSize = false; return v; }
extern "C" __declspec(dllexport) double GetNewMinSize() { return gNewMinSize; }
extern "C" __declspec(dllexport) bool IsIgnoreAlert() { bool v = gIgnoreAlert; gIgnoreAlert = false; return v; }

// Resource script (for reference, not compiled here):
// 101 DIALOGEX 0,0,200,100
// STYLE DS_MODALFRAME | WS_POPUP | WS_CAPTION | WS_SYSMENU
// CAPTION "Golden Candle EA Control"
// FONT 9, "Segoe UI"
// BEGIN
//     PUSHBUTTON "Pause Trading",1001,50,40,100,24
// END
