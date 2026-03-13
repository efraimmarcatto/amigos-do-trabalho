# PRD: Desktop Pet Upgrade — Fullscreen, Physics, Furniture & Real Input

## Introduction

Upgrade the desktop pet ("Amigos do Trabalho") from a small overlay to a full-screen always-on-top transparent companion. This includes: replacing the mock `GlobalInput` with the real compiled GDExtension, adding physics (gravity, drag-and-drop), random idle walking, and a coin-purchasable furniture system where pieces can be walkable surfaces or interactive triggers for the pet.

---

## Goals

- Remove all mock input code and use the real `GlobalInput` GDExtension (Linux + Windows)
- Expand the window to cover the full screen while remaining transparent and click-through on empty areas
- Pet falls to the ground with gravity when dropped after being dragged
- Pet autonomously walks in random directions/distances during idle
- Furniture items are purchasable with coins, placeable on screen, and configurable per-piece (walkable surface, interaction trigger, or inert decoration)

---

## User Stories

### US-001: Replace mock GlobalInput with real GDExtension
**Description:** As a developer, I want the game to use the compiled `GlobalInput` C++ extension so that real keyboard and mouse events drive the coin system.

**Acceptance Criteria:**
- [ ] `project.godot` autoload entry for `GlobalInput` is removed (extension registers itself)
- [ ] `global_input.gdextension` is present and referenced via Godot's extension system
- [ ] `coin_system.gd` works unchanged — `GlobalInput.get_key_count()`, `get_click_count()`, `reset_counts()` resolve to the C++ class
- [ ] `scripts/mock_global_input.gd` is deleted
- [ ] On Linux, `start_hooks()` is called on game start and `stop_hooks()` on game exit
- [ ] On Windows, equivalent hooks are called
- [ ] No GDScript errors in the Godot output when starting the project

### US-002: Fullscreen transparent always-on-top window
**Description:** As a user, I want the game window to cover my entire screen transparently so the pet and furniture appear to live on my desktop.

**Acceptance Criteria:**
- [ ] Window size matches the primary monitor resolution at startup (use `DisplayServer.screen_get_size()`)
- [ ] Window is borderless, always-on-top, and has a transparent background
- [ ] Click-through passthrough polygon covers only visible elements (pet, furniture, UI), not empty transparent areas
- [ ] `project.godot` display settings updated to match fullscreen transparent behavior
- [ ] Existing `_update_passthrough()` logic in `main.gd` updated to account for all visible furniture rects in addition to pet and menu

### US-003: Pet drag-and-drop with gravity
**Description:** As a user, I want to click and drag the pet and have it fall realistically when I release it.

**Acceptance Criteria:**
- [ ] Left-click + hold on the pet sprite enters drag mode; pet follows the cursor
- [ ] On release, the pet is subject to gravity and falls downward
- [ ] Pet lands on the first walkable surface below it (a walkable furniture item or the screen bottom)
- [ ] Pet does not fall below the screen bottom (`screen_height - pet_height`)
- [ ] While dragging, the pet plays a "grabbed" visual state (e.g. slight rotation or scale change)
- [ ] Dragging does not open the interaction menu (menu opens only on click without drag)
- [ ] `pet.gd` handles drag input; physics state is managed internally (not Godot RigidBody)

### US-004: Pet idle walking
**Description:** As a user, I want the pet to walk around on its own when idle so it feels alive.

**Acceptance Criteria:**
- [ ] When idle (not dragged, not in interaction), pet picks a random horizontal direction (left or right) and a random distance (e.g. 50–300px)
- [ ] Pet walks at a constant configurable speed (`@export var walk_speed: float`)
- [ ] After reaching the target, pet waits a random idle duration (e.g. 1–5 seconds) before picking a new walk target
- [ ] Pet flips its sprite horizontally based on walking direction
- [ ] Pet is constrained to the walkable surface it is currently on (does not walk off a furniture edge unless `can_fall_off_edge` is true for that furniture)
- [ ] Pet does not walk through non-walkable furniture (treated as a wall)
- [ ] Walking state is interrupted immediately when the user starts dragging

