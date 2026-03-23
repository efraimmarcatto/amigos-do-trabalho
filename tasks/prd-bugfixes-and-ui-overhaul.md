# PRD: Bug Fixes, UI Overhaul, Pet Animations & Jumpable Furniture

## Introduction

Address critical bugs (furniture placement, mouse passthrough, Rect2 error) and deliver a set of UX improvements: a collapsible side menu, proper taskbar-aligned floor, pet animation state machine with sprite sheet support, pet stillness during interactions, and a new "jumpable" furniture flag so the pet can leap onto specific pieces.

---

## Goals

- Fix furniture not placeable after purchase (placement mode with mouse-follow)
- Fix mouse passthrough only working above the highest UI element (Rect2 negative size error)
- Consolidate all UI into a hidden slide-out menu on the bottom-right
- Align the game floor to the top edge of the OS taskbar
- Pet freezes in place when the interaction menu is open, resuming on menu close or click-away
- Define pet animation states (idle, walk, jump-prep, jumping, falling) with sprite sheet row support
- Add a `jumpable` flag to furniture so the pet can jump onto tagged pieces

---

## User Stories

### US-012: Fix Rect2 negative size error in passthrough
**Description:** As a user, I want the passthrough to work correctly across the entire screen so I can click through empty areas anywhere, not just above UI elements.

**Acceptance Criteria:**
- [ ] The `Rect2 size is negative` error in `main.gd:220 @ _update_passthrough()` no longer appears in the debug console
- [ ] All `Rect2` values passed to `.merge()` use `.abs()` to guarantee positive dimensions before merging
- [ ] Mouse passthrough works for ALL empty areas on screen regardless of where UI elements are positioned
- [ ] Clicks on the pet, furniture, and UI elements are still captured correctly
- [ ] Passthrough polygon correctly covers only visible interactive elements

### US-013: Furniture placement mode
**Description:** As a user, I want to place furniture by clicking a location after buying it so I can choose where it goes.

**Acceptance Criteria:**
- [ ] After purchasing furniture in the shop, the game enters "placement mode"
- [ ] The shop closes automatically when placement mode begins
- [ ] A semi-transparent preview of the furniture follows the mouse cursor
- [ ] The furniture preview is constrained to the floor level (Y = floor line, cannot float)
- [ ] The furniture preview is constrained horizontally within screen bounds
- [ ] Left-clicking places the furniture at the cursor's X position on the floor
- [ ] Right-click or Escape cancels placement (furniture is refunded to coins)
- [ ] Passthrough is disabled (full window captures input) during placement mode
- [ ] The placed furniture position is saved to `save_data.json`

### US-014: Furniture repositioning via edit mode
**Description:** As a user, I want to rearrange my furniture through an edit mode so I can redesign my desktop layout.

**Acceptance Criteria:**
- [ ] An "Edit Layout" button exists in the slide-out menu
- [ ] Clicking "Edit Layout" enters edit mode: all furniture pieces show a visual indicator (e.g. highlight, outline, or subtle glow)
- [ ] In edit mode, furniture can be dragged horizontally along the floor (Y stays fixed at floor level)
- [ ] Furniture cannot be dragged off-screen or overlapping other furniture
- [ ] A "Done" button or clicking "Edit Layout" again exits edit mode
- [ ] Updated positions are saved to `save_data.json` on exit from edit mode
- [ ] Pet pauses walking/interactions while edit mode is active

### US-015: Collapsible slide-out menu
**Description:** As a user, I want a clean UI with a single menu button on the bottom-right that slides open to reveal all options.

**Acceptance Criteria:**
- [ ] A single small button (icon or "☰") is always visible at the bottom-right of the screen
- [ ] Clicking the button slides a menu panel from right to left with a smooth animation (Tween, ~0.3s ease-out)
- [ ] The menu contains: Shop button, Edit Layout button, and a placeholder area for future settings
- [ ] Clicking the menu button again or clicking outside the menu slides it back (right) and hides it
- [ ] The old standalone shop button is removed
- [ ] The menu button and panel are included in the passthrough polygon when visible
- [ ] The menu is positioned above the taskbar (respects usable screen rect)

