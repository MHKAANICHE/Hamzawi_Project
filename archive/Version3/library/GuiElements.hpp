
#pragma once
#include <windows.h>
#include <string>
#include <vector>
#include <functional>
#include <commctrl.h>
#include <chrono>
#include <fstream>
#include <sstream>

// Extern declaration for logging function
extern void logWithTimestampToFile(const char* msg, const std::string& logFilePath);

class GuiElement {
public:
    HWND hwnd;
    int id;
    virtual void Create(HWND parent, int x, int y, int w, int h) = 0;
    virtual bool HandleMessage(UINT msg, WPARAM wParam, LPARAM lParam) { return false; }
    virtual ~GuiElement() {}
};

class GuiButton : public GuiElement {
    std::wstring text;
public:
    std::function<void()> onClick;
    GuiButton(const std::wstring& t, int i) : text(t) { id = i; }
// The following classes are duplicates and will be removed.
// class GuiElement, class GuiButton, class GuiEdit, class GuiCheckBox, etc.
        void Create(HWND parent, int x, int y, int w, int h) override {
            hwnd = CreateWindowW(L"BUTTON", text.c_str(), WS_VISIBLE | WS_CHILD | BS_PUSHBUTTON, x, y, w, h, parent, (HMENU)id, NULL, NULL);
        }
        bool HandleMessage(UINT msg, WPARAM wParam, LPARAM lParam) override {
            if (msg == WM_COMMAND && LOWORD(wParam) == id && HIWORD(wParam) == BN_CLICKED) {
                if (onClick) onClick();
                    // Log button click
                    logWithTimestampToFile(("[MT4 GUI] Button clicked: " + std::to_string(id)).c_str(), "C:\\Temp\\dll_test_log.txt");
                return true;
            }
            return false;
        }
        void SetText(const std::wstring& t) {
            text = t;
            if(hwnd) SetWindowTextW(hwnd, text.c_str());
        }
        std::wstring GetText() const { return text; }
    };

    class GuiEdit : public GuiElement {
        std::wstring text;
        DWORD style;
    public:
        std::function<void(const std::wstring&)> onChange;
        GuiEdit(const std::wstring& t, int i, bool password = false) : text(t) {
            id = i;
            style = WS_VISIBLE | WS_CHILD | WS_BORDER | ES_AUTOHSCROLL;
            if(password) style |= ES_PASSWORD;
        }
        void Create(HWND parent, int x, int y, int w, int h) override {
            hwnd = CreateWindowW(L"EDIT", text.c_str(), style, x, y, w, h, parent, (HMENU)id, NULL, NULL);
        }
        bool HandleMessage(UINT msg, WPARAM wParam, LPARAM lParam) override {
            if (msg == WM_COMMAND && LOWORD(wParam) == id && HIWORD(wParam) == EN_CHANGE) {
                wchar_t buf[256] = {0};
                GetWindowTextW(hwnd, buf, 255);
                text = buf;
                if (onChange) onChange(text);
                    // Log input value change
                    std::wstring logMsg = L"[MT4 GUI] Input changed: " + std::to_wstring(id) + L" value: " + text;
                    std::string logMsgA(logMsg.begin(), logMsg.end());
                    logWithTimestampToFile(logMsgA.c_str(), "C:\\Temp\\dll_test_log.txt");
                return true;
            }
            return false;
        }
        void SetText(const std::wstring& t) {
            text = t;
            if(hwnd) SetWindowTextW(hwnd, text.c_str());
        }
        std::wstring GetText() const {
            if(hwnd) {
                wchar_t buf[256] = {0};
                GetWindowTextW(hwnd, buf, 255);
                return buf;
            }
            return text;
        }
    };

    class GuiCheckBox : public GuiElement {
        std::wstring text;
        bool checked = false;
    public:
        std::function<void(bool)> onCheck;
        GuiCheckBox(const std::wstring& t, int i, bool initial = false) : text(t), checked(initial) { id = i; }
        void Create(HWND parent, int x, int y, int w, int h) override {
            hwnd = CreateWindowW(L"BUTTON", text.c_str(), WS_VISIBLE | WS_CHILD | BS_CHECKBOX, x, y, w, h, parent, (HMENU)id, NULL, NULL);
            SetChecked(checked);
        }
        bool HandleMessage(UINT msg, WPARAM wParam, LPARAM lParam) override {
            if (msg == WM_COMMAND && LOWORD(wParam) == id && (HIWORD(wParam) == BN_CLICKED || HIWORD(wParam) == BN_DOUBLECLICKED)) {
                checked = (SendMessageW(hwnd, BM_GETCHECK, 0, 0) == BST_CHECKED);
                if (onCheck) onCheck(checked);
                    // Log checkbox state
                    std::string state = checked ? "checked" : "unchecked";
                    logWithTimestampToFile(("[MT4 GUI] Checkbox " + std::to_string(id) + " " + state).c_str(), "C:\\Temp\\dll_test_log.txt");
                return true;
            }
            return false;
        }
        void SetChecked(bool state) {
            checked = state;
            if(hwnd) SendMessageW(hwnd, BM_SETCHECK, checked ? BST_CHECKED : BST_UNCHECKED, 0);
        }
        bool GetChecked() const {
            if(hwnd) return (SendMessageW(hwnd, BM_GETCHECK, 0, 0) == BST_CHECKED);
            return checked;
        }
        void SetText(const std::wstring& t) {
            text = t;
            if(hwnd) SetWindowTextW(hwnd, text.c_str());
        }
        std::wstring GetText() const { return text; }
    };

    class GuiRadioButton : public GuiElement {
        std::wstring text;
        bool selected = false;
        int xpos, ypos, width, height;
    public:
        std::function<void(bool)> onSelect;
        GuiRadioButton(const std::wstring& t, int i, int x, int y, int w, int h)
            : text(t), selected(false), xpos(x), ypos(y), width(w), height(h) { id = i; }
        void Create(HWND parent, int x, int y, int w, int h) override {
            hwnd = CreateWindowW(L"BUTTON", text.c_str(), WS_VISIBLE | WS_CHILD | BS_AUTORADIOBUTTON, x, y, w, h, parent, (HMENU)id, NULL, NULL);
            SendMessageW(hwnd, BM_SETCHECK, selected ? BST_CHECKED : BST_UNCHECKED, 0);
        }
        bool HandleMessage(UINT msg, WPARAM wParam, LPARAM lParam) override {
            if (msg == WM_COMMAND && LOWORD(wParam) == id) {
                selected = SendMessageW(hwnd, BM_GETCHECK, 0, 0) == BST_CHECKED;
                if (onSelect) onSelect(selected);
                    // Log radio button selection
                    std::string state = selected ? "selected" : "deselected";
                    logWithTimestampToFile(("[MT4 GUI] RadioButton " + std::to_string(id) + " " + state).c_str(), "C:\\Temp\\dll_test_log.txt");
                return true;
            }
            return false;
        }
        void SetChecked(bool check) {
            selected = check;
            if (hwnd) SendMessageW(hwnd, BM_SETCHECK, check ? BST_CHECKED : BST_UNCHECKED, 0);
        }
        bool GetChecked() const { return selected; }
        void SetOnSelect(std::function<void(bool)> handler) { onSelect = handler; }
    };

    class GuiComboBox : public GuiElement {
        std::vector<std::wstring> items;
        int curSel = -1;
    public:
        std::function<void(int)> onSelect;
        GuiComboBox(int i) { id = i; }
        void Create(HWND parent, int x, int y, int w, int h) override {
            hwnd = CreateWindowW(L"COMBOBOX", NULL, WS_VISIBLE | WS_CHILD | CBS_DROPDOWNLIST, x, y, w, h, parent, (HMENU)id, NULL, NULL);
            for (const auto& item : items) {
                SendMessageW(hwnd, CB_ADDSTRING, 0, (LPARAM)item.c_str());
            }
            if (curSel >= 0) SetCurSel(curSel);
        }
        void AddItem(const std::wstring& item) {
            items.push_back(item);
            if(hwnd) SendMessageW(hwnd, CB_ADDSTRING, 0, (LPARAM)item.c_str());
        }
        void SetCurSel(int idx) {
            curSel = idx;
            if(hwnd) SendMessageW(hwnd, CB_SETCURSEL, idx, 0);
        }
        int GetCurSel() const {
            if(hwnd) return (int)SendMessageW(hwnd, CB_GETCURSEL, 0, 0);
            return curSel;
        }
        bool HandleMessage(UINT msg, WPARAM wParam, LPARAM lParam) override {
            if (msg == WM_COMMAND && LOWORD(wParam) == id && HIWORD(wParam) == CBN_SELCHANGE) {
                int sel = GetCurSel();
                if (onSelect) onSelect(sel);
                    // Log combo box selection
                    logWithTimestampToFile(("[MT4 GUI] ComboBox " + std::to_string(id) + " selected: " + std::to_string(sel)).c_str(), "C:\\Temp\\dll_test_log.txt");
                return true;
            }
            return false;
        }
    };

    class GuiListBox : public GuiElement {
        std::vector<std::wstring> items;
        std::vector<int> selIndices;
    public:
        std::function<void(const std::vector<int>&)> onSelect;
        GuiListBox(int i) { id = i; }
        void Create(HWND parent, int x, int y, int w, int h) override {
            hwnd = CreateWindowW(L"LISTBOX", NULL, WS_VISIBLE | WS_CHILD | LBS_MULTIPLESEL | WS_BORDER, x, y, w, h, parent, (HMENU)id, NULL, NULL);
            for (const auto& item : items) {
                SendMessageW(hwnd, LB_ADDSTRING, 0, (LPARAM)item.c_str());
            }
            for (int idx : selIndices) {
                SendMessageW(hwnd, LB_SETSEL, TRUE, idx);
            }
        }
        void AddItem(const std::wstring& item) {
            items.push_back(item);
            if(hwnd) SendMessageW(hwnd, LB_ADDSTRING, 0, (LPARAM)item.c_str());
        }
        void SetSelIndices(const std::vector<int>& indices) {
            selIndices = indices;
            if(hwnd) {
                SendMessageW(hwnd, LB_SETSEL, FALSE, -1); // clear all
                for (int idx : selIndices) {
                    SendMessageW(hwnd, LB_SETSEL, TRUE, idx);
                }
            }
        }
        std::vector<int> GetSelIndices() const {
            std::vector<int> result;
            if(hwnd) {
                int count = (int)SendMessageW(hwnd, LB_GETCOUNT, 0, 0);
                for(int i=0; i<count; ++i) {
                    if(SendMessageW(hwnd, LB_GETSEL, i, 0) > 0) result.push_back(i);
                }
            } else {
                result = selIndices;
            }
            return result;
        }
        bool HandleMessage(UINT msg, WPARAM wParam, LPARAM lParam) override {
            if (msg == WM_COMMAND && LOWORD(wParam) == id && HIWORD(wParam) == LBN_SELCHANGE) {
                selIndices = GetSelIndices();
                if (onSelect) onSelect(selIndices);
                    // Log list box selection
                    std::string logMsg = "[MT4 GUI] ListBox " + std::to_string(id) + " selected indices: ";
                    for (int idx : selIndices) logMsg += std::to_string(idx) + ",";
                    logWithTimestampToFile(logMsg.c_str(), "C:\\Temp\\dll_test_log.txt");
                return true;
            }
            return false;
        }
    };

    class GuiProgressBar : public GuiElement {
        int minValue = 0;
        int maxValue = 100;
        int curValue = 0;
    public:
        GuiProgressBar(int i, int minV = 0, int maxV = 100, int curV = 0) {
            id = i;
            minValue = minV;
            maxValue = maxV;
            curValue = curV;
        }
        void Create(HWND parent, int x, int y, int w, int h) override {
            hwnd = CreateWindowW(L"msctls_progress32", NULL, WS_VISIBLE | WS_CHILD, x, y, w, h, parent, (HMENU)id, NULL, NULL);
            SendMessageW(hwnd, PBM_SETRANGE, 0, MAKELPARAM(minValue, maxValue));
            SendMessageW(hwnd, PBM_SETPOS, curValue, 0);
        }
        void SetValue(int v) {
            curValue = v;
            if(hwnd) SendMessageW(hwnd, PBM_SETPOS, v, 0);
        }
        int GetValue() const {
            return curValue;
        }
        void SetRange(int minV, int maxV) {
            minValue = minV; maxValue = maxV;
            if(hwnd) SendMessageW(hwnd, PBM_SETRANGE, 0, MAKELPARAM(minValue, maxValue));
        }
    };

    enum class TabDock { Top, Bottom, Left, Right };

    class GuiTab : public GuiElement {
        TabDock dock = TabDock::Top;
        std::vector<std::wstring> pages;
        int curSel = 0;
        std::function<void(int)> onSelect;
    public:
        GuiTab(int i, TabDock d = TabDock::Top) {
            id = i;
            dock = d;
        }
        void AddPage(const std::wstring& name) { pages.push_back(name); }
        void Create(HWND parent, int x, int y, int w, int h) override {
            hwnd = CreateWindowW(L"SysTabControl32", NULL, WS_VISIBLE | WS_CHILD, x, y, w, h, parent, (HMENU)id, NULL, NULL);
            TCITEMW tie = {0};
            tie.mask = TCIF_TEXT;
            for(size_t i=0; i<pages.size(); ++i) {
                tie.pszText = (LPWSTR)pages[i].c_str();
                TabCtrl_InsertItem(hwnd, i, &tie);
            }
            TabCtrl_SetCurSel(hwnd, curSel);
        }
        void SetCurSel(int idx) {
            curSel = idx;
            if(hwnd) TabCtrl_SetCurSel(hwnd, idx);
        }
        int GetCurSel() const {
            if(hwnd) return TabCtrl_GetCurSel(hwnd);
            return curSel;
        }
        bool HandleMessage(UINT msg, WPARAM wParam, LPARAM lParam) override {
            if(msg == WM_NOTIFY && ((LPNMHDR)lParam)->idFrom == id) {
                LPNMHDR nmhdr = (LPNMHDR)lParam;
                if(nmhdr->code == TCN_SELCHANGE) {
                    curSel = GetCurSel();
                    if(onSelect) onSelect(curSel);
                    return true;
                }
            }
            return false;
        }
        void SetOnSelect(std::function<void(int)> handler) { onSelect = handler; }
        TabDock GetDock() const { return dock; }
        void SetDock(TabDock d) { dock = d; }
    };

    class GuiSlider : public GuiElement {
        int minValue = 0;
        int maxValue = 100;
        int curValue = 0;
    public:
        std::function<void(int)> onChange;
        GuiSlider(int i, int minV, int maxV, int curV) {
            id = i;
            minValue = minV;
            maxValue = maxV;
            curValue = curV;
        }
        void Create(HWND parent, int x, int y, int w, int h) override {
            hwnd = CreateWindowW(L"msctls_trackbar32", NULL, WS_VISIBLE | WS_CHILD | TBS_AUTOTICKS, x, y, w, h, parent, (HMENU)id, NULL, NULL);
            SendMessageW(hwnd, TBM_SETRANGE, TRUE, MAKELPARAM(minValue, maxValue));
            SendMessageW(hwnd, TBM_SETPOS, TRUE, curValue);
        }
        void SetValue(int v) {
            curValue = v;
            if(hwnd) SendMessageW(hwnd, TBM_SETPOS, TRUE, v);
        }
        int GetValue() const {
            if(hwnd) return (int)SendMessageW(hwnd, TBM_GETPOS, 0, 0);
            return curValue;
        }
        bool HandleMessage(UINT msg, WPARAM wParam, LPARAM lParam) override {
            if(msg == WM_HSCROLL && (HWND)lParam == hwnd) {
                curValue = (int)SendMessageW(hwnd, TBM_GETPOS, 0, 0);
                if(onChange) onChange(curValue);
                    // Log slider value change
                    logWithTimestampToFile(("[MT4 GUI] Slider " + std::to_string(id) + " value: " + std::to_string(curValue)).c_str(), "C:\\Temp\\dll_test_log.txt");
                return true;
            }
            return false;
        }
        void SetOnChange(std::function<void(int)> handler) { onChange = handler; }
    };

    class GuiGroupBox : public GuiElement {
        std::wstring text;
    public:
        GuiGroupBox(const std::wstring& t, int i) : text(t) { id = i; }
        void Create(HWND parent, int x, int y, int w, int h) override {
            hwnd = CreateWindowW(L"BUTTON", text.c_str(), WS_VISIBLE | WS_CHILD | BS_GROUPBOX, x, y, w, h, parent, (HMENU)id, NULL, NULL);
        }
        void SetText(const std::wstring& t) {
            text = t;
            if(hwnd) SetWindowTextW(hwnd, text.c_str());
        }
        std::wstring GetText() const { return text; }
    };
