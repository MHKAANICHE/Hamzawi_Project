// full_demo_interface_winapi_v2.cpp
// Clean demo of bootstrapped GUI elements for MT4 DLL child window
#include <windows.h>
#include <vector>
#include <string>
#include <sstream>
#include <thread>
#include "GuiElements.hpp"

// Helper logging function
void logWithTimestampToFile(const char* msg, const std::string& logFilePath) {
    std::ofstream logfile(logFilePath, std::ios::app);
    if (logfile.is_open()) {
        logfile << msg << std::endl;
        logfile.close();
    }
}

LRESULT CALLBACK DemoWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
    static std::vector<GuiElement*>* elementsPtr = nullptr;
    if (message == WM_USER + 1) {
        // Custom message to set elements pointer
        elementsPtr = (std::vector<GuiElement*>*)lParam;
        return 0;
    }
    if (elementsPtr) {
        for (auto el : *elementsPtr) {
            if (el && el->HandleMessage(message, wParam, lParam)) return 0;
        }
    }
    switch (message) {
    case WM_CLOSE:
        DestroyWindow(hWnd);
        break;
    case WM_DESTROY:
        PostQuitMessage(0);
        break;
    default:
        return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
}

void DemoWindowThread(HINSTANCE hInstance, HWND parent, std::string logFilePath) {
    WNDCLASSW wc = {0};
    wc.lpfnWndProc = DemoWndProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = L"MT4DemoWindow";
    RegisterClassW(&wc);
    int winW = 900, winH = 700;
    HWND hWnd = CreateWindowExW(0, wc.lpszClassName, L"MT4 Bootstrap GUI Demo", WS_OVERLAPPEDWINDOW | WS_VISIBLE,
        120, 120, winW, winH, parent, NULL, hInstance, NULL);
    ShowWindow(hWnd, SW_SHOW);
    UpdateWindow(hWnd);
    HBRUSH hBrush = CreateSolidBrush(RGB(240, 245, 255));
    SetClassLongPtr(hWnd, GCLP_HBRBACKGROUND, (LONG_PTR)hBrush);
    HFONT hFont = CreateFontW(20, 0, 0, 0, FW_MEDIUM, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH | FF_SWISS, L"Segoe UI");
    SendMessageW(hWnd, WM_SETFONT, (WPARAM)hFont, TRUE);
    ShowWindow(hWnd, SW_SHOW);
    UpdateWindow(hWnd);

    // --- Bootstrap GUI Elements ---
    std::vector<GuiElement*> elements;
    int xPad = 80, yPad = 80, y = yPad;
    int labelW = 140, inputW = 260, inputH = 40, gapY = 60, gapX = 32;
    int xCenter = 420;

    // Static labels and GUI elements
    HWND lblName = CreateWindowW(L"STATIC", L"Name:", WS_VISIBLE | WS_CHILD, xCenter - labelW - 10, y, labelW, inputH, hWnd, NULL, hInstance, NULL);
    auto nameEdit = new GuiEdit(L"", 201); elements.push_back(nameEdit);
    nameEdit->Create(hWnd, xCenter, y, inputW, inputH); y += gapY;

    HWND lblPass = CreateWindowW(L"STATIC", L"Password:", WS_VISIBLE | WS_CHILD, xCenter - labelW - 10, y, labelW, inputH, hWnd, NULL, hInstance, NULL);
    auto passEdit = new GuiEdit(L"", 202, true); elements.push_back(passEdit);
    passEdit->Create(hWnd, xCenter, y, inputW, inputH); y += gapY;

    y += gapY / 2;
    HWND lblEnable = CreateWindowW(L"STATIC", L"Enable:", WS_VISIBLE | WS_CHILD, xCenter - labelW - 10, y, labelW, inputH, hWnd, NULL, hInstance, NULL);
    auto enableCheck = new GuiCheckBox(L"Enable", 203); elements.push_back(enableCheck);
    enableCheck->Create(hWnd, xCenter, y, 120, inputH); y += gapY;

    // Forward elements pointer to window procedure for message handling
    SendMessage(hWnd, WM_USER + 1, 0, (LPARAM)&elements);

    HWND lblOptionA = CreateWindowW(L"STATIC", L"Option A:", WS_VISIBLE | WS_CHILD, xCenter - labelW - 10, y, labelW, inputH, hWnd, NULL, hInstance, NULL);
    auto optionA = new GuiRadioButton(L"Option A", 204, xCenter, y, 120, inputH); elements.push_back(optionA);
    optionA->Create(hWnd, xCenter, y, 120, inputH);
    HWND lblOptionB = CreateWindowW(L"STATIC", L"Option B:", WS_VISIBLE | WS_CHILD, xCenter + 140, y, labelW, inputH, hWnd, NULL, hInstance, NULL);
    auto optionB = new GuiRadioButton(L"Option B", 205, xCenter + 160, y, 120, inputH); elements.push_back(optionB);
    optionB->Create(hWnd, xCenter + 160, y, 120, inputH); y += gapY;

    y += gapY / 2;
    HWND lblSlider = CreateWindowW(L"STATIC", L"Value:", WS_VISIBLE | WS_CHILD, xCenter - labelW - 10, y, labelW, inputH, hWnd, NULL, hInstance, NULL);
    auto valueSlider = new GuiSlider(206, 0, 100, 50); elements.push_back(valueSlider);
    valueSlider->Create(hWnd, xCenter, y, inputW, inputH); y += gapY;

    HWND lblCombo = CreateWindowW(L"STATIC", L"Choice:", WS_VISIBLE | WS_CHILD, xCenter - labelW - 10, y, labelW, inputH, hWnd, NULL, hInstance, NULL);
    auto choiceCombo = new GuiComboBox(207); choiceCombo->AddItem(L"Option 1"); choiceCombo->AddItem(L"Option 2"); choiceCombo->AddItem(L"Option 3"); elements.push_back(choiceCombo);
    choiceCombo->Create(hWnd, xCenter, y, inputW, inputH); y += gapY;

    HWND lblList = CreateWindowW(L"STATIC", L"List:", WS_VISIBLE | WS_CHILD, xCenter - labelW - 10, y, labelW, inputH, hWnd, NULL, hInstance, NULL);
    auto itemList = new GuiListBox(208); itemList->AddItem(L"Item 1"); itemList->AddItem(L"Item 2"); itemList->AddItem(L"Item 3"); elements.push_back(itemList);
    itemList->Create(hWnd, xCenter, y, inputW, 100); y += 110;

    y += gapY / 2;
    // Action Buttons
    auto okBtn = new GuiButton(L"OK", 209); elements.push_back(okBtn);
    okBtn->Create(hWnd, xCenter, y, 120, inputH);
    auto applyBtn = new GuiButton(L"Apply", 210); elements.push_back(applyBtn);
    applyBtn->Create(hWnd, xCenter + 140, y, 140, inputH);

    // --- Event Handlers ---
    okBtn->onClick = [=]() {
        logWithTimestampToFile("[Demo] OK clicked", logFilePath);
    };
    applyBtn->onClick = [=]() {
        std::ostringstream oss;
        oss << "name=" << std::string(nameEdit->GetText().begin(), nameEdit->GetText().end()) << "\n";
        oss << "password=" << std::string(passEdit->GetText().begin(), passEdit->GetText().end()) << "\n";
        oss << "enable=" << (enableCheck->GetChecked() ? "1" : "0") << "\n";
        oss << "option_a=" << (optionA->GetChecked() ? "1" : "0") << "\n";
        oss << "option_b=" << (optionB->GetChecked() ? "1" : "0") << "\n";
        oss << "slider=" << valueSlider->GetValue() << "\n";
        oss << "combo=" << choiceCombo->GetCurSel() << "\n";
        oss << "list=";
        auto selList = itemList->GetSelIndices();
        for (size_t i = 0; i < selList.size(); ++i) {
            oss << selList[i];
            if (i + 1 < selList.size()) oss << ",";
        }
        oss << "\n";
        std::string values = oss.str();
        logWithTimestampToFile(("[Demo] Apply clicked. Values:\n" + values).c_str(), logFilePath);
    };

    // --- Message Loop ---
    MSG msg;
    // Forward pointer to elements for message handling
    SendMessage(hWnd, WM_USER + 1, 0, (LPARAM)&elements);
    while (GetMessage(&msg, NULL, 0, 0)) {
        // Forward messages to GUI elements for responsiveness
        for (auto el : elements) {
            if (el && el->HandleMessage(msg.message, msg.wParam, msg.lParam)) {
                continue;
            }
        }
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
}

extern "C" __declspec(dllexport)
void CreateDemoBootstrapWindow(int parentHandle, const char* logPath) {
    HINSTANCE hInstance = GetModuleHandle(NULL);
    HWND parent = (HWND)parentHandle;
    std::string logFile(logPath);
    std::thread demoThread(DemoWindowThread, hInstance, parent, logFile);
    demoThread.detach();
}
