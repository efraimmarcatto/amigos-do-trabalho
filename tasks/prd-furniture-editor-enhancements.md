# PRD: Furniture Editor Enhancements — Standing Area, Mouse Editing & Placement Node

## Introduction

The furniture editor currently has a single collision area used for pet interaction detection. However, there's no separate way to define where the pet can physically **stand** on a piece of furniture. For example, on a table the pet should be able to walk across the entire surface, not just the center. On a sofa, the pet should stay on the seat portion.

Additionally, editing collision rectangles via spinboxes is tedious — mouse-based drag and resize in the preview would be much faster. Finally, furniture spawned at runtime should be parented under the existing `Furnitures` node in the main scene (which sits behind the pet in z-order), replacing the dynamically-created `FurnitureContainer`.

## Goals

- Allow furniture creators to define two independent areas: a **standing area** (where the pet can walk/stand) and an **interaction area** (where the pet triggers interactions)
- Provide mouse-based drag-to-move and handle-to-resize editing for both areas in the preview panel
- Parent runtime furniture under the existing `Furnitures` scene node instead of dynamically creating a `FurnitureContainer`

## User Stories

### US-001: Add standing area properties to FurnitureData
**Description:** As a furniture creator, I want to define a standing area rectangle (size + offset) separately from the interaction collision, so the pet's walkable surface matches the furniture's visual surface.

**Acceptance Criteria:**
- [ ] `FurnitureData` resource gains `standing_size_override: Vector2` and `standing_offset: Vector2` properties
- [ ] When `standing_size_override` is `Vector2.ZERO`, standing area auto-calculates from texture × display_scale (current behavior)
- [ ] Existing furniture `.tres` files continue to work without changes (backward compatible defaults)
- [ ] Typecheck/lint passes

### US-002: Use standing area for pet walk bounds at runtime
**Description:** As a player, I want my pet to walk across the full defined standing area of furniture, not just the center.

**Acceptance Criteria:**
- [ ] `Furniture.get_surface_y()` uses the standing area (standing offset + standing size) when defined, falling back to current sprite-based calculation
- [ ] `Furniture.get_left_x()` and `Furniture.get_right_x()` use the standing area bounds when defined
- [ ] Pet walks across the full standing area on a table (not just the center)
- [ ] Pet stays on the seat portion of a sofa when standing area is configured for it
- [ ] Existing furniture without standing overrides behaves identically to before

### US-003: Add standing area controls to the furniture editor form
**Description:** As a furniture creator, I want form fields to configure the standing area in the editor, similar to the existing collision controls.

**Acceptance Criteria:**
- [ ] New "Custom Standing Area" checkbox in the Behavior section (visible when Walkable is checked)
- [ ] When checked, shows Standing Size (W/H) and Standing Offset (X/Y) spinboxes
- [ ] Auto-calculated label shows default standing dimensions when unchecked
- [ ] Standing area values are saved to and loaded from `.tres` files correctly
- [ ] Typecheck/lint passes

### US-004: Display standing area overlay in preview
**Description:** As a furniture creator, I want to see the standing area visualized in the preview alongside the interaction collision area, so I can verify both areas are correct.

**Acceptance Criteria:**
- [ ] Standing area renders as a distinct colored rectangle (e.g., green) in the preview
- [ ] Interaction collision area continues to render in its existing blue color
- [ ] Both rectangles are visible simultaneously with labels or a legend to distinguish them
- [ ] Preview updates in real-time when standing area values change

### US-005: Mouse drag-to-move for collision and standing rectangles
**Description:** As a furniture creator, I want to click and drag a rectangle in the preview to reposition it, so I don't have to manually type offset values.

**Acceptance Criteria:**
- [ ] Clicking inside a rectangle in the preview starts a drag operation
- [ ] Dragging moves the rectangle and updates the corresponding offset spinboxes in real-time
- [ ] If rectangles overlap, the smaller/top rectangle gets priority for click targeting
- [ ] Cursor changes to a move cursor when hovering over a draggable rectangle
- [ ] Releasing the mouse ends the drag; spinbox values reflect final position

### US-006: Mouse handle-to-resize for collision and standing rectangles
**Description:** As a furniture creator, I want to drag edge/corner handles on a rectangle in the preview to resize it, so I can visually adjust the area without typing dimensions.

