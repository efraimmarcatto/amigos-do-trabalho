# PRD: Layout Edit, Shop & Pet Regression Fixes

## Introduction

Three regressions have been identified in the desktop pet application: (1) the layout edit mode's "X" remove buttons and save button are unresponsive to clicks, (2) shop panel item images are misaligned and oversized relative to their buttons, and (3) the pet renders behind furniture/menus and cannot be grabbed for dragging when overlapping other elements. This PRD covers bug fixes only — no new features or UX changes.

## Goals

- Restore full layout edit mode functionality: remove buttons ("X") and save button respond to clicks
- Fix shop panel so item images are properly sized and aligned within their grid cell buttons
- Fix pet rendering order so the pet appears in front of furniture but behind menus
- Ensure the pet can be grabbed and dragged even when overlapping furniture

## User Stories

### US-001: Fix "X" remove button clicks in layout edit mode
**Description:** As a user, I want to click the "X" button on furniture during edit mode so that I can send items back to inventory.

**Acceptance Criteria:**
- [ ] Investigate why remove button clicks are not reaching the Button's `pressed` signal in edit mode — likely an input consumption issue in `_handle_edit_input()` (`scripts/main.gd:996`) or a position/rect mismatch between `_is_click_on_remove_button()` (`scripts/main.gd:966`) and the actual Button global rect
- [ ] Remove buttons respond to clicks on all furniture items during edit mode
- [ ] Clicking "X" removes the furniture from the scene and adds it to inventory (existing `_on_remove_furniture` logic at `scripts/main.gd:707`)
- [ ] Stacked furniture on top of removed furniture is also returned to inventory
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-002: Fix save button click in layout edit mode
**Description:** As a user, I want to click the "Save" button in the slide menu to save my layout and exit edit mode, instead of having to press ESC.

**Acceptance Criteria:**
- [ ] Investigate why the save button (edit button re-labeled as "Save Edit" at `scripts/slide_menu.gd:151`) doesn't respond during edit mode — likely the same input handling issue as US-001, or the menu auto-closing before the click registers (check `slide_menu.gd:172` `_unhandled_input` auto-close behavior)
- [ ] Clicking the "Save Edit" button in the slide menu exits edit mode and saves the layout
- [ ] The button label reverts to "Edit Layout" after saving
- [ ] Furniture positions are persisted to `save_data.json`
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-003: Fix shop panel image sizing and alignment
**Description:** As a user, I want shop item images to fit properly within their grid cell buttons so the shop looks correct.

**Acceptance Criteria:**
- [ ] Investigate the image sizing in `_create_grid_cell()` (`scripts/shop.gd:141`) — the `TextureRect` uses `EXPAND_FIT_WIDTH_PROPORTIONAL` (line 159) and `PRESET_CENTER` anchors (line 161) which may cause the image to overflow the 64x64 button when the source texture is larger
- [ ] Item images fit within their button bounds (64x64 cell, 48x48 icon target)
- [ ] Images are centered within their buttons
- [ ] No image overflow or clipping artifacts
- [ ] Layout remains correct across different numbers of items (varying grid column counts)
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-004: Fix pet rendering layer — in front of furniture, behind menus
**Description:** As a user, I want the pet to appear in front of furniture but behind UI menus so it looks natural and menus remain usable.

**Acceptance Criteria:**
- [ ] Pet renders visually in front of all furniture sprites
- [ ] Pet renders behind the slide menu, shop panel, inventory panel, settings panel, and pet selection panel
- [ ] The current `z_index` approach (`scripts/main.gd:113`, pet z_index=1 vs furniture container z_index=0) may need to be replaced or supplemented — z_index only works within the same parent or CanvasLayer; UI Control nodes render on top regardless
- [ ] Menus and panels remain fully clickable and visually on top of the pet
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-005: Fix pet dragging when overlapping furniture
**Description:** As a user, I want to grab and drag the pet even when it visually overlaps furniture, so it doesn't feel stuck.

**Acceptance Criteria:**
- [ ] Investigate the pet's `_is_point_on_pet()` (`scripts/pet.gd:673`) and `_input()` (`scripts/pet.gd:640`) — the pet's click detection may be blocked by the passthrough polygon or by furniture nodes consuming the input first
- [ ] Pet can be grabbed by clicking on it even when it overlaps furniture
- [ ] Dragging the pet works smoothly regardless of what's behind it
- [ ] Releasing the pet after drag still triggers the FALLING state correctly
- [ ] Pet cannot be grabbed when clicking on a menu or panel area (menus take priority)
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

## Functional Requirements

- FR-1: In edit mode, `_handle_edit_input()` must not consume input events that target remove buttons or the slide menu save button — these must propagate to Godot's GUI system
- FR-2: The `_is_click_on_remove_button()` rect calculation must match the actual Button global rect as rendered on screen
- FR-3: Shop grid cell `TextureRect` must be constrained to fit within the `ICON_SIZE` (48x48) bounds without overflow, regardless of source texture size
- FR-4: Pet `z_index` must place it above the furniture container but the pet must not obscure UI Control nodes (menus, panels)
- FR-5: Pet `_input()` click detection must have priority over furniture click handling in normal mode, so the pet can be grabbed when overlapping furniture
- FR-6: The `mouse_passthrough_polygon` in `_update_passthrough()` must include the pet's area so clicks on the pet reach the window even when the pet overlaps furniture

## Non-Goals

- No UX improvements or visual polish beyond fixing these bugs
- No changes to edit mode drag-to-reposition behavior (this already works)
- No changes to shop pricing, inventory logic, or furniture interaction system
- No changes to pet animations, states, or AI behavior
- No new features or UI redesign

## Technical Considerations

- The app uses Godot's `mouse_passthrough_polygon` for desktop pet click-through behavior — this is central to all click/drag issues and must be carefully considered when fixing input handling
- `_input()` in Godot 4 fires before GUI event propagation — when `_handle_edit_input` returns without calling `set_input_as_handled()`, the event should reach Button controls, but verify this is actually happening
- Control nodes (menus, panels) as children of the scene root render on a different layer than Node2D children — z_index on Node2D nodes doesn't affect Control node rendering order
- The pet's `_is_point_on_pet()` does sprite-level hit detection — ensure this works correctly with the pet's global transform and scale

## Success Metrics

- All "X" remove buttons respond to clicks in edit mode
- Save button exits edit mode and persists layout on click
- Shop item images are contained within button bounds and visually centered
- Pet renders in front of furniture, behind all menus
- Pet can be grabbed and dragged from any position, including when overlapping furniture
