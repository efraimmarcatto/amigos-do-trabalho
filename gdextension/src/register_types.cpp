#include "register_types.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/engine.hpp>

#include "global_input.h"

using namespace godot;

static GlobalInput *global_input_singleton = nullptr;

void initialize_global_input_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	ClassDB::register_class<GlobalInput>();

	global_input_singleton = memnew(GlobalInput);
	Engine::get_singleton()->register_singleton("GlobalInput", global_input_singleton);
}

void uninitialize_global_input_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	if (global_input_singleton) {
		Engine::get_singleton()->unregister_singleton("GlobalInput");
		memdelete(global_input_singleton);
		global_input_singleton = nullptr;
	}
}

extern "C" {
GDExtensionBool GDE_EXPORT global_input_library_init(
		GDExtensionInterfaceGetProcAddress p_get_proc_address,
		const GDExtensionClassLibraryPtr p_library,
		GDExtensionInitialization *r_initialization) {
	godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

	init_obj.register_initializer(initialize_global_input_module);
	init_obj.register_terminator(uninitialize_global_input_module);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

	return init_obj.init();
}
}
