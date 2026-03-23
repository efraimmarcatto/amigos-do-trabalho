# PRD: Furniture Creator Tool (Godot Editor Plugin)

## Introduction

Creating new furniture items currently requires manually writing `.tres` resource files with correct atlas regions, UIDs, and property values. This is error-prone and slow to iterate on. The Furniture Creator Tool is a Godot Editor plugin that provides a graphical interface for creating and configuring `FurnitureData` resources — including sprite selection (from atlas or standalone image), property editing, collision area customization, and a live preview — then generates the `.tres` file and saves it to `res://furniture/data/`.

## Goals

- Eliminate manual `.tres` file editing for item creation
- Provide a visual atlas region picker for selecting sprites from existing sprite sheets
- Support importing standalone image files as item textures
- Auto-calculate collision area from sprite size with manual override support
- Show a live preview of the item at its configured scale
- Generate valid `FurnitureData` `.tres` files saved to `res://furniture/data/`
- Reduce time to create and iterate on new items from minutes to seconds

## User Stories

### US-001: Open the Furniture Creator from the Godot Editor
**Description:** As a developer, I want to access the Furniture Creator from the Godot Editor so that I can create items without leaving my workflow.

**Acceptance Criteria:**
- [ ] A "Furniture Creator" entry appears in the Godot Editor (e.g., via Project > Tools menu, or as a bottom panel/dock)
- [ ] Clicking it opens the creator panel/window
- [ ] The plugin is registered in `addons/` following Godot 4 `EditorPlugin` conventions
- [ ] Typecheck passes

### US-002: Select a sprite from an existing atlas sprite sheet
**Description:** As a developer, I want to visually browse a sprite sheet and click-drag to select a region so that I can pick the exact sprite for my item.

**Acceptance Criteria:**
- [ ] A "From Atlas" tab/mode lets me choose a sprite sheet file (default to `res://assets/Top-Down_Retro_Interior/`)
- [ ] The full sprite sheet is displayed with zoom controls
- [ ] I can click and drag to define a rectangular region on the sheet
- [ ] The selected region coordinates (x, y, width, height) are shown and editable numerically
- [ ] The selected region is highlighted with a visible border/overlay
- [ ] Typecheck passes

### US-003: Import a standalone image as item texture
**Description:** As a developer, I want to import a standalone image file so that I can use custom sprites not on an existing sprite sheet.

**Acceptance Criteria:**
- [ ] A "From File" tab/mode lets me pick an image file via Godot's file dialog
- [ ] The selected image is displayed in the preview
- [ ] The image path is stored as a direct `Texture2D` reference (not `AtlasTexture`)
- [ ] Typecheck passes

### US-004: Configure all FurnitureData properties via form fields
**Description:** As a developer, I want to set all item properties through labeled form fields so that I don't need to remember property names or valid values.

**Acceptance Criteria:**
- [ ] Form includes fields for all 14 `FurnitureData` properties:
  - `id` (String input, auto-generated from display_name as snake_case, editable)
  - `display_name` (String input)
  - `coin_cost` (int spinner)
  - `walkable` (checkbox)
  - `walk_surface_y_offset` (int spinner, visible only when `walkable` is checked)
  - `can_fall_off_edge` (checkbox, default true)
  - `jumpable` (checkbox)
  - `interaction_type` (dropdown: none / play / eat / sleep)
  - `interaction_coin_bonus` (int spinner, visible only when interaction_type is set)
  - `interaction_cooldown` (float spinner, visible only when interaction_type is set)
  - `discard_refund_ratio` (float slider 0.0–1.0, default 0.5, shows calculated refund value next to it)
  - `display_scale` (Vector2 input, default (4, 4))
  - `stackable` (checkbox)
- [ ] Conditional fields show/hide based on related toggles
- [ ] Refund value label updates live: shows `coin_cost * discard_refund_ratio` rounded
- [ ] Typecheck passes

### US-005: Preview item at actual display scale
**Description:** As a developer, I want to see a live preview of the selected sprite at its configured display scale so I can verify the item looks correct before saving.

**Acceptance Criteria:**
- [ ] Preview area shows the selected sprite scaled by `display_scale`
- [ ] Preview updates in real-time when sprite selection or scale changes
- [ ] Preview is scrollable/pannable if the scaled sprite is large
- [ ] Typecheck passes

### US-006: Auto-calculated collision with manual override
**Description:** As a developer, I want the collision area to be auto-calculated from the sprite size by default, but I also want to manually adjust it for items like the sofa where only part of the sprite should have collision (e.g., half height).

**Acceptance Criteria:**
- [ ] By default, collision size = `texture_size * display_scale` (matching current `furniture.gd` behavior)
- [ ] A "Custom collision" checkbox enables manual override
- [ ] When enabled, width and height fields appear (pre-filled with auto-calculated values)
- [ ] An offset field (Vector2) allows shifting the collision box relative to the sprite center
- [ ] The collision rectangle is shown as a semi-transparent overlay on the preview
- [ ] The auto-calculated default matches the current behavior (e.g., table works as-is)
- [ ] Manual override supports cases like the sofa (collision at half the sprite height)
- [ ] Custom collision data is stored as new optional properties on `FurnitureData`:
  - `collision_size_override: Vector2` (Vector2.ZERO = use auto)
  - `collision_offset: Vector2` (default Vector2.ZERO)
