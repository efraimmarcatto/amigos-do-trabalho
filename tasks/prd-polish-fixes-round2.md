# PRD: Polish & Fixes Round 2

## Introduction

A collection of bug fixes, UI improvements, and new features for the Amigos do Trabalho desktop pet application. These address usability issues discovered after the initial menu/shop/inventory/pet implementation: furniture rendering and scale, edit mode workflow gaps, shop/inventory layout overhaul, click passthrough accuracy, pet behavior edge cases, and quality-of-life additions like an exit button and first-launch hint.

## Goals

- Fix furniture rendering order so furniture always appears behind the pet
- Add configurable scale to furniture art via FurnitureData
- Improve edit mode so the menu remains visible, inventory items can be placed, and the "send to inventory" button doesn't obstruct furniture
- Overhaul shop and inventory panels to use responsive icon grids
- Fix mouse click passthrough to use actual object shapes instead of bounding rectangles
- Add an exit game button to the menu
- Add a stackable flag to furniture for items like clocks and mugs
- Fix pet getting permanently stuck attempting to jump on furniture
- Fix discard confirmation popup positioning
- Remove commented-out coin animation code and keep coin HUD static
- Prevent settings from opening on game start; add an animated menu hint arrow

## User Stories

### US-032: Furniture Display Scale Configuration
**Description:** As a developer, I want to configure the display scale of each furniture type in its FurnitureData resource so that pixel art renders at the correct size without manual scene adjustments.

**Acceptance Criteria:**
- [ ] `FurnitureData` has a new export var `display_scale: Vector2` defaulting to `Vector2(1, 1)`
- [ ] When furniture is spawned, its sprite scale is set to `display_scale`
- [ ] Existing furniture `.tres` files are updated with appropriate scale values
- [ ] Collision shapes scale proportionally with the sprite
- [ ] Scale is applied consistently whether placing from shop or loading from save

### US-033: Exit Game Button
**Description:** As a player, I want an exit button in the menu so I can close the application without using the taskbar or task manager.

**Acceptance Criteria:**
- [ ] "Exit" button added to the slide menu below the Settings button
- [ ] The empty space below Settings is used for the button; excess panel area below the button is removed
- [ ] Clicking the button calls `get_tree().quit()`
- [ ] Button uses a style consistent with existing menu buttons
- [ ] Button label is translatable (added to translation CSV)

### US-034: Edit Mode — Persistent Menu and Inventory Access
**Description:** As a player, I want the menu and "Save Edit" button to remain visible during edit mode, and I want to grab items from inventory to place them while editing, so the workflow is seamless.

**Acceptance Criteria:**
- [ ] The slide menu remains visible (not hidden) when entering edit mode
- [ ] The "Save Edit" button is always visible during edit mode to make it clear that saving is required
- [ ] While in edit mode, the player can open the inventory panel and select items to place
- [ ] Placing an item from inventory during edit mode adds it to the scene and decrements inventory count
- [ ] The "send to inventory" button (remove/chest icon on each furniture) is positioned above the furniture sprite height so it does not obstruct the furniture view
- [ ] Exiting edit mode via "Save Edit" or Escape persists all changes (existing behavior preserved)

### US-035: Furniture Z-Ordering (Behind Pet)
**Description:** As a player, I want furniture to always render behind the pet so the pet is never obscured by furniture.

**Acceptance Criteria:**
- [ ] A container node (e.g., `FurnitureContainer`) is created for all furniture instances in the scene
- [ ] The furniture container's z-index is set lower than the pet sprite's z-index
- [ ] Newly placed furniture is added as a child of the furniture container
- [ ] Furniture loaded from save is also added to the furniture container
- [ ] Pet is always visible in front of all furniture pieces

### US-036: Remove Coin Animation Code
**Description:** As a developer, I want the commented-out coin animation code removed so the codebase stays clean, and the coin HUD stays in its initial position at all times.

**Acceptance Criteria:**
- [ ] All commented-out coin animation code is deleted from `coin_hud.gd` and any related scripts
- [ ] The coin HUD remains in its initial fixed position at all times (no movement when menu opens/closes)
- [ ] Any tween or animation references for coin HUD movement are removed
- [ ] Coin value change animation (counter tween) is preserved if it exists separately