### US-016: Align game floor to taskbar top edge
**Description:** As a user, I want the pet and furniture to sit on top of my taskbar so the pet feels integrated with my desktop.

**Acceptance Criteria:**
- [ ] Use `DisplayServer.screen_get_usable_rect()` to determine the usable screen area (excludes taskbar)
- [ ] The game "floor" Y coordinate is set to the bottom of the usable rect (top of the taskbar)
- [ ] Pet ground level uses this floor Y (not full screen height)
- [ ] Furniture is placed at this floor level
- [ ] The window still covers the full screen (`DisplayServer.screen_get_size()`) so the pet can visually overlap the taskbar area if falling
- [ ] Works regardless of taskbar position (bottom, top, left, right) or size

### US-017: Pet stays still during interaction menu
**Description:** As a user, I want the pet to stop moving when I open its interaction menu so I can interact without it walking away.

**Acceptance Criteria:**
- [ ] When the pet interaction menu opens, the pet immediately transitions to IDLE (stops walking/falling)
- [ ] Pet remains in IDLE and does not pick new walk targets while the interaction menu is visible
- [ ] When the menu closes (button clicked or click-away), the pet resumes normal idle behavior (can walk again)
- [ ] If an interaction is selected (Feed/Play), the pet enters INTERACTING state as usual
- [ ] The interaction menu stays anchored near the pet (does not drift if menu opened mid-walk)

### US-018: Pet animation state definitions
**Description:** As a developer, I want the pet to support distinct animation states with sprite sheet rows so artists can drop in artwork later.

**Acceptance Criteria:**
- [ ] Pet uses an `AnimatedSprite2D` (or `Sprite2D` with `hframes`/`vframes`) instead of a plain `Sprite2D`
- [ ] Animation states defined: `idle`, `walk`, `jump_prep`, `jump`, `fall`, `interact`
- [ ] Each animation state maps to a row in the sprite sheet (row index configurable)
- [ ] `idle`: loops through idle frames (default: 1 frame placeholder)
- [ ] `walk`: loops through walk frames (default: 1 frame placeholder)
- [ ] `jump_prep`: plays 1 frame, brief pause (~0.15s), then transitions to `jump`
- [ ] `jump`: plays 1 frame, active while pet is moving upward
- [ ] `fall`: plays 1 frame, active while pet is moving downward (gravity)
- [ ] `interact`: plays during INTERACTING state (can reuse idle for now)
- [ ] Sprite still flips horizontally based on movement direction
- [ ] Placeholder texture works with a single-frame sprite sheet (no crash if only 1 frame per row)
- [ ] Animation FPS is configurable via export var

### US-019: Jumpable furniture flag and pet jumping
**Description:** As a user, I want my pet to jump onto certain furniture pieces so it feels more dynamic and playful.

**Acceptance Criteria:**
- [ ] `FurnitureData` has a new `jumpable: bool` property (default `false`)
- [ ] Jumpable furniture must also be `walkable` (jumpable implies the pet can be on top)
- [ ] When the pet is walking on the floor and is near a jumpable furniture piece (within configurable range, e.g. 80px horizontal), there is a random chance it will jump onto it
- [ ] Jump sequence: pet stops → plays `jump_prep` animation → pauses briefly → launches upward with an arc toward the furniture surface → plays `jump` while ascending → plays `fall` while descending → lands on the furniture's walk surface
- [ ] Jump physics: horizontal velocity toward furniture center + vertical impulse, then gravity takes over
- [ ] Pet can also jump DOWN from furniture (transitions to `fall` animation)
- [ ] Jump probability and range are configurable via export vars
- [ ] Update existing furniture data: `table` and `sofa` should have `jumpable = true`
- [ ] The `.tres` resource files are updated with the new `jumpable` field

---

## Functional Requirements