- [ ] `furniture.gd` reads these overrides when sizing the `CollisionShape2D`
- [ ] Typecheck passes

### US-007: Generate and save the .tres resource file
**Description:** As a developer, I want to click "Save" and have the tool generate a valid `.tres` file in `res://furniture/data/` so the item is immediately available in the shop.

**Acceptance Criteria:**
- [ ] "Save" button generates a `FurnitureData` resource with all configured properties
- [ ] File is saved as `res://furniture/data/{id}.tres`
- [ ] If file already exists, a confirmation dialog warns before overwriting
- [ ] For atlas textures: generates correct `AtlasTexture` sub-resource with region
- [ ] For standalone images: references the texture directly
- [ ] After saving, the resource is visible in Godot's FileSystem dock immediately
- [ ] The saved `.tres` file is loadable by the shop system without changes
- [ ] Typecheck passes

### US-008: Load and edit an existing furniture item
**Description:** As a developer, I want to load an existing `.tres` file into the tool so I can tweak properties and re-save without starting from scratch.

**Acceptance Criteria:**
- [ ] A "Load" button opens a file dialog filtered to `res://furniture/data/*.tres`
- [ ] Loading populates all form fields with the item's current values
- [ ] Atlas region is restored and highlighted on the sprite sheet
- [ ] Saving overwrites the original file (with confirmation)
- [ ] Typecheck passes

## Functional Requirements

- FR-1: The plugin must register as a Godot 4 `EditorPlugin` in `addons/furniture_creator/`
- FR-2: The plugin must provide a visual atlas region picker that displays sprite sheet images and allows click-drag region selection
- FR-3: The plugin must support importing standalone image files as `Texture2D` references
- FR-4: The plugin must expose all 14 `FurnitureData` properties as form controls with appropriate input types
- FR-5: The plugin must show a live preview of the sprite at the configured `display_scale`
- FR-6: The plugin must auto-calculate collision area as `texture_size * display_scale` by default
- FR-7: The plugin must allow manual collision size and offset override, displayed as an overlay on the preview
- FR-8: The plugin must generate valid `.tres` resource files compatible with the existing shop loading system (`shop.gd` scanning `res://furniture/data/`)
- FR-9: The plugin must add `collision_size_override` and `collision_offset` properties to `FurnitureData`
- FR-10: `furniture.gd` must be updated to use collision overrides when present
- FR-11: The plugin must support loading existing `.tres` files for editing
- FR-12: The plugin must validate required fields (`id`, `display_name`, `texture`) before saving and show error messages for missing fields

## Non-Goals

- No batch creation or CSV import of items
- No animation or multi-frame sprite support
- No pet behavior preview or simulation within the tool
- No undo/redo history within the plugin (rely on file-level revert)
- No auto-deployment or runtime hot-reload — items appear after next shop scan
- Not for end users — this is a developer-only editor tool

## Design Considerations

- Follow Godot's editor UI patterns: use `EditorInspector`-style controls, standard theme colors, and dock/panel conventions
- The atlas picker should feel similar to Godot's built-in `AtlasTexture` region editor but simpler (no 9-slice, no margin controls)
- Group form fields logically: Identity (id, name) > Economics (cost, refund) > Behavior (walkable, jumpable, stackable, interaction) > Visual (scale, collision)
- Default the file browser to `res://assets/Top-Down_Retro_Interior/` for atlas mode since that's where all current sprites live

## Technical Considerations

- Plugin structure follows Godot 4 conventions: `addons/furniture_creator/plugin.cfg` + `plugin.gd`
- All UI built with Godot's `Control` nodes in GDScript (no C++ needed)
- Atlas region selection uses a custom `Control` that draws the sprite sheet and handles input for click-drag selection
- The `.tres` file is generated using Godot's `ResourceSaver.save()` API, which ensures correct format and UID generation
- Two new optional properties added to `FurnitureData`:
  - `@export var collision_size_override: Vector2 = Vector2.ZERO` — when non-zero, used instead of auto-calculated size
  - `@export var collision_offset: Vector2 = Vector2.ZERO` — offset from sprite center
- `furniture.gd` `_ready()` updated: if `collision_size_override != Vector2.ZERO`, use it instead of `texture_size * display_scale`
- Existing `.tres` files remain compatible — new properties default to zero (auto behavior)

## Success Metrics

- A new furniture item can be created and appear in the shop in under 60 seconds
- Editing an existing item's properties takes under 30 seconds
- No manual `.tres` file editing required for any standard item creation workflow
- All 5 existing items can be loaded, viewed, and re-saved without data loss

## Open Questions

- Should the interaction_type dropdown be extensible (allow custom strings) or limited to the current set (play, eat, sleep)?
- Should the tool include a "duplicate" feature for creating variants of existing items?
- Would it be useful to preview how the item looks on the desktop (with taskbar/transparency) or is sprite-at-scale sufficient?
