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
    int id;
public:
    GuiRadioButton(const std::wstring& t, int i) : text(t), id(i) {}
    void Create(HWND parent, int x, int y, int w, int h) override {
        hwnd = CreateWindowW(L"BUTTON", text.c_str(), WS_VISIBLE | WS_CHILD | BS_RADIOBUTTON, x, y, w, h, parent, (HMENU)id, NULL, NULL);
    }
};

class GuiSlider : public GuiElement {
    int id;
public:
    GuiSlider(int i) : id(i) {}
    void Create(HWND parent, int x, int y, int w, int h) override {
        hwnd = CreateWindowW(L"msctls_trackbar32", NULL, WS_VISIBLE | WS_CHILD | TBS_AUTOTICKS, x, y, w, h, parent, (HMENU)id, NULL, NULL);
    }
};

class GuiGroupBox : public GuiElement {
    std::wstring text;
    int id;
public:
    GuiGroupBox(const std::wstring& t, int i) : text(t), id(i) {}
    void Create(HWND parent, int x, int y, int w, int h) override {
        hwnd = CreateWindowW(L"BUTTON", text.c_str(), WS_VISIBLE | WS_CHILD | BS_GROUPBOX, x, y, w, h, parent, (HMENU)id, NULL, NULL);
    }
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