- **FR-11:** In `_update_passthrough()`, call `.abs()` on every `Rect2` before passing to `.merge()` to prevent the negative-size error.
- **FR-12:** Furniture placement mode is a new state in `main.gd`: a ghost sprite follows the mouse, constrained to floor Y; left-click confirms, right-click/Escape cancels and refunds coins.
- **FR-13:** Edit mode is a toggle state in `main.gd`: when active, furniture nodes accept drag input (horizontal only, Y locked to floor), pet state machine is paused.
- **FR-14:** The slide-out menu is a `PanelContainer` anchored to the bottom-right. Use a `Tween` to animate its `position.x` from off-screen to visible. The toggle button sits outside the panel and is always visible.
- **FR-15:** Floor Y is calculated as `DisplayServer.screen_get_usable_rect().position.y + DisplayServer.screen_get_usable_rect().size.y` — the bottom edge of the usable area.
- **FR-16:** Pet state machine gains a `menu_open` flag. While true, `_process_idle()` skips selecting new walk targets and the state is locked to `IDLE`.
- **FR-17:** `AnimatedSprite2D` with a `SpriteFrames` resource. Each animation name corresponds to a state. Rows in the sprite sheet map to animation names. Frame counts per animation are configurable.
- **FR-18:** `FurnitureData` gains `jumpable: bool`. Pet walking logic checks nearby jumpable furniture and probabilistically initiates a jump arc (parabolic trajectory using horizontal speed + vertical impulse + gravity).
- **FR-19:** Jump arc calculation: `velocity.x` = direction toward furniture center × `jump_horizontal_speed`, `velocity.y` = `-jump_impulse`. Gravity applies each frame. Landing detection reuses existing surface-check logic.

---

## Non-Goals

- No furniture rotation or resizing
- No furniture selling or removal (yet)
- No pet animation artwork — placeholders only, artist provides assets later
- No audio or sound effects
- No macOS support
- No multi-monitor support (primary monitor only)
- No furniture stacking (furniture only placed on the floor)

---

## Design Considerations

- The slide-out menu should feel lightweight — thin panel, minimal padding, icon-style buttons where possible
- Placement mode ghost sprite should be visually distinct (e.g. 50% opacity) so the user knows it's not yet placed
- Edit mode furniture highlights should be subtle (e.g. modulate color slightly) to avoid visual clutter
- The menu toggle button should be small and unobtrusive — consider a gear icon or hamburger icon
- Animation transitions should feel snappy: jump_prep is intentionally short (~0.15s) to keep the pet feeling responsive

---

## Technical Considerations

- **Passthrough fix:** The root cause is `Rect2` constructed with negative width/height when UI elements are at screen edges. The fix is straightforward — `.abs()` before merge.
- **`screen_get_usable_rect()`:** Returns a `Rect2i` with position and size excluding taskbar. On Linux (X11/Wayland) and Windows this is reliable. Fallback to `screen_get_size()` if usable rect returns zero.
- **Placement mode input:** During placement mode, set `mouse_passthrough_polygon` to an empty array (capture all input). Restore normal passthrough when placement ends.
- **Tween animation for menu:** Use `create_tween().tween_property(panel, "position:x", target_x, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)`.
- **AnimatedSprite2D vs Sprite2D:** `AnimatedSprite2D` with `SpriteFrames` is preferred because it natively supports named animations, per-animation FPS, and looping config — no manual frame math needed.
- **Jump physics:** Reuse existing gravity constant. Add `jump_impulse` and `jump_horizontal_speed` export vars. The jump is a standard projectile arc — no special curves needed.
- **Save data:** Schema unchanged structurally, just furniture positions update. No migration needed.

---

## Success Metrics

- Zero `Rect2 size is negative` errors in the debug console
- Furniture can be purchased and placed via mouse-click in under 3 seconds
- Mouse clicks pass through all empty screen areas regardless of UI element positioning
- Slide-out menu opens/closes smoothly with no visual glitches
- Pet visibly stops moving when interaction menu is open
- Pet performs jump onto jumpable furniture at least once per 2 minutes of idle
- Floor line aligns with the top of the OS taskbar visually

---

## Open Questions

- Should there be a max number of furniture pieces on screen at once?
- Should the pet prefer jumping onto nearby furniture vs walking to distant furniture?
- Should edit mode show furniture collision bounds to help avoid overlap?
- What should the menu button icon be — hamburger (☰), gear (⚙), or a custom pet icon?