### US-005: Furniture data resource
**Description:** As a developer, I want a structured `FurnitureData` resource so each piece of furniture has consistent, configurable properties.

**Acceptance Criteria:**
- [ ] `FurnitureData` is a `Resource` class (`furniture_data.gd`) with the following exported fields:
  - `id: String` — unique identifier (e.g. `"sofa"`, `"bookshelf"`)
  - `display_name: String`
  - `texture: Texture2D`
  - `coin_cost: int`
  - `walkable: bool` — pet can walk on top of this furniture
  - `walk_surface_y_offset: int` — pixel offset from the top of the sprite where the pet stands
  - `can_fall_off_edge: bool` — pet can walk off the sides
  - `interaction_type: String` — `""` (none), `"sleep"`, `"eat"`, `"play"`, or future types
  - `interaction_coin_bonus: int` — coins awarded when pet interacts
  - `interaction_cooldown: float` — seconds before the same piece can trigger again
- [ ] At least 5 `FurnitureData` `.tres` resource files are created as placeholders (can use colored rectangles as textures initially):
  - `sofa` (walkable, `interaction_type="sleep"`)
  - `bookshelf` (not walkable, inert wall)
  - `food_bowl` (not walkable, `interaction_type="eat"`)
  - `toy` (not walkable, `interaction_type="play"`)
  - `table` (walkable, no interaction)
- [ ] Resources are saved under `res://furniture/data/`

### US-006: Furniture node scene
**Description:** As a developer, I want a reusable `Furniture` scene so each furniture instance in the world behaves consistently.

**Acceptance Criteria:**
- [ ] `Furniture` scene (`furniture.tscn`) with script `furniture.gd` extending `Node2D`
- [ ] Takes a `FurnitureData` resource as `@export var data: FurnitureData`
- [ ] Displays the furniture texture via a `Sprite2D` child
- [ ] Exposes `get_surface_y() -> float` — returns the Y coordinate of the walkable surface (top of sprite + `walk_surface_y_offset`) in global coordinates
- [ ] Exposes `get_left_x() -> float` and `get_right_x() -> float` for edge detection
- [ ] Emits `pet_interacted(furniture: Furniture)` signal when pet overlaps and interaction is triggered
- [ ] Has an `Area2D` + `CollisionShape2D` child sized to the sprite for overlap detection

### US-007: Furniture shop UI
**Description:** As a user, I want to browse and buy furniture with my coins so I can decorate my desktop.

**Acceptance Criteria:**
- [ ] A "Shop" button is added to the screen (always visible, small, anchored to a corner)
- [ ] Clicking Shop opens a panel listing all available `FurnitureData` items with: icon, name, cost
- [ ] Items the user already owns show "Owned"; items they can afford show "Buy"; items too expensive are greyed out
- [ ] Buying deducts coins and adds the item to the player's owned furniture list
- [ ] Owned furniture list is saved to `user://save_data.json` alongside coins
- [ ] Shop panel is included in the click-through passthrough polygon while visible
- [ ] Shop closes when clicking outside it

### US-008: Furniture placement in the world
**Description:** As a user, I want owned furniture to appear on screen in configured positions so my desktop looks decorated.

**Acceptance Criteria:**
- [ ] Owned furniture items are spawned into the main scene at startup, loaded from save data
- [ ] Each furniture piece has a saved `position: Vector2` in `save_data.json`
- [ ] Default positions are assigned on first purchase (staggered along the bottom of the screen)
- [ ] The passthrough polygon is updated to include all furniture rects
- [ ] Furniture does not overlap the pet's starting position

### US-009: Pet interacts with interactive furniture
**Description:** As a user, I want to see the pet react when it walks into interactive furniture so the world feels dynamic.

