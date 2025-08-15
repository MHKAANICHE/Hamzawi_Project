

#include <windows.h>
#include <thread>
#include <vector>
#include "GuiElements.hpp"

// AUTOGEN START
// Auto-generated C++ WinAPI GUI code from HTML sketch
void CreateDemoGuiElements(HWND parent) {
	std::vector<GuiElement*> elements;
	int y = 10;
	// Label: Text Input: for input input_test
	auto edit_input_test = new GuiEdit(L"CopilotTest", 108); elements.push_back(edit_input_test); edit_input_test->Create(parent, 10, 10, 200, 24); y += 30;
	// Label: Checkbox: for checkbox checkbox_test
	auto check_checkbox_test = new GuiCheckBox(L"checkbox_test", 109); elements.push_back(check_checkbox_test); check_checkbox_test->Create(parent, 10, 10, 100, 24); y += 30;
	// Label: Radio 1: for radio radio_test1
	auto radio_radio_test1 = new GuiRadioButton(L"radio_test1", 110, 10, 10, 100, 24); elements.push_back(radio_radio_test1); radio_radio_test1->Create(parent, 10, 10, 100, 24); y += 30;
	// Label: Radio 2: for radio radio_test2
	auto radio_radio_test2 = new GuiRadioButton(L"radio_test2", 111, 10, 10, 100, 24); elements.push_back(radio_radio_test2); radio_radio_test2->Create(parent, 10, 10, 100, 24); y += 30;
	// Label: Slider: for slider slider_test
	auto slider_slider_test = new GuiSlider(112, 0, 100, 25); elements.push_back(slider_slider_test); slider_slider_test->Create(parent, 10, 10, 200, 24); y += 30;

    // AUTOGEN END
}

LRESULT CALLBACK DemoWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
	switch (msg) {
		case WM_CLOSE:
			DestroyWindow(hwnd);
			break;
		case WM_DESTROY:
			PostQuitMessage(0);
			break;
		default:
			return DefWindowProc(hwnd, msg, wParam, lParam);
	}
	return 0;
}

void ShowDemoWindow() {
	HINSTANCE hInstance = GetModuleHandle(NULL);
	LPCWSTR CLASS_NAME = L"DemoWinAPIClass";

	WNDCLASSW wc = {};
	wc.lpfnWndProc = DemoWndProc;
	wc.hInstance = hInstance;
	wc.lpszClassName = CLASS_NAME;
	wc.hCursor = LoadCursorW(NULL, (LPCWSTR)IDC_ARROW);
	wc.hbrBackground = (HBRUSH)(COLOR_WINDOW+1);
	RegisterClassW(&wc);

	HWND hwnd = CreateWindowExW(0, CLASS_NAME, L"MT4 WinAPI Demo", WS_POPUP | WS_VISIBLE,
		CW_USEDEFAULT, CW_USEDEFAULT, 600, 500, NULL, NULL, hInstance, NULL);

	if (!hwnd) {
		MessageBoxW(NULL, L"Failed to create WinAPI window!", L"DLL Error", MB_OK | MB_ICONERROR);
		return;
	}

	SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 600, 500, SWP_SHOWWINDOW);
	ShowWindow(hwnd, SW_SHOW);
	UpdateWindow(hwnd);

	// Place generated controls inside the window
	CreateDemoGuiElements(hwnd);

	// Message loop
	MSG msg;
	while (GetMessageW(&msg, NULL, 0, 0)) {
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}
}

extern "C" __declspec(dllexport) void CreateDemoGui(HWND parent) {
	std::thread(ShowDemoWindow).detach();
}

