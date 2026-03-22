# PRD: Layout Edit, Shop UI, and Pet Layering Regression Fixes

## 1. Introduction/Overview

This PRD defines a focused regression fix for the in-game layout/shop flow. Current behavior allows moving items, but layout editing actions are partially broken: the `X` action does not reliably send furniture to inventory, saving layout is not working, shop item visuals are misaligned/oversized relative to buttons, buy action is broken, and pet interaction/layering conflicts with UI and furniture.

The goal is to restore expected behavior without redesigning the system.

## 2. Goals

- Restore layout edit mode so `X` appears only during edit mode and sends item to inventory when clicked.
- Restore layout save action so furniture placements persist after save.
- Correct shop item image/button sizing and alignment to match current UI layout.
- Fix shop buy action so purchases complete correctly.
- Ensure scene hierarchy/layering places UI elements and placeable items in a node behind the pet node.
- Ensure pet remains interactable/draggable when visually in front of furniture/menu based on configured node order.

## 3. User Stories

### US-001: Show `X` only in layout edit mode
**Description:** As a player, I want the remove (`X`) controls to appear only when layout edit mode is active so normal play mode stays clean and non-destructive.

**Acceptance Criteria:**
- [ ] `X` control is hidden for all placeable items when layout edit mode is off.
- [ ] `X` control is visible for editable placeable items when layout edit mode is on.
- [ ] Entering/exiting edit mode toggles visibility immediately without reopening the scene.
- [ ] Verify in browser.

### US-002: Send furniture to inventory via `X`
**Description:** As a player, I want clicking `X` in edit mode to immediately move the item back to inventory so I can quickly reorganize the room.

**Acceptance Criteria:**
- [ ] Clicking `X` in edit mode removes the selected placed item from the room.
- [ ] Removed item quantity is incremented in inventory immediately.
- [ ] No confirmation dialog is shown.
- [ ] Action is ignored when edit mode is off because `X` is not shown/usable.
- [ ] Verify in browser.

### US-003: Save layout persists moved/edited items
**Description:** As a player, I want Save Layout to persist my moved furniture and edit actions so my arrangement remains after reload.

**Acceptance Criteria:**
- [ ] Clicking Save Layout writes current item transforms/state to the existing persistence path.
- [ ] After save and scene reload (or app restart), positions match the saved layout.
- [ ] If save fails, user gets visible feedback and previous persisted layout is not corrupted.
- [ ] Verify in browser.

### US-004: Fix shop item visual fit (images and buttons)
**Description:** As a player, I want shop item images to fit and align with buttons so the shop is readable and usable.

**Acceptance Criteria:**
- [ ] Item images fit inside their intended card/button bounds without overflow.
- [ ] Image anchors/margins are aligned consistently with button labels and prices.
- [ ] No item image overlaps neighboring controls in the tested shop viewport.
- [ ] Verify in browser.

### US-005: Fix shop buy action
**Description:** As a player, I want the Buy action to complete reliably so purchased items are added correctly.

**Acceptance Criteria:**
- [ ] Clicking Buy on an affordable item completes purchase and updates inventory/coins immediately.
- [ ] Clicking Buy on non-affordable item does not complete purchase and provides existing error/feedback behavior.
- [ ] Rapid repeated clicks do not duplicate purchase beyond allowed quantity rules.
- [ ] Verify in browser.

### US-006: Enforce node layering so pet is in front of UI/item layer
**Description:** As a player, I want pet visibility/interaction to follow explicit node order, with UI elements and placeable items under the pet node.

**Acceptance Criteria:**
- [ ] Scene tree contains a node grouping UI elements and placeable items behind the pet node.
- [ ] Pet node renders in front according to node/canvas order (not only ad-hoc `z_index` overrides).
- [ ] Dragging pet remains possible when overlapping furniture/menu visuals under the configured hierarchy.
- [ ] Verify in browser.

## 4. Functional Requirements

- FR-1: The system must gate remove controls (`X`) by layout edit mode state.
- FR-2: When user clicks `X` during layout edit mode, the selected placed furniture must be removed from room and returned to inventory immediately.
- FR-3: The system must persist current layout state when Save Layout is triggered and reload the same state later.
- FR-4: Shop item image containers and button bounds must use consistent sizing/alignment rules so images do not exceed button/card layout.
- FR-5: The Buy action must validate affordability and apply one authoritative transaction update to currency and inventory.
- FR-6: Scene structure must place UI/menu and placeable item nodes in a layer/node that is behind the pet node.
- FR-7: Pet drag hit-testing/input handling must remain active when pet overlaps visuals from lower-priority nodes.

## 5. Non-Goals (Out of Scope)

- Full redesign of shop or layout editor UX.
- New inventory features, filters, or pagination.
- New animation systems for furniture/pet interactions.
- Major art/asset replacement for shop items.
- Cross-platform UI overhaul beyond current target behavior.

## 6. Design Considerations

- Preserve current visual style; only adjust sizing/alignment needed to make images/buttons fit.
- Keep `X` affordance minimal and only visible during edit mode.
- Avoid clutter in normal mode by keeping edit-only controls hidden.

## 7. Technical Considerations

- Prefer deterministic node hierarchy/layer organization for draw/input behavior instead of relying solely on high `z_index` values.
- Ensure drag input routing for pet does not get blocked by overlay nodes that are visually behind/should be non-interactive for drag.
- Reuse existing save/load pipeline for layout persistence, patching only broken wiring/state serialization points.
- Maintain compatibility with existing item definitions and shop data structures.

## 8. Success Metrics

- `X` action works in edit mode and is unavailable outside edit mode.
- Save Layout successfully persists arrangement in manual verification runs.
- Shop visuals no longer show oversized/misaligned images relative to buttons.
- Buy action completes expected transaction outcomes without obvious duplication/regression.
- Pet remains draggable with configured node hierarchy where UI/items are behind pet.

## 9. Open Questions

- Should pet dragging be disabled while a modal dialog is open, or always remain available when visible?
- Which exact scene/node names should be standardized for layering (`World`, `UILayer`, `PetLayer`, etc.) to reduce future regressions?
