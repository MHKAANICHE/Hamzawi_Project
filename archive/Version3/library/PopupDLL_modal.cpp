#include <windows.h>

#define ID_EDIT   1001
#define ID_OK     1
#define ID_CANCEL 2

struct DialogData {
    wchar_t* wbuffer;
    int wbufferLen;
    int pressedButton;
};

INT_PTR CALLBACK DialogProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam) {
    DialogData* data = (DialogData*)GetWindowLongPtr(hDlg, GWLP_USERDATA);
    switch (message) {
    case WM_INITDIALOG:
        SetWindowLongPtr(hDlg, GWLP_USERDATA, lParam);
        CreateWindowW(L"STATIC", L"Enter value:", WS_VISIBLE | WS_CHILD, 10, 10, 60, 20, hDlg, NULL, NULL, NULL);
        CreateWindowW(L"EDIT", L"", WS_VISIBLE | WS_CHILD | WS_BORDER | ES_AUTOHSCROLL, 10, 35, 180, 20, hDlg, (HMENU)ID_EDIT, NULL, NULL);
        CreateWindowW(L"BUTTON", L"OK", WS_VISIBLE | WS_CHILD | BS_DEFPUSHBUTTON, 40, 65, 50, 20, hDlg, (HMENU)ID_OK, NULL, NULL);
        CreateWindowW(L"BUTTON", L"Cancel", WS_VISIBLE | WS_CHILD, 110, 65, 50, 20, hDlg, (HMENU)ID_CANCEL, NULL, NULL);
        return TRUE;
    case WM_COMMAND:
        if (LOWORD(wParam) == ID_OK) {
            if (data && data->wbuffer && data->wbufferLen > 0) {
                HWND hEdit = GetDlgItem(hDlg, ID_EDIT);
                GetWindowTextW(hEdit, data->wbuffer, data->wbufferLen);
            }
            data->pressedButton = ID_OK;
            EndDialog(hDlg, ID_OK);
            return TRUE;
        }
        if (LOWORD(wParam) == ID_CANCEL) {
            data->pressedButton = ID_CANCEL;
            EndDialog(hDlg, ID_CANCEL);
            return TRUE;
        }
        break;
    case WM_CLOSE:
        data->pressedButton = ID_CANCEL;
        EndDialog(hDlg, ID_CANCEL);
        return TRUE;
    }
    return FALSE;
}

extern "C" __declspec(dllexport)
int ShowInputDialog(char* buffer, int bufferLen) {
    wchar_t wbuffer[256] = {0};
    DialogData data = { wbuffer, 256, 0 };
    // Create a dialog template in memory
    BYTE dlgTemplate[1024] = {0};
    DLGTEMPLATE* pDlg = (DLGTEMPLATE*)dlgTemplate;
    pDlg->style = DS_MODALFRAME | WS_POPUP | WS_CAPTION | WS_SYSMENU;
    pDlg->cdit = 0; // No controls, will be created in WM_INITDIALOG
    pDlg->x = 0; pDlg->y = 0; pDlg->cx = 220; pDlg->cy = 120;
    HINSTANCE hInstance = GetModuleHandle(NULL);
    DialogBoxIndirectParamW(hInstance, pDlg, NULL, DialogProc, (LPARAM)&data);
    // Convert wbuffer to buffer (ANSI)
    WideCharToMultiByte(CP_ACP, 0, wbuffer, -1, buffer, bufferLen, NULL, NULL);
    return data.pressedButton;
}