### US-037: Shop and Inventory Icon Grid Layout
**Description:** As a player, I want the shop and inventory to display items as a responsive icon grid so I can browse items visually and efficiently.

**Acceptance Criteria:**
- [ ] Shop displays items as icons in a responsive grid that fills available width with as many icons as fit
- [ ] Each shop icon shows the furniture sprite/thumbnail at a readable size
- [ ] The item price is displayed below the icon in the shop
- [ ] Hovering over a shop item shows the item name in a tooltip
- [ ] Inventory displays items in the same responsive icon grid layout
- [ ] Inventory icons show the furniture sprite/thumbnail and quantity badge
- [ ] Hovering over an inventory item shows the item name in a tooltip
- [ ] No price is shown in inventory icons
- [ ] Quantity selector and buy button in shop are accessible from the icon (e.g., click to open a small buy popover, or inline controls)

### US-038: Discard Confirmation Popup Positioning
**Description:** As a player, I want the discard confirmation popup to appear near the menu rather than in the center of the screen so it feels contextual and doesn't require large mouse movements.

**Acceptance Criteria:**
- [ ] Discard confirmation dialog appears near the slide menu / inventory panel area
- [ ] Dialog is positioned so it does not overflow off-screen
- [ ] Dialog remains functional (confirm/cancel buttons work as before)

### US-039: Furniture Stacking Flag
**Description:** As a developer, I want a flag on FurnitureData that allows certain items to be placed on top of other furniture so we can support decorative objects like clocks, mugs, and similar items.

**Acceptance Criteria:**
- [ ] `FurnitureData` has a new export var `stackable: bool` defaulting to `false`
- [ ] Stackable items, when placed, snap to the top surface of the furniture below them
- [ ] Non-stackable items can only be placed on the floor level (existing behavior)
- [ ] Stackable items are saved with a reference to their parent furniture or with their absolute Y position
- [ ] Stacked items move with their parent furniture during edit mode drag
- [ ] Removing the base furniture from the scene also removes or sends stacked items to inventory

### US-040: Pet Jump Timeout
**Description:** As a player, I want my pet to stop attempting to jump on furniture after repeated failures so it doesn't get stuck in an infinite loop, and instead plays a brief frustrated reaction.

**Acceptance Criteria:**
- [ ] Pet tracks consecutive failed jump attempts toward the same furniture target
- [ ] After a configurable maximum number of attempts (e.g., 3-5, export var), the pet gives up on that target
- [ ] On giving up, the pet plays a brief frustrated/sad reaction (e.g., mood bubble or short animation)
- [ ] After the reaction, the pet resumes normal walking behavior on its current surface
- [ ] The failed-attempt counter resets when the pet successfully jumps or targets different furniture
- [ ] The maximum attempts value is configurable in the Godot editor

### US-041: Fix Mouse Click Passthrough
**Description:** As a player, I want mouse clicks to pass through to the desktop in empty spaces between furniture, the pet, and the menu, instead of being blocked by invisible bounding rectangles.

**Acceptance Criteria:**
- [ ] The passthrough polygon is built from the actual visible shapes/sprites of objects, not from enclosing rectangles of the entire HUD layer
- [ ] Empty space between furniture pieces allows clicks to pass through to the desktop
- [ ] Empty space between the pet and the menu allows clicks to pass through
- [ ] All interactive UI elements (menu, panels, buttons, coin HUD) still block clicks correctly
- [ ] All furniture pieces still block clicks correctly (for interaction)
- [ ] The pet sprite still blocks clicks correctly (for dragging)

### US-042: Game Start State and Menu Hint Arrow
**Description:** As a player, I want the game to start with settings closed and see a brief animated arrow pointing to the menu so I know where to find it on first launch.

**Acceptance Criteria:**
- [ ] The game does not start with the settings panel open (fix current behavior)
- [ ] On game start, an animated arrow sprite appears pointing at the hamburger menu button
- [ ] The arrow has a bouncing or pulsing animation to draw attention
- [ ] The arrow disappears after a configurable duration (export var in seconds, editable in Godot editor)
- [ ] The arrow disappears immediately if the player opens the menu before the timer expires
- [ ] The arrow is not shown if the player has already interacted with the menu in a previous session (persist a `has_seen_menu_hint: bool` in `save_data.json`)

