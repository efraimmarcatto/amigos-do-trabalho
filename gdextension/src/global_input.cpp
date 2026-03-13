#include "global_input.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void GlobalInput::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_key_count"), &GlobalInput::get_key_count);
	ClassDB::bind_method(D_METHOD("get_click_count"), &GlobalInput::get_click_count);
	ClassDB::bind_method(D_METHOD("reset_counts"), &GlobalInput::reset_counts);
	ClassDB::bind_method(D_METHOD("start_hooks"), &GlobalInput::start_hooks);
	ClassDB::bind_method(D_METHOD("stop_hooks"), &GlobalInput::stop_hooks);
}

GlobalInput::GlobalInput() {
}

GlobalInput::~GlobalInput() {
	stop_hooks();
}

int GlobalInput::get_key_count() const {
	return key_count.load(std::memory_order_relaxed);
}

int GlobalInput::get_click_count() const {
	return click_count.load(std::memory_order_relaxed);
}

void GlobalInput::reset_counts() {
	key_count.store(0, std::memory_order_relaxed);
	click_count.store(0, std::memory_order_relaxed);
}

void GlobalInput::_increment_key_count() {
	key_count.fetch_add(1, std::memory_order_relaxed);
}

void GlobalInput::_increment_click_count() {
	click_count.fetch_add(1, std::memory_order_relaxed);
}

#if !defined(_WIN32) && !defined(__linux__)
void GlobalInput::start_hooks() {
	UtilityFunctions::print("GlobalInput: start_hooks() - no platform implementation for this OS");
}

void GlobalInput::stop_hooks() {
	UtilityFunctions::print("GlobalInput: stop_hooks() - no platform implementation for this OS");
}
#endif
