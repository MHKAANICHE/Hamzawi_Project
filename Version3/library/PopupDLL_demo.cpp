// PopupDLL_demo.cpp
// Demo DLL entry point for standard interface showing all OOP GUI elements
#include <windows.h>
#include <vector>
#include <string>
#include <functional>
#include "GuiElements.hpp"
#include <commctrl.h>

#pragma comment(lib, "comctl32.lib")

std::vector<GuiElement*> elements;

// Helper to create and layout all demo elements
void CreateDemoElements(HWND parent) {
    int y = 10;
    elements.clear();
    // Label
    elements.push_back(new GuiLabel(L"Demo: All OOP GUI Elements", 100, 10, y, 300, 24)); y += 30;
    // Edit
    auto edit = new GuiEdit(L"Type here", 101); elements.push_back(edit); edit->Create(parent, 10, y, 200, 24); y += 30;
    // Password
    auto pass = new GuiEdit(L"", 102, true); elements.push_back(pass); pass->Create(parent, 10, y, 200, 24); y += 30;
    // ComboBox
    auto combo = new GuiComboBox(103); elements.push_back(combo); combo->Create(parent, 10, y, 120, 24); combo->AddItem(L"Option 1"); combo->AddItem(L"Option 2"); combo->AddItem(L"Option 3"); y += 30;
    // ListBox
    auto list = new GuiListBox(104); elements.push_back(list); list->Create(parent, 10, y, 120, 60); list->AddItem(L"Item 1"); list->AddItem(L"Item 2"); list->AddItem(L"Item 3"); y += 70;
    // Checkbox
    auto check = new GuiCheckBox(L"Enable", 105); elements.push_back(check); check->Create(parent, 10, y, 100, 24); y += 30;
    // RadioButton
    auto radio1 = new GuiRadioButton(L"Choice A", 106, 10, y, 100, 24); elements.push_back(radio1); radio1->Create(parent); y += 30;
    auto radio2 = new GuiRadioButton(L"Choice B", 107, 10, y, 100, 24); elements.push_back(radio2); radio2->Create(parent); y += 30;
    // Slider
    auto slider = new GuiSlider(108, 0, 100, 50); elements.push_back(slider); slider->Create(parent, 10, y, 200, 24); y += 30;
    // GroupBox
    auto group = new GuiGroupBox(L"Settings", 109, 220, 10, 150, 120); elements.push_back(group); group->Create(parent);
    // Tab
    auto tab = new GuiTab(110, 10, y, 200, 40, TabDock::Top); tab->AddPage(L"Welcome"); tab->AddPage(L"Settings"); tab->AddPage(L"Help"); elements.push_back(tab); tab->Create(parent); y += 50;
    // ProgressBar
    auto progress = new GuiProgressBar(111, 10, y, 200, 24, 0, 100, 25); elements.push_back(progress); progress->Create(parent); y += 30;
    // Buttons
    auto btnOk = new GuiButton(L"OK", 112, 10, y, 60, 24); elements.push_back(btnOk); btnOk->Create(parent);
    auto btnBuy = new GuiButton(L"Buy", 113, 80, y, 60, 24); elements.push_back(btnBuy); btnBuy->Create(parent);
    auto btnSell = new GuiButton(L"Sell", 114, 150, y, 60, 24); elements.push_back(btnSell); btnSell->Create(parent);
    auto btnCancel = new GuiButton(L"Cancel", 115, 220, y, 60, 24); elements.push_back(btnCancel); btnCancel->Create(parent);
}

INT_PTR CALLBACK DemoDialogProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch(msg) {
        case WM_INITDIALOG:
            InitCommonControls();
            CreateDemoElements(hDlg);
            return TRUE;
        case WM_COMMAND:
            for(auto* el : elements) {
                el->HandleMessage(msg, wParam, lParam);
            }
            // Only close on action button
            if(LOWORD(wParam) >= 112 && LOWORD(wParam) <= 115) {
                EndDialog(hDlg, LOWORD(wParam));
                return TRUE;
            }
            break;
        case WM_HSCROLL:
            for(auto* el : elements) {
                el->HandleMessage(msg, wParam, lParam);
            }
            break;
        case WM_NOTIFY:
            for(auto* el : elements) {
                el->HandleMessage(msg, wParam, lParam);
            }
            break;
        case WM_CLOSE:
            EndDialog(hDlg, 0);
            return TRUE;
    }
    return FALSE;
}

extern "C" __declspec(dllexport)
int ShowDemoDialog() {
    INITCOMMONCONTROLSEX icc = { sizeof(icc), ICC_WIN95_CLASSES };
    InitCommonControlsEx(&icc);
    return DialogBoxParamW(GetModuleHandle(NULL), NULL, NULL, DemoDialogProc, 0);
}
