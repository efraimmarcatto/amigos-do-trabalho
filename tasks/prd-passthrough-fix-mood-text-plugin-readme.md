# PRD: Passthrough Polygon Fix, Mood Text, GlobalInput Plugin & Project README

## Introduction

This PRD covers four interconnected improvements to Amigos do Trabalho:

1. **Passthrough polygon bug fix** — Overlapping sprites (e.g., pet standing in front of furniture) create transparent holes showing the desktop behind them. The polygon merge logic in `_update_passthrough()` must produce a solid union so overlapping areas remain opaque.

2. **Mood bubble emotion text** — The current mood bubble uses only colored circles (blue/yellow/green), which is confusing. Add the written mood name ("Sad", "Neutral", "Happy") and architect the system so emotion images (small expressive faces) can be added later via node configuration.

3. **GlobalInput GDExtension plugin packaging** — Extract the global input C++ extension into a self-contained Godot plugin with `plugin.cfg`, ready to drop into any project's `addons/` folder and enable via Project Settings. Write a README for standalone repository use.

4. **Project README** — Write comprehensive English documentation for Amigos do Trabalho covering features, architecture, configuration, interactions, animations, and pet creation.

## Goals

- Eliminate the transparency bug where overlapping sprites show the desktop through them
- Make the passthrough polygon system robust against edge cases (fully contained rects, degenerate polygons)
- Make pet emotions instantly understandable by displaying mood text in the bubble
- Design emotion display so images can be swapped in later without code changes
- Package GlobalInput as a reusable, self-contained Godot plugin with clear installation docs
- Provide comprehensive English project documentation for new contributors and users

## User Stories

### US-001: Fix passthrough polygon merge for overlapping sprites
**Description:** As a user, I want overlapping sprites (pet + furniture) to remain fully visible so I don't see the desktop through them.

**Acceptance Criteria:**
- [ ] When the pet stands in front of or overlaps with furniture, no transparent holes appear
- [ ] The `_update_passthrough()` function produces a single solid polygon union from all interactive element rects
- [ ] Edge case: a rect fully contained inside another does not create a hole
- [ ] Edge case: degenerate or zero-area rects are filtered out before merging
- [ ] Passthrough still works correctly for non-overlapping elements (clicking between separate sprites passes through to desktop)
- [ ] Tested on both Linux and Windows

### US-002: Harden passthrough polygon merging
**Description:** As a developer, I want the passthrough merge logic to be robust so future UI additions don't reintroduce transparency bugs.

**Acceptance Criteria:**
- [ ] Refactor merge logic to iteratively merge each new polygon into the accumulated result, handling `Geometry2D.merge_polygons()` returning multiple disjoint polygons
- [ ] Add validation: skip empty rects, skip rects with zero width or height
- [ ] The anchor-point path stitching (connecting islands via `Vector2.ZERO`) still works correctly for Linux stability
- [ ] No regression in passthrough behavior for all existing UI elements (coin HUD, menus, shop, inventory, settings, pet selection, furniture, mood bubble)

### US-003: Add emotion text to mood bubble
**Description:** As a user, I want to see a text label in the pet's mood bubble so I can immediately understand the pet's emotional state without guessing what colors mean.

**Acceptance Criteria:**
- [ ] The mood bubble displays the mood name as text: "Sad", "Neutral", "Happy"
- [ ] Text is legible (appropriate font size, contrasting color against bubble background)
- [ ] Text updates when mood changes
- [ ] The colored circle icon is still displayed alongside the text
- [ ] Bubble size adjusts to fit both icon and text
- [ ] Bubble rect calculation (`get_bubble_rect()`) accounts for new size so passthrough remains correct

### US-004: Architect emotion image support via node configuration
**Description:** As a developer, I want to be able to configure emotion images (e.g., small expressive face sprites) through exported node properties so they can be added later without code changes.

**Acceptance Criteria:**
- [ ] Add exported properties on the pet node for mood textures: `sad_texture: Texture2D`, `neutral_texture: Texture2D`, `happy_texture: Texture2D`
- [ ] When a texture is assigned for a mood, the bubble displays that image instead of the generated colored circle
- [ ] When no texture is assigned (null), falls back to the current generated colored circle
- [ ] Text label is always shown regardless of whether an image or colored circle is used
- [ ] The system is documented with a code comment explaining how to add emotion images

### US-005: Package GlobalInput as a Godot plugin
**Description:** As a developer, I want the GlobalInput GDExtension packaged as a standard Godot plugin so I can reuse it in other projects by copying a single folder.

**Acceptance Criteria:**
- [ ] Create `addons/global_input/` folder structure containing:
  - `plugin.cfg` with proper metadata (name, description, author, version, script)
  - Plugin script that registers/unregisters the GlobalInput singleton
  - All C++ source files (`src/` subfolder)
  - `SConstruct` build file
  - Compiled binaries folder (`bin/`)
  - `global_input.gdextension` manifest (paths updated for plugin location)
- [ ] Plugin can be enabled/disabled via Godot's Project Settings > Plugins
- [ ] When enabled, `GlobalInput` is available as an autoload/singleton
- [ ] When disabled, the singleton is removed cleanly
- [ ] Existing Amigos do Trabalho project updated to use the plugin from `addons/global_input/` instead of the root-level gdextension

