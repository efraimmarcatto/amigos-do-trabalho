# PRD: Desktop Virtual Pet (Godot 4.6)

## Introduction

A virtual desktop pet that lives as a transparent overlay on the user's screen, rewarding productivity by converting real keyboard and mouse activity into in-game coins. The pet reacts visually to the player's activity level, becoming happier when the user is productive and sadder when idle. Since Godot cannot capture input when its window is out of focus, a C/C++ GDExtension hooks into OS-level input events and exposes them to GDScript. Primary platform is Windows, with Linux as a secondary target.

## Goals

- Deliver a transparent, always-on-top desktop overlay with a clickable pet and click-through empty areas
- Capture system-wide keyboard strokes and mouse clicks via a C/C++ GDExtension, even when the Godot window is not focused
- Convert captured input into a coins/money currency that accumulates over time
- Implement passive coin decay so the pet degrades (gets hungry/sad) during idle periods
- Allow the user to spend coins on basic pet interactions to restore or boost pet mood
- Ship a working MVP for Windows; provide a Linux implementation path

## User Stories

### US-001: Transparent Always-On-Top Window
**Description:** As a user, I want the pet to float on my desktop without blocking my work, so that it feels like a companion rather than an obstruction.

**Acceptance Criteria:**
- [ ] Godot window has a fully transparent background (no visible chrome or background color)
- [ ] Window is set to always-on-top
- [ ] Clicking on empty/transparent areas passes the click through to the application underneath
- [ ] Clicking directly on the pet sprite is captured by Godot (not passed through)
- [ ] Window renders correctly on Windows 10/11

### US-002: GDExtension — Windows Global Input Hook
**Description:** As a developer, I need a GDExtension written in C/C++ that captures system-wide keyboard and mouse events on Windows, so that GDScript can track user activity regardless of window focus.

**Acceptance Criteria:**
- [ ] GDExtension uses Windows `SetWindowsHookEx` with `WH_KEYBOARD_LL` and `WH_MOUSE_LL` to capture global input
- [ ] Hook runs on a dedicated thread to avoid blocking Godot's main loop
- [ ] Extension exposes the following to GDScript via a registered singleton (e.g., `GlobalInput`):
  - `get_key_count() -> int` — total key presses since last poll
  - `get_click_count() -> int` — total mouse clicks since last poll
  - `reset_counts()` — resets both counters to zero
- [ ] Hook is installed on `_ready()` and cleanly uninstalled on `_exit_tree()` or application quit
- [ ] Extension compiles as a `.gdextension` loadable by Godot 4.6
- [ ] No memory leaks or crashes after 1 hour of continuous use

### US-003: GDExtension — Linux Global Input Capture
**Description:** As a developer, I need the GDExtension to also support Linux so the game works on a secondary platform.

**Acceptance Criteria:**
- [ ] Linux implementation uses X11 (`XRecord` extension or `/dev/input` with appropriate permissions) to capture global key and mouse events
- [ ] Exposes the same `GlobalInput` API as the Windows version
- [ ] Compiles and loads on Linux (X11; Wayland support is a non-goal)
- [ ] Falls back gracefully or logs a clear error if permissions are insufficient

### US-004: Coin/Money System
**Description:** As a user, I want my keystrokes and clicks to earn me coins so that I feel rewarded for being productive.

**Acceptance Criteria:**
- [ ] A GDScript system polls `GlobalInput` at a fixed interval (e.g., every 1 second)
- [ ] Each key press earns a configurable amount of coins (default: 1 coin per keystroke)
- [ ] Each mouse click earns a configurable amount of coins (default: 1 coin per click)
- [ ] Accumulated coins are displayed in a small, unobtrusive UI element near the pet
- [ ] Coin total persists across sessions (saved to a local file)

### US-005: Passive Coin Decay
**Description:** As a user, I want my coins to slowly drain over time so that I need to stay active to keep my pet happy.

**Acceptance Criteria:**
- [ ] Coins decay at a configurable rate (default: 1 coin per 30 seconds of zero input)
- [ ] Decay only occurs when no keystrokes or clicks have been registered in the current polling window
- [ ] Coins cannot go below zero
- [ ] Decay rate is tuned so casual usage sustains the pet (not punishing)

### US-006: Pet Visual States
**Description:** As a user, I want the pet to visually react to my activity level so I can tell at a glance how it's doing.

**Acceptance Criteria:**
- [ ] Pet has at least 3 visual states: Happy (high coins/active), Neutral (moderate), Sad/Hungry (low coins/idle)
- [ ] State thresholds are configurable
- [ ] Pet transitions between states smoothly (e.g., sprite swap or simple animation)
- [ ] Pet state updates in real time as coins change

