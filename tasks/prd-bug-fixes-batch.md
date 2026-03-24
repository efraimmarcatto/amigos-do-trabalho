# PRD: Bug Fixes Batch — Shop, Placement, Mood Bubble, Buttons, Plugin

## Introduction

Several bugs are affecting core gameplay and visual polish in Amigos do Trabalho. The shop crashes when clicking items due to missing node references, duplicate furniture of the same type cannot be placed, the mood bubble has rendering and flip issues, shop/inventory button images are misaligned and cropped, and the GlobalInput plugin has dead commented-out code. This PRD covers all fixes as equal-priority work.

## Goals

- Eliminate the shop crash caused by missing `QtyLabel` and `MinusBtn` node references
- Allow placing multiple furniture items of the same type, limited by inventory count
- Fix mood bubble rendering: reduce size by ~50%, prevent flipping when pet walks left, fix Windows-only visibility issue
- Fix shop and inventory button image misalignment and cropping
- Clean up dead code in the GlobalInput plugin

## User Stories

### US-001: Fix shop buy popup crash
**Description:** As a player, I want to click items in the shop without the game crashing so that I can browse and buy furniture.

**Acceptance Criteria:**
- [ ] Clicking any item in the shop opens the buy popup without errors
- [ ] `QtyLabel`, `MinusBtn`, and all other popup nodes are found correctly
- [ ] Quantity controls (+/-) work and update the displayed quantity and cost
- [ ] Buy button is disabled when the player doesn't have enough coins
- [ ] No `Node not found` or `null instance` errors in the output log

### US-002: Allow placing multiple furniture of the same type
**Description:** As a player, I want to place multiple copies of the same furniture type (e.g., two sofas) so that I can decorate freely with items I've purchased.

**Acceptance Criteria:**
- [ ] Placing a second item of the same type succeeds (no silent rejection)
- [ ] Each placed item gets a unique key in `_furniture_nodes` and `_furniture_positions` (e.g., `"sofa_1"`, `"sofa_2"` or a UUID)
- [ ] The number of placed items of a given type cannot exceed the inventory count for that type
- [ ] Picking up a placed item returns it to inventory and frees its unique key
- [ ] Save/load correctly persists and restores multiple items of the same type
- [ ] Existing save files with single-keyed furniture still load correctly (backwards compatibility)

### US-003: Reduce mood bubble size
**Description:** As a player, I want the mood bubble to be smaller so it doesn't dominate the screen relative to the pet.

**Acceptance Criteria:**
- [ ] Mood bubble is approximately 50% smaller than current size (icon, text, padding all scaled down)
- [ ] Bubble is still legible and recognizable at the reduced size
- [ ] Bubble position above the pet is adjusted to match the new size

### US-004: Fix mood bubble flipping when pet walks left
**Description:** As a player, I want the mood bubble to stay upright when the pet walks to the left so that the text and icon remain readable.

**Acceptance Criteria:**
- [ ] When the pet faces left (negative `scale.x`), the bubble does not mirror/flip
- [ ] Bubble content (icon + text) remains left-to-right readable regardless of pet direction
- [ ] Bubble stays positioned above the pet correctly in both directions

### US-005: Fix mood bubble visibility on Windows
**Description:** As a player on Windows, I want to see the mood bubble at all times when it's active, not only when furniture overlaps it.

**Acceptance Criteria:**
- [ ] Mood bubble is visible when shown, regardless of whether furniture is nearby
- [ ] The passthrough polygon correctly includes the bubble's rect when visible
- [ ] Bubble visibility works on Windows (the platform where the bug was reported)

### US-006: Fix shop and inventory button images
**Description:** As a player, I want the shop and inventory buttons to display their images correctly without misalignment or cropping.

**Acceptance Criteria:**
- [ ] Shop button image is fully visible, not cropped
- [ ] Both shop and inventory button images are properly aligned within their buttons
- [ ] Buttons look correct at different window/DPI scales

### US-007: Clean up GlobalInput plugin dead code
**Description:** As a developer, I want the GlobalInput plugin file to be clean and free of commented-out code.

**Acceptance Criteria:**
- [ ] Remove the commented-out `add_autoload_singleton` and `remove_autoload_singleton` lines from `plugin.gd`
- [ ] `_enter_tree()` and `_exit_tree()` contain only `pass` (or are removed if empty methods aren't required)
- [ ] The game still starts and GlobalInput functions correctly (autoload is handled elsewhere)

## Functional Requirements

- FR-1: The shop's `_create_buy_popup()` must build the popup node tree so that `_update_buy_popup()` can find `QtyLabel`, `MinusBtn`, and all other child nodes by name
- FR-2: `_furniture_nodes` and `_furniture_positions` dictionaries in `main.gd` must use unique instance keys (not bare `furniture_id`) to allow multiple items of the same type
- FR-3: `_spawn_furniture_at()` must check inventory count vs. already-placed count for the given `furniture_id` before allowing placement
- FR-4: `_update_bubble_position()` in `pet.gd` must account for the pet's `scale.x` direction so the bubble offset is correct when the pet faces left, and the bubble itself must not be flipped
- FR-5: Mood bubble icon size, label font size, and panel padding must be reduced by approximately 50%
- FR-6: The passthrough polygon calculation must include the mood bubble's screen rect when the bubble is visible, ensuring it renders above the transparent window on Windows
- FR-7: Shop and inventory button images must use correct `stretch_mode`, alignment, and sizing so they are not cropped or offset
- FR-8: Remove all commented-out code from `addons/global_input/plugin.gd`

## Non-Goals

- No new shop features (search, categories, sorting)
- No new furniture types or mechanics
- No mood system changes beyond the bubble visual/position fixes
- No redesign of the menu or button styling — just fix current image alignment/cropping
- No changes to how GlobalInput is registered as an autoload (that's handled outside the plugin)

## Technical Considerations

- The duplicate placement fix touches save/load serialization — must maintain backwards compatibility with existing `save_data.json` files that use bare `furniture_id` keys
- The mood bubble flip fix likely requires counter-scaling the bubble (e.g., `_bubble_panel.scale.x = sign(scale.x)`) or reparenting it outside the pet's transform hierarchy
- The Windows-only bubble visibility bug may be related to the passthrough polygon not including the bubble area, causing the compositor to treat it as click-through/invisible
- Shop popup node references failing suggests the popup's node tree structure changed or nodes aren't being added to the correct parent

## Success Metrics

- Zero `Node not found` or `null instance` errors when using the shop
- Players can place N items of type X if they own N in inventory
- Mood bubble is readable and correctly positioned regardless of pet direction or platform
- Shop and inventory buttons display images without visual artifacts

## Open Questions

- Is the shop popup being recreated each time an item is clicked, or is it created once and reused? (Determines whether the fix is in creation or lookup)
- Are there other dictionaries or systems (e.g., save/load, edit mode) that also key by bare `furniture_id` and need the same unique-key treatment?
- Is the Windows bubble visibility issue specific to the passthrough system, or could it be a Godot rendering order / z-index issue?