**Acceptance Criteria:**
- [ ] When pet enters the `Area2D` of an interactive furniture (`interaction_type != ""`), the pet plays a matching animation/visual reaction and the player earns `interaction_coin_bonus` coins
- [ ] Interaction is blocked if `interaction_cooldown` has not elapsed since the last trigger for that piece
- [ ] `sleep` interaction: pet plays a sleeping visual (e.g. "Zzz" label, closed-eye tint) for 2–3 seconds then resumes walking
- [ ] `eat` interaction: pet plays eat animation (scale bounce) and awards coins
- [ ] `play` interaction: same bounce as existing `_play_bounce()` in `pet.gd`
- [ ] Cooldown state is not persisted across sessions (resets on load)

---

## Functional Requirements

- **FR-1:** Remove `GlobalInput` autoload from `project.godot`. The C++ extension registers the `GlobalInput` singleton automatically via `register_types.cpp`.
- **FR-2:** Call `GlobalInput.start_hooks()` in `main.gd`'s `_ready()` and `GlobalInput.stop_hooks()` in `_notification(NOTIFICATION_WM_CLOSE_REQUEST)`.
- **FR-3:** On startup, set window size to `DisplayServer.screen_get_size()` and position to `Vector2.ZERO`.
- **FR-4:** The pet's Y position floor is `screen_height - pet_height / 2`. The pet cannot go below this.
- **FR-5:** Pet physics are simulated manually: apply a configurable `gravity: float` each frame when `is_falling == true`, zero out velocity on landing.
- **FR-6:** Drag detection: `InputEventMouseButton` press starts a drag only if the mouse does not move more than a threshold (4px) before release; otherwise it's a drag, not a click.
- **FR-7:** Walking AI uses a state machine inside `pet.gd`: states are `IDLE`, `WALKING`, `FALLING`, `DRAGGED`, `INTERACTING`.
- **FR-8:** `FurnitureData` resources are loaded from `res://furniture/data/` at runtime into a registry (dictionary keyed by `id`).
- **FR-9:** `save_data.json` schema is extended to: `{ "coins": int, "pet_state": int, "owned_furniture": [{ "id": str, "position": { "x": float, "y": float } }] }`.
- **FR-10:** Passthrough polygon is rebuilt every frame to cover: pet bounding rect + all visible furniture rects + shop panel rect (if visible).

---

## Non-Goals

- No multiplayer or remote pets
- No furniture drag-to-reposition by the user (positions are fixed after purchase; can be added later)
- No animated sprite sheets for the pet (color tint and scale changes are sufficient for now)
- No audio
- No macOS support
- No furniture removal or selling

---

## Technical Considerations

- **GDExtension build:** The `.so`/`.dll` must be compiled and placed in `gdextension/bin/` before the project runs. The `.gdextension` manifest already points to the correct paths.
- **`register_types.cpp`:** Verify that `GlobalInput` is registered as a singleton (not just a class) so `GlobalInput.get_key_count()` works as a global call from GDScript. If not, add singleton registration.
- **Physics:** Use manual velocity integration (`position += velocity * delta`) rather than Godot's physics engine to keep the pet a simple `Node2D`/`Sprite2D`. Convert `pet.gd` from `extends Sprite2D` to `extends Node2D` with a `Sprite2D` child.
- **Furniture surface collision:** Walking surface detection is done by comparing the pet's bottom Y against each walkable furniture's `get_surface_y()` and X range — no physics engine needed.
- **Platform differences:** On Linux, XRecord requires a display server. On Windows, the existing `global_input_windows.cpp` hook pattern should be validated.

---

## Success Metrics

- Coin counter increments from real keystrokes/clicks (not random simulation)
- Pet visibly falls and lands when dragged and released
- Pet walks autonomously at least once every 10 seconds of idle time
- At least 3 furniture pieces are purchasable and visible on screen
- Pet triggers at least one furniture interaction per session

---

## Open Questions

- Should furniture have z-index layering (pet appears behind/in-front of furniture based on Y position)?
- Should the pet's mood (sad/neutral/happy) affect its walk speed or idle frequency?
- Should interactive furniture show a visual indicator (e.g. sparkle) when its cooldown is ready?
- Is there a specific art style for furniture, or are placeholder colored rectangles acceptable for the first iteration?
