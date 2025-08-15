class GuiProgressBar : public GuiElement {
    int minValue = 0;
    int maxValue = 100;
    int curValue = 0;
    int xpos, ypos, width, height;
public:
    GuiProgressBar(int i, int x, int y, int w, int h, int minV = 0, int maxV = 100, int curV = 0)
        : xpos(x), ypos(y), width(w), height(h), minValue(minV), maxValue(maxV), curValue(curV) { id = i; }
    void Create(HWND parent) override {
        hwnd = CreateWindowW(L"msctls_progress32", NULL, WS_VISIBLE | WS_CHILD, xpos, ypos, width, height, parent, (HMENU)id, NULL, NULL);
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
// Tab docking options
enum class TabDock { Top, Bottom, Left, Right };

class GuiTab : public GuiElement {
    int id;
    TabDock dock = TabDock::Top;
    std::vector<std::wstring> pages;
    int xpos, ypos, width, height;
    int curSel = 0;
    std::function<void(int)> onSelect;
public:
    GuiTab(int i, int x, int y, int w, int h, TabDock d = TabDock::Top)
        : id(i), xpos(x), ypos(y), width(w), height(h), dock(d) {}
    void AddPage(const std::wstring& name) { pages.push_back(name); }
    void Create(HWND parent) override {
        hwnd = CreateWindowW(L"SysTabControl32", NULL, WS_VISIBLE | WS_CHILD, xpos, ypos, width, height, parent, (HMENU)id, NULL, NULL);
        TCITEMW tie = {0};
        tie.mask = TCIF_TEXT;
        for(size_t i=0; i<pages.size(); ++i) {
            tie.pszText = (LPWSTR)pages[i].c_str();
            TabCtrl_InsertItem(hwnd, i, &tie);
        }
        TabCtrl_SetCurSel(hwnd, curSel);
        // Docking logic (visual only, developer can choose position)
        // Top: default, Bottom: move to bottom, Left/Right: vertical tabs (requires custom drawing)
        // For now, just position based on dock
        // (Advanced: implement vertical tabs if needed)
    }
    void SetCurSel(int idx) {
        curSel = idx;
        if(hwnd) TabCtrl_SetCurSel(hwnd, idx);
    }
    int GetCurSel() const {
        if(hwnd) return TabCtrl_GetCurSel(hwnd);
        return curSel;
    }
    void HandleMessage(UINT msg, WPARAM wParam, LPARAM lParam) override {
        if(msg == WM_NOTIFY && ((LPNMHDR)lParam)->idFrom == id) {
            LPNMHDR nmhdr = (LPNMHDR)lParam;
            if(nmhdr->code == TCN_SELCHANGE) {
                curSel = GetCurSel();
                if(onSelect) onSelect(curSel);
            }
        }
    }
    void SetOnSelect(std::function<void(int)> handler) { onSelect = handler; }
    TabDock GetDock() const { return dock; }
    void SetDock(TabDock d) { dock = d; }
};
// OOP GUI base and button with event handler
#pragma once
#include <windows.h>
#include <string>
#include <functional>

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
    void Create(HWND parent, int x, int y, int w, int h) override {
        hwnd = CreateWindowW(L"BUTTON", text.c_str(), WS_VISIBLE | WS_CHILD | BS_PUSHBUTTON, x, y, w, h, parent, (HMENU)id, NULL, NULL);
    }
    bool HandleMessage(UINT msg, WPARAM wParam, LPARAM lParam) override {
        if (msg == WM_COMMAND && LOWORD(wParam) == id && HIWORD(wParam) == BN_CLICKED) {
            if (onClick) onClick();
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
            return true;
        }
        return false;
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
    bool selected;
    std::function<void(bool)> onSelect;
public:
    GuiRadioButton(const std::wstring& t, int i, int x, int y, int w, int h)
        : text(t), selected(false) {
        id = i; xpos = x; ypos = y; width = w; height = h;
    }
    void Create(HWND parent) override {
        hwnd = CreateWindowW(L"BUTTON", text.c_str(),
            WS_VISIBLE | WS_CHILD | BS_AUTORADIOBUTTON,
            xpos, ypos, width, height, parent, (HMENU)id, NULL, NULL);
        SendMessageW(hwnd, BM_SETCHECK, selected ? BST_CHECKED : BST_UNCHECKED, 0);
    }
    void SetChecked(bool check) {
        selected = check;
        if (hwnd) SendMessageW(hwnd, BM_SETCHECK, check ? BST_CHECKED : BST_UNCHECKED, 0);
    }
    bool GetChecked() const { return selected; }
    void HandleMessage(WPARAM wParam) override {
        if (LOWORD(wParam) == id) {
            selected = SendMessageW(hwnd, BM_GETCHECK, 0, 0) == BST_CHECKED;
            if (onSelect) onSelect(selected);
        }
    }
    void SetOnSelect(std::function<void(bool)> handler) { onSelect = handler; }
};
};

class GuiSlider : public GuiElement {
    int minValue = 0;
    int maxValue = 100;
    int curValue = 0;
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
    void HandleMessage(UINT msg, WPARAM wParam, LPARAM lParam) override {
        if(msg == WM_HSCROLL && (HWND)lParam == hwnd) {
            curValue = (int)SendMessageW(hwnd, TBM_GETPOS, 0, 0);
            if(onChange) onChange(curValue);
        }
    }
    void SetOnChange(std::function<void(int)> handler) { onChange = handler; }
};
};

class GuiGroupBox : public GuiElement {
    std::wstring text;
    int id;
    int xpos, ypos, width, height;
public:
    GuiGroupBox(const std::wstring& t, int i, int x, int y, int w, int h)
        : text(t), id(i), xpos(x), ypos(y), width(w), height(h) {}
    void Create(HWND parent) override {
        hwnd = CreateWindowW(L"BUTTON", text.c_str(), WS_VISIBLE | WS_CHILD | BS_GROUPBOX, xpos, ypos, width, height, parent, (HMENU)id, NULL, NULL);
    }
    void SetText(const std::wstring& t) {
        text = t;
        if(hwnd) SetWindowTextW(hwnd, text.c_str());
    }
    std::wstring GetText() const { return text; }
};
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
    void Create(HWND parent, int x, int y, int w, int h) override {
        hwnd = CreateWindowW(L"msctls_progress32", NULL, WS_VISIBLE | WS_CHILD, x, y, w, h, parent, (HMENU)id, NULL, NULL);
    }
};
