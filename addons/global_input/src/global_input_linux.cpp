#ifdef __linux__

#include "global_input.h"

#include <godot_cpp/variant/utility_functions.hpp>

#include <thread>
#include <atomic>

// X11 and XRecord headers
#include <X11/Xlib.h>
#include <X11/extensions/record.h>
#include <X11/Xproto.h>

using namespace godot;

// File-static state for the Linux capture thread
static GlobalInput *s_instance = nullptr;
static Display *s_ctrl_display = nullptr;
static Display *s_data_display = nullptr;
static XRecordContext s_record_context = 0;
static std::thread s_capture_thread;
static std::atomic<bool> s_running{false};

static void xrecord_callback(XPointer closure, XRecordInterceptData *hook) {
	if (hook->category != XRecordFromServer) {
		XRecordFreeData(hook);
		return;
	}

	if (s_instance == nullptr) {
		XRecordFreeData(hook);
		return;
	}

	xEvent *event = (xEvent *)hook->data;
	int event_type = event->u.u.type;

	switch (event_type) {
		case KeyPress:
			s_instance->_increment_key_count();
			break;
		case ButtonPress:
			s_instance->_increment_click_count();
			break;
		default:
			break;
	}

	XRecordFreeData(hook);
}

static void capture_thread_func() {
	// XRecordEnableContext blocks until the context is disabled
	if (!XRecordEnableContext(s_data_display, s_record_context, xrecord_callback, nullptr)) {
		UtilityFunctions::print("GlobalInput: XRecordEnableContext failed");
	}
}

void GlobalInput::start_hooks() {
	if (s_running.load(std::memory_order_relaxed)) {
		UtilityFunctions::print("GlobalInput: Hooks already running");
		return;
	}

	// XRecord requires two separate Display connections
	s_ctrl_display = XOpenDisplay(nullptr);
	s_data_display = XOpenDisplay(nullptr);

	if (s_ctrl_display == nullptr || s_data_display == nullptr) {
		UtilityFunctions::print("GlobalInput: Failed to open X11 display connections. Is DISPLAY set?");
		if (s_ctrl_display != nullptr) {
			XCloseDisplay(s_ctrl_display);
			s_ctrl_display = nullptr;
		}
		if (s_data_display != nullptr) {
			XCloseDisplay(s_data_display);
			s_data_display = nullptr;
		}
		return;
	}

	// Check if XRecord extension is available
	int major, minor;
	if (!XRecordQueryVersion(s_ctrl_display, &major, &minor)) {
		UtilityFunctions::print("GlobalInput: XRecord extension not available. Cannot capture global input.");
		XCloseDisplay(s_ctrl_display);
		XCloseDisplay(s_data_display);
		s_ctrl_display = nullptr;
		s_data_display = nullptr;
		return;
	}

	// Set up XRecord to capture key and mouse button events
	XRecordRange *range = XRecordAllocRange();
	if (range == nullptr) {
		UtilityFunctions::print("GlobalInput: Failed to allocate XRecord range");
		XCloseDisplay(s_ctrl_display);
		XCloseDisplay(s_data_display);
		s_ctrl_display = nullptr;
		s_data_display = nullptr;
		return;
	}

	range->device_events.first = KeyPress;
	range->device_events.last = ButtonPress;

	XRecordClientSpec client_spec = XRecordAllClients;
	s_record_context = XRecordCreateContext(s_ctrl_display, 0, &client_spec, 1, &range, 1);
	XFree(range);

	if (s_record_context == 0) {
		UtilityFunctions::print("GlobalInput: Failed to create XRecord context. Check permissions (input group membership may be needed).");
		XCloseDisplay(s_ctrl_display);
		XCloseDisplay(s_data_display);
		s_ctrl_display = nullptr;
		s_data_display = nullptr;
		return;
	}

	s_instance = this;
	s_running.store(true, std::memory_order_relaxed);

	s_capture_thread = std::thread(capture_thread_func);

	UtilityFunctions::print("GlobalInput: Linux XRecord capture started");
}

void GlobalInput::stop_hooks() {
	if (!s_running.load(std::memory_order_relaxed)) {
		return;
	}

	s_running.store(false, std::memory_order_relaxed);

	// Disable the record context to unblock XRecordEnableContext in the capture thread
	if (s_ctrl_display != nullptr && s_record_context != 0) {
		XRecordDisableContext(s_ctrl_display, s_record_context);
		XFlush(s_ctrl_display);
	}

	if (s_capture_thread.joinable()) {
		s_capture_thread.join();
	}

	// Free the record context
	if (s_ctrl_display != nullptr && s_record_context != 0) {
		XRecordFreeContext(s_ctrl_display, s_record_context);
		s_record_context = 0;
	}

	// Close display connections
	if (s_data_display != nullptr) {
		XCloseDisplay(s_data_display);
		s_data_display = nullptr;
	}
	if (s_ctrl_display != nullptr) {
		XCloseDisplay(s_ctrl_display);
		s_ctrl_display = nullptr;
	}

	s_instance = nullptr;

	UtilityFunctions::print("GlobalInput: Linux XRecord capture stopped");
}

#endif // __linux__