## Functional Requirements

- FR-25: Add `display_scale: Vector2` export to `FurnitureData`; apply to sprite and collision on spawn
- FR-26: Add "Exit" button to slide menu; calls `get_tree().quit()`
- FR-27: Keep slide menu visible during edit mode; allow opening inventory panel to place items
- FR-28: Position furniture remove buttons above furniture sprite height
- FR-29: Create a `FurnitureContainer` node with z-index lower than the pet for all furniture instances
- FR-30: Delete all commented-out coin animation/movement code; keep coin HUD position static
- FR-31: Replace shop item list with a responsive icon grid; show price below icon, name on hover tooltip
- FR-32: Replace inventory item list with a responsive icon grid; show quantity badge, name on hover tooltip
- FR-33: Position discard confirmation dialog near the menu/inventory panel area
- FR-34: Add `stackable: bool` export to `FurnitureData`; stackable items snap to parent furniture surface
- FR-35: Stacked items move with parent during edit; removing parent sends stacked items to inventory
- FR-36: Track consecutive failed jump attempts per furniture target; give up after configurable max (export var)
- FR-37: Play frustrated reaction on jump give-up, then resume walking
- FR-38: Build passthrough polygon from individual object shapes rather than HUD-level bounding rectangles
- FR-39: Do not open settings panel on game start
- FR-40: Show animated bouncing arrow pointing at menu button on start; configurable duration (export var)
- FR-41: Persist `has_seen_menu_hint` in save data; skip arrow on subsequent launches

## Non-Goals

- No furniture rotation or flipping
- No multi-tile or large furniture that spans multiple grid cells
- No animated furniture (furniture remains static sprites)
- No drag-and-drop reordering within inventory grid
- No search or filter functionality in shop/inventory (simple grid is sufficient)
- No custom tooltips — use Godot's built-in tooltip system

## Design Considerations

- The icon grid should use consistent thumbnail sizes (e.g., 48x48 or 64x64 display area per item)
- Shop icons could show a small coin icon + price beneath the thumbnail
- Inventory icons should show a quantity badge in the corner (e.g., "x3")
- The menu hint arrow should be a simple sprite — no complex animation system needed
- The frustrated pet reaction should be short (1-2 seconds) and non-disruptive
- Furniture container z-ordering should use Godot's built-in z-index rather than manual draw order

## Technical Considerations

- **Passthrough polygon:** Instead of one large polygon for the HUD, build the polygon as a union of individual rects per visible object (pet sprite rect, each furniture rect, each visible UI panel rect). This may require refactoring `_update_passthrough()` in `main.gd`
- **Furniture container:** Add a `Node2D` named `FurnitureContainer` to the scene tree; set its `z_index` below the pet. All furniture add/remove operations should target this container
- **Stackable furniture:** Placement mode needs to detect if the mouse is over an existing furniture surface and snap the Y coordinate accordingly. Save format should store the absolute position (existing format likely works)
- **Icon grid:** Use Godot's `GridContainer` or `FlowContainer` with responsive column calculation based on panel width. Each grid cell is a `TextureButton` or custom `Control` with a `TextureRect` child
- **Menu hint arrow:** A simple `Sprite2D` or `TextureRect` with a `Tween` for bounce animation and a `Timer` for auto-hide. Persist hint-seen flag in save data
- **Display scale:** Apply `display_scale` to both the `Sprite2D` and the `CollisionShape2D` of furniture on instantiation. Ensure save/load does not override this

## Success Metrics

- Furniture always renders behind the pet regardless of position
- Clicks pass through to desktop in all empty spaces between objects
- Players can complete a full edit mode workflow (rearrange, add from inventory, remove, save) without the menu disappearing
- Shop and inventory are browseable with a visual icon grid
- Pet never gets permanently stuck attempting to jump
- New players notice the menu hint arrow on first launch

## Open Questions

- What icon/sprite should the hint arrow use? (A simple triangle/chevron placeholder can be used initially)
- Should the frustrated pet reaction use the existing mood speech bubble system or a separate animation?
- For stackable items: should there be a limit to how many items can stack on one piece of furniture?
