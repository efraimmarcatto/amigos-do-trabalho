#ifndef GLOBAL_INPUT_H
#define GLOBAL_INPUT_H

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/core/class_db.hpp>

#include <atomic>

namespace godot {

class GlobalInput : public Object {
	GDCLASS(GlobalInput, Object);

protected:
	static void _bind_methods();

private:
	std::atomic<int> key_count{0};
	std::atomic<int> click_count{0};

public:
	GlobalInput();
	~GlobalInput();

	int get_key_count() const;
	int get_click_count() const;
	void reset_counts();
	void start_hooks();
	void stop_hooks();

	// Internal helpers for platform hook callbacks
	void _increment_key_count();
	void _increment_click_count();
};

} // namespace godot

#endif // GLOBAL_INPUT_H
