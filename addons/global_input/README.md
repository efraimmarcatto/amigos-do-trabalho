# GlobalInput

A Godot 4 GDExtension plugin that captures system-wide keyboard and mouse input outside the Godot window. This enables tracking user activity (key presses, mouse clicks) even when the Godot application does not have focus — useful for desktop pets, productivity trackers, and activity-driven game mechanics.

## Prerequisites

- **Godot 4.6+** with GDExtension support
- **godot-cpp** submodule (initialized and built for your target platform)
- **SCons** build system
- **C++ compiler** (GCC/Clang on Linux, MSVC on Windows)

### Platform Dependencies

| Platform | Libraries Required |
|----------|-------------------|
| Linux    | `libX11-dev`, `libXtst-dev` (X11 and XRecord extension) |
| Windows  | `user32.lib` (included with Windows SDK) |

## Installation

1. Copy the `addons/global_input/` folder into your project's `addons/` directory.
2. In Godot, go to **Project > Project Settings > Plugins**.
3. Enable the **GlobalInput** plugin.

The plugin automatically registers `GlobalInput` as an autoload singleton, making it accessible from any script.

## Building

The native extension must be compiled before use. From the `addons/global_input/` directory:

```bash
# Initialize godot-cpp (if not already done)
cd godot-cpp
scons platform=<your_platform>
cd ..

# Build for Linux
scons platform=linux

# Build for Windows
scons platform=windows
```

Set the `GODOT_CPP_PATH` environment variable if your godot-cpp checkout is not at `./godot-cpp`:

```bash
GODOT_CPP_PATH=/path/to/godot-cpp scons platform=linux
```

Compiled binaries are output to `bin/`.

## API Reference

All methods are available on the `GlobalInput` singleton.

| Method | Description |
|--------|-------------|
| `start_hooks()` | Start capturing system-wide keyboard and mouse input. Spawns a background thread for input monitoring. |
| `stop_hooks()` | Stop capturing input and clean up the background thread and platform resources. |
| `get_key_count() -> int` | Return the number of key presses recorded since the last reset. |
| `get_click_count() -> int` | Return the number of mouse clicks recorded since the last reset. |
| `reset_counts()` | Reset both key and click counters to zero. |

## Usage Example

A typical pattern is to poll the counts on a timer, consume them, and reset:

```gdscript
extends Node

@onready var poll_timer := Timer.new()

func _ready() -> void:
    GlobalInput.start_hooks()
    poll_timer.wait_time = 1.0
    poll_timer.timeout.connect(_on_poll_timeout)
    add_child(poll_timer)
    poll_timer.start()

func _on_poll_timeout() -> void:
    var keys := GlobalInput.get_key_count()
    var clicks := GlobalInput.get_click_count()
    GlobalInput.reset_counts()

    # Convert raw input counts into application logic
    var coins_earned := keys + clicks
    if coins_earned > 0:
        print("Earned %d coins this interval" % coins_earned)

func _exit_tree() -> void:
    GlobalInput.stop_hooks()
```

## Platform Notes

### Linux

- **Requires X11** — Wayland is not supported. The extension uses the XRecord protocol to intercept key and mouse events globally.
- The user may need to be a member of the **input** group for XRecord permissions, depending on the distribution and security configuration.
- Two separate X11 display connections are opened (required by XRecord).
- The `DISPLAY` environment variable must be set.

### Windows

- Uses **low-level hooks** (`WH_KEYBOARD_LL`, `WH_MOUSE_LL`) via `SetWindowsHookExW`.
- A dedicated thread runs a Win32 message loop, which is required for low-level hooks to function.
- The hook thread is cleanly terminated via `PostThreadMessage(WM_QUIT)` when `stop_hooks()` is called.
- Captures left, right, and middle mouse button clicks.

## License

MIT License — see LICENSE file.
