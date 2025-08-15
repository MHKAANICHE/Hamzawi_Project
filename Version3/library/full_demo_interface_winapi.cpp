
#include <vector>
#include "GuiElements.hpp"

// AUTOGEN START


#include <windows.h>
#include <thread>

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

	HWND hwnd = CreateWindowExW(0, CLASS_NAME, L"MT4 WinAPI Demo", WS_OVERLAPPEDWINDOW,
		CW_USEDEFAULT, CW_USEDEFAULT, 400, 150, NULL, NULL, hInstance, NULL);

	ShowWindow(hwnd, SW_SHOW);
	UpdateWindow(hwnd);

	// Place generated controls inside the window
	std::vector<GuiElement*> elements;
	int y = 10;
	auto edit_input_test = new GuiEdit(L"CopilotTest", 108);
	elements.push_back(edit_input_test);
	edit_input_test->Create(hwnd, 10, 10, 200, 24);

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
// AUTOGEN END
