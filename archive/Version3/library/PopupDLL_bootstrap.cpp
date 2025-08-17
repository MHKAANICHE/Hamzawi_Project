
#include <windows.h>
#include <commctrl.h>
#include <vector>
#include "GuiElements.hpp"

#pragma comment(lib, "comctl32.lib")

struct DialogContext {
    std::vector<GuiElement*> elements;
};

INT_PTR CALLBACK DialogProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam) {
    DialogContext* ctx = (DialogContext*)GetWindowLongPtr(hDlg, GWLP_USERDATA);
    switch (message) {
    case WM_INITDIALOG: {
        ctx = (DialogContext*)lParam;
        SetWindowLongPtr(hDlg, GWLP_USERDATA, (LONG_PTR)ctx);
        int y = 10;
        for (auto* el : ctx->elements) {
            el->Create(hDlg, 10, y, 200, 24);
            y += 30;
        }
        return TRUE;
    }
    case WM_COMMAND:
        // Only close dialog if a BUTTON (not other controls) is clicked
        if (HIWORD(wParam) == BN_CLICKED) {
            int btnId = LOWORD(wParam);
            if (btnId >= 100 && btnId <= 110) {
                EndDialog(hDlg, btnId);
            }
        }
        break;
    case WM_CLOSE:
        EndDialog(hDlg, 0);
        return TRUE;
    }
    return FALSE;
}

extern "C" __declspec(dllexport)
int ShowBootstrapDialog() {
    INITCOMMONCONTROLSEX icc = { sizeof(INITCOMMONCONTROLSEX), ICC_WIN95_CLASSES };
    InitCommonControlsEx(&icc);
    DialogContext ctx;
    // Label
    ctx.elements.push_back(new GuiLabel(L"Label: Welcome to the Demo!"));
    // Text input with initial value
    ctx.elements.push_back(new GuiEdit(L"Initial input", 101));
    // Password input with initial value
    ctx.elements.push_back(new GuiEdit(L"secret", 102, true));
    // Buttons
    ctx.elements.push_back(new GuiButton(L"OK", 100));
    ctx.elements.push_back(new GuiButton(L"Buy", 103));
    ctx.elements.push_back(new GuiButton(L"Sell", 104));
    ctx.elements.push_back(new GuiButton(L"Cancel", 105));
    ctx.elements.push_back(new GuiButton(L"Save", 106));
    // Dropdown/ComboBox with options
    auto* combo = new GuiComboBox(107);
    ctx.elements.push_back(combo);
    combo->AddItem(L"Option 1");
    combo->AddItem(L"Option 2");
    combo->AddItem(L"Option 3");
    combo->SetCurSel(1); // Select Option 2
    // ListBox with items
    auto* listbox = new GuiListBox(108);
    ctx.elements.push_back(listbox);
    // Checkbox checked by default
    auto* checkbox = new GuiCheckBox(L"Enable Feature", 109);
    ctx.elements.push_back(checkbox);
    // Radio button
    ctx.elements.push_back(new GuiRadioButton(L"Order Type: Market", 110));
    // Slider/Trackbar
    ctx.elements.push_back(new GuiSlider(111));
    // Group box
    ctx.elements.push_back(new GuiGroupBox(L"Settings Group", 112));
    // Tab control with 3 pages: Welcome, Settings, Help
    auto* tab = new GuiTab(113);
    ctx.elements.push_back(tab);
    // Progress bar at 50%
    auto* progress = new GuiProgressBar(114);
    ctx.elements.push_back(progress);
    BYTE dlgTemplate[1024] = {0};
    DLGTEMPLATE* pDlg = (DLGTEMPLATE*)dlgTemplate;
    pDlg->style = DS_MODALFRAME | WS_POPUP | WS_CAPTION | WS_SYSMENU;
    pDlg->cdit = 0;
    pDlg->x = 0; pDlg->y = 0; pDlg->cx = 400; pDlg->cy = 400;
    HINSTANCE hInstance = GetModuleHandle(NULL);
    int ret = DialogBoxIndirectParamW(hInstance, pDlg, NULL, DialogProc, (LPARAM)&ctx);
    for (auto* el : ctx.elements) delete el;
    return ret;
}