### US-007: Spend Coins on Pet Interactions
**Description:** As a user, I want to click the pet and spend coins to feed or play with it, boosting its mood.

**Acceptance Criteria:**
- [ ] Clicking the pet opens a small context menu or radial menu with interaction options (e.g., "Feed", "Play")
- [ ] Each interaction costs a set amount of coins (configurable)
- [ ] Successful interaction triggers a short visual reaction (animation or particle effect)
- [ ] Interaction temporarily boosts the pet's mood state
- [ ] Cannot interact if insufficient coins (button grayed out or hidden)

### US-008: Save/Load Pet State
**Description:** As a user, I want my pet's state and coins to persist when I close and reopen the game.

**Acceptance Criteria:**
- [ ] On quit, save coin total and current pet state to a local JSON file
- [ ] On launch, load saved state and restore pet
- [ ] Handle missing or corrupted save file gracefully (start fresh with defaults)

## Functional Requirements

- FR-1: The Godot project must use a transparent, borderless, always-on-top window with per-pixel click-through on transparent regions
- FR-2: A C/C++ GDExtension must capture global keyboard and mouse input on Windows using low-level hooks (`SetWindowsHookEx`)
- FR-3: The GDExtension must expose a `GlobalInput` singleton to GDScript with `get_key_count()`, `get_click_count()`, and `reset_counts()` methods
- FR-4: A Linux implementation of the GDExtension must use X11 APIs (`XRecord` or `/dev/input`) to provide the same interface
- FR-5: A coin system must convert captured input counts into currency at configurable rates
- FR-6: Coins must passively decay during idle periods at a configurable rate
- FR-7: The pet must display at least 3 visual states (happy, neutral, sad) driven by coin balance
- FR-8: The user must be able to click the pet to spend coins on interactions that boost mood
- FR-9: Coin balance and pet state must persist to disk between sessions

## Non-Goals

- No multiplayer or online features
- No Wayland support (X11 only for Linux)
- No pet evolution, growth stages, or multiple pet types (MVP)
- No shop, cosmetics, or unlockables
- No sound or audio (MVP)
- No system tray icon or minimize-to-tray
- No anti-cheat or rate-limiting on input (trust the user)
- No macOS support

## Technical Considerations

- **Godot 4.6** is the target engine version; use its native GDExtension C API (godot-cpp bindings)
- **Transparent window:** Godot 4.x supports `display/window/per_pixel_transparency/allowed` and `display/window/size/transparent` project settings. The window must also be borderless and always-on-top
- **Click-through:** On Windows, use `SetWindowLong` with `WS_EX_TRANSPARENT` + `WS_EX_LAYERED` on transparent pixels. Godot 4.x has partial support via `mouse_passthrough_polygon` on the Window node — evaluate if this is sufficient or if native Win32 calls are needed in the GDExtension
- **Global input hooks (Windows):** `SetWindowsHookEx` with `WH_KEYBOARD_LL` and `WH_MOUSE_LL` requires a message pump on the hook thread. Use a dedicated thread with its own message loop
- **Global input hooks (Linux):** `XRecord` extension is the cleanest approach for X11. `/dev/input` requires root or `input` group membership. Document the permission requirements
- **Thread safety:** Hook callbacks run on a separate thread; use atomic counters or mutexes for the count variables that GDScript polls from the main thread
- **GDExtension structure:** Register a singleton class (e.g., `GlobalInput`) via `gdextension_init`. Use `#ifdef _WIN32` / `#ifdef __linux__` for platform-specific implementations
- **Build system:** Use SCons (consistent with godot-cpp) or CMake for the GDExtension build

## Success Metrics

- Pet renders on a transparent overlay without visual artifacts on Windows 10/11
- GDExtension successfully captures >95% of keystrokes and clicks while the user works in other applications
- Coin system correctly tallies input and decays during idle, with state persisting across restarts
- Pet visually reacts to activity within 2 seconds of state threshold changes
- No measurable performance impact on the user's system (<1% CPU usage when idle)

## Open Questions

- Should the pet be draggable to reposition on screen, or fixed to a corner?
- What art style / pet character should be used for the MVP sprite?
- Should there be a configurable hotkey to show/hide the pet?
- Should coin earn rates scale down for rapid/repetitive input (anti-macro)?
- What is the ideal polling interval for `GlobalInput` — 1 second, 500ms, or frame-based?
