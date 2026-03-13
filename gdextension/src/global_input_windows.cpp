#ifdef _WIN32

#include "global_input.h"

#include <godot_cpp/variant/utility_functions.hpp>

#include <windows.h>
#include <thread>
#include <atomic>

using namespace godot;

// File-static state for the Windows hook thread
static GlobalInput *s_instance = nullptr;
static HHOOK s_keyboard_hook = nullptr;
static HHOOK s_mouse_hook = nullptr;
static DWORD s_hook_thread_id = 0;
static std::thread s_hook_thread;
static std::atomic<bool> s_running{false};

static LRESULT CALLBACK keyboard_hook_proc(int nCode, WPARAM wParam, LPARAM lParam) {
	if (nCode >= 0 && s_instance != nullptr) {
		if (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN) {
			s_instance->_increment_key_count();
		}
	}
	return CallNextHookEx(s_keyboard_hook, nCode, wParam, lParam);
}

static LRESULT CALLBACK mouse_hook_proc(int nCode, WPARAM wParam, LPARAM lParam) {
	if (nCode >= 0 && s_instance != nullptr) {
		if (wParam == WM_LBUTTONDOWN || wParam == WM_RBUTTONDOWN || wParam == WM_MBUTTONDOWN) {
			s_instance->_increment_click_count();
		}
	}
	return CallNextHookEx(s_mouse_hook, nCode, wParam, lParam);
}

static void hook_thread_func() {
	s_keyboard_hook = SetWindowsHookExW(WH_KEYBOARD_LL, keyboard_hook_proc, nullptr, 0);
	if (s_keyboard_hook == nullptr) {
		UtilityFunctions::print("GlobalInput: Failed to install keyboard hook, error: ", (int64_t)GetLastError());
	}

	s_mouse_hook = SetWindowsHookExW(WH_MOUSE_LL, mouse_hook_proc, nullptr, 0);
	if (s_mouse_hook == nullptr) {
		UtilityFunctions::print("GlobalInput: Failed to install mouse hook, error: ", (int64_t)GetLastError());
	}

	// Low-level hooks require a message loop on the installing thread
	MSG msg;
	while (s_running.load(std::memory_order_relaxed)) {
		BOOL ret = GetMessage(&msg, nullptr, 0, 0);
		if (ret == 0 || ret == -1) {
			break;
		}
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}

	// Cleanup hooks on thread exit
	if (s_keyboard_hook != nullptr) {
		UnhookWindowsHookEx(s_keyboard_hook);
		s_keyboard_hook = nullptr;
	}
	if (s_mouse_hook != nullptr) {
		UnhookWindowsHookEx(s_mouse_hook);
		s_mouse_hook = nullptr;
	}
}

void GlobalInput::start_hooks() {
	if (s_running.load(std::memory_order_relaxed)) {
		UtilityFunctions::print("GlobalInput: Hooks already running");
		return;
	}

	s_instance = this;
	s_running.store(true, std::memory_order_relaxed);

	s_hook_thread = std::thread([]() {
		s_hook_thread_id = GetCurrentThreadId();
		hook_thread_func();
	});

	UtilityFunctions::print("GlobalInput: Windows hooks started");
}

void GlobalInput::stop_hooks() {
	if (!s_running.load(std::memory_order_relaxed)) {
		return;
	}

	s_running.store(false, std::memory_order_relaxed);

	// Post WM_QUIT to the hook thread to break out of GetMessage loop
	if (s_hook_thread_id != 0) {
		PostThreadMessage(s_hook_thread_id, WM_QUIT, 0, 0);
	}

	if (s_hook_thread.joinable()) {
		s_hook_thread.join();
	}

	s_hook_thread_id = 0;
	s_instance = nullptr;

	UtilityFunctions::print("GlobalInput: Windows hooks stopped");
}

#endif // _WIN32