### US-006: Write GlobalInput plugin README
**Description:** As a developer adopting GlobalInput in another project, I want clear documentation on how to install, build, and use it.

**Acceptance Criteria:**
- [ ] README.md inside `addons/global_input/` covers:
  - What GlobalInput does (captures system-wide keyboard and mouse input outside Godot)
  - Prerequisites (godot-cpp, build tools, platform dependencies: X11/Xtst on Linux, user32 on Windows)
  - Installation steps (copy folder, enable plugin, build native libraries)
  - Build instructions (SCons commands for Linux and Windows)
  - API reference: `start_hooks()`, `stop_hooks()`, `get_key_count()`, `get_click_count()`, `reset_counts()`
  - Usage example (GDScript snippet showing polling pattern)
  - Platform notes (X11 permissions on Linux, hook limitations on Windows)
  - License information placeholder

### US-007: Write Amigos do Trabalho project README
**Description:** As a new contributor or user, I want comprehensive English documentation so I can understand, configure, and extend the project.

**Acceptance Criteria:**
- [ ] README.md at project root covers:
  - Project overview and features (desktop pet, transparent window, furniture, coin economy, mood system)
  - Screenshots or description of the app in action
  - Installation and running instructions
  - Code organization (directory structure, key files and their purposes)
  - How items/furniture are configured (FurnitureData resource properties, `.tres` files, the furniture creator editor plugin)
  - How pet interactions and animations are linked (state machine, animation names, interaction types, cooldowns)
  - How to create new pets (SpriteFrames resource, required animations, directory convention, auto-discovery)
  - Save data format and location
  - GlobalInput extension overview (with pointer to plugin README for details)
  - Multi-monitor and multi-language support
- [ ] Written in clear English, accessible to developers unfamiliar with the project
- [ ] 3-5 pages in length

### US-008: Delete bug screenshot
**Description:** Clean up the temporary bug screenshot after analysis.

**Acceptance Criteria:**
- [ ] `/workspace/bug-erase-me/` folder and its contents are deleted

## Functional Requirements

- FR-1: `_update_passthrough()` must collect all interactive element rects, convert to polygons, and merge them into a solid union with no interior holes from overlapping regions
- FR-2: The merge algorithm must handle `Geometry2D.merge_polygons()` returning multiple disjoint polygon islands and stitch them via the existing anchor-point approach
- FR-3: Zero-area or degenerate rects must be filtered before polygon conversion
- FR-4: Fully-contained rects must not produce holes after merging
- FR-5: The mood bubble must display a Label node showing "Sad", "Neutral", or "Happy" next to the mood icon
- FR-6: The pet node must expose `@export` properties for optional mood textures per mood state
- FR-7: If an exported mood texture is set, it replaces the generated colored circle; text is always shown
- FR-8: GlobalInput plugin must follow Godot's `addons/` plugin convention with `plugin.cfg` and an EditorPlugin script
- FR-9: The plugin script must add `GlobalInput` as an autoload on enable and remove it on disable
- FR-10: The `.gdextension` manifest paths must be relative to the plugin folder
- FR-11: The project must be updated to reference GlobalInput from its new `addons/global_input/` location
- FR-12: GlobalInput README must include build instructions, API reference, and usage examples
- FR-13: Project README must document features, architecture, configuration, interactions, animations, and pet creation

## Non-Goals

- No visual debug overlay for passthrough polygons (just robust logic)
- No actual emotion face images are included — only the architecture to support them later
- No changes to the coin economy, shop, inventory, or settings systems
- No new pet animations or pet content
- No automated build/CI pipeline for the GlobalInput plugin
- No localization of the mood text (English only for now; translation system can be used later)
- No changes to the furniture creator editor plugin

## Technical Considerations

- `Geometry2D.merge_polygons()` in Godot can return multiple polygons when inputs are disjoint; the merge loop must accumulate iteratively
- `Geometry2D.merge_polygons()` may also return inner polygons (holes) indicated by winding order — these must be detected and excluded
- The existing anchor-point stitching approach (connecting disjoint islands through `Vector2.ZERO`) is critical for Linux stability and must be preserved
- The mood bubble's `_bubble_panel` is built programmatically in `pet.gd` — the Label node should be added to the same container
- Exported texture properties use `@export var sad_texture: Texture2D` pattern in GDScript
- The GlobalInput `.gdextension` file uses relative paths like `res://addons/global_input/bin/libglobal_input.linux.template_debug.x86_64.so` — these must be updated
- Moving the gdextension into `addons/` requires updating any `res://` paths that reference the old location

## Success Metrics

- Zero transparency artifacts when pet overlaps with any furniture item
- Users can identify pet mood within 1 second by reading the bubble text
- GlobalInput plugin can be installed in a fresh Godot project by copying `addons/global_input/` and enabling it — no other steps needed beyond building native libs
- A developer new to the project can understand its architecture and create a new pet after reading the README

## Open Questions

- Should the mood text be localized using Godot's translation system in a future iteration?
- Should the passthrough polygon update be debounced/throttled for performance if many elements overlap?
- What license should the GlobalInput plugin use?
- Should the project README include animated GIFs or screenshots (requires capturing them separately)?