**Acceptance Criteria:**
- [ ] Each rectangle displays 8 resize handles (4 corners + 4 edge midpoints) when hovered or selected
- [ ] Dragging a handle resizes the rectangle from that edge/corner
- [ ] Corresponding size and offset spinboxes update in real-time during resize
- [ ] Minimum size enforced (e.g., 4×4 px) to prevent zero-size rectangles
- [ ] Cursor changes to appropriate resize cursor (↔, ↕, ↗, etc.) when hovering handles

### US-007: Parent furniture under existing Furnitures scene node
**Description:** As a developer, I want runtime furniture to be added under the `Furnitures` node that already exists in the main scene, so z-ordering is controlled by the scene tree and furniture renders behind the pet.

**Acceptance Criteria:**
- [ ] `main.gd` references the existing `Furnitures` node from the scene tree (via `@onready` or `$Furnitures`)
- [ ] The dynamic `FurnitureContainer` creation code is removed
- [ ] `_spawn_furniture()` and `_spawn_furniture_at()` add children to the `Furnitures` node
- [ ] Furniture renders behind the pet (the `Furnitures` node is above the pet in the scene tree, i.e., earlier/behind)
- [ ] All existing furniture features (edit mode, dragging, stacking, removal) continue to work

## Functional Requirements

- FR-1: Add `standing_size_override: Vector2` and `standing_offset: Vector2` exported properties to `FurnitureData`, defaulting to `Vector2.ZERO`
- FR-2: When `standing_size_override != Vector2.ZERO`, `Furniture.get_surface_y()`, `get_left_x()`, and `get_right_x()` use the standing area dimensions and offset instead of raw texture bounds
- FR-3: The furniture editor form shows standing area controls (size W/H, offset X/Y) when both "Walkable" and "Custom Standing Area" are checked
- FR-4: The preview display renders two distinct colored overlays: interaction collision (blue) and standing area (green), each with labeled outlines
- FR-5: Clicking and dragging inside a rectangle in the preview moves it; offset spinboxes update in real-time
- FR-6: Dragging edge/corner handles on a rectangle resizes it; size and offset spinboxes update in real-time
- FR-7: `main.gd` uses the `Furnitures` node from `main.tscn` as the furniture parent instead of creating a dynamic `FurnitureContainer`
- FR-8: Save and load of `.tres` files includes standing area properties; missing properties default to `Vector2.ZERO` for backward compatibility

## Non-Goals

- No changes to pet interaction detection logic (the existing collision area continues to drive `_try_furniture_interaction()`)
- No multi-select or group-editing of rectangles in the preview
- No undo/redo system for mouse-based edits (spinbox values serve as the source of truth)
- No fix for the pet-dragging bug (separate issue; the `Furnitures` node z-ordering serves as a workaround)
- No changes to how furniture positions are saved/loaded in `save_data.json`

## Technical Considerations

- The `preview_display.gd` `_draw()` method needs to be extended to render two rectangles and handle mouse input (`_gui_input`)
- Handle hit-testing should use a small pixel tolerance (~6px) around handles for comfortable click targets
- The `Furnitures` node in `main.tscn` is a plain `Node` (not `Node2D`); it may need to be changed to `Node2D` for proper spatial parenting of furniture sprites
- Standing area and collision area are independent — a furniture piece can have a custom standing area without a custom collision, and vice versa
- The pet's `get_left_x()`/`get_right_x()` currently use raw texture size × scale; the standing area override should replace this when defined, not layer on top of it

## Success Metrics

- Furniture creators can define standing areas visually in under 30 seconds per piece
- Pet walks across the full intended surface of tables, sofas, and similar furniture
- Mouse editing of rectangles feels responsive with no perceptible lag between drag and spinbox updates
- Existing furniture resources load and behave identically without any migration

## Open Questions

- Should the standing area be visualized at runtime (debug overlay) or only in the editor?
- Should enabling "Custom Standing Area" auto-populate from the collision area values (if set) or from texture × scale?
- Should the `Furnitures` node type be changed from `Node` to `Node2D` in the scene, or should we handle it in code?
