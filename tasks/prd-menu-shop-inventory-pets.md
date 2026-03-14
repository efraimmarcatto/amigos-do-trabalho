# PRD: Menu & HUD Overhaul, Shop & Inventory System, Settings, and Pet Enhancements

## Introduction

A major feature expansion for the Amigos do Trabalho desktop pet application. This PRD covers six interconnected systems: a redesigned coin HUD with animated counter, a shop supporting bulk purchases, a new inventory system for storing and managing furniture, edit mode improvements for removing furniture, a settings panel with language and monitor selection, and pet system enhancements including pet selection UI, mood speech bubbles, and a held animation.

## Goals

- Redesign the coin display as a game-style HUD element positioned next to the menu button with smooth animation
- Allow purchasing multiple units of the same furniture and storing them in an unlimited inventory
- Provide a discard interface that refunds a configurable portion of coins per furniture item
- Enable furniture removal from the scene (to inventory) during edit mode and placement
- Add a settings panel with language selection and monitor selection
- Build a scalable pet selection UI driven by available SpriteFrames resources
- Display pet mood via image-based speech bubbles with context-aware frequency
- Add a dedicated "dragged" animation for the pet (distinct from idle)

## User Stories

### US-020: Coin HUD Redesign
**Description:** As a player, I want a game-style coin display (icon + animated counter, no label) positioned next to the menu toggle button so the HUD feels polished and integrated.

**Acceptance Criteria:**
- [ ] Coin display is a styled panel with a coin icon and numeric value (no "Coins:" label)
- [ ] Positioned directly next to (left of) the menu toggle button at the bottom-right
- [ ] Counter animates when value changes (tween counting up/down)
- [ ] White/light background with rounded corners to match game-style HUD
- [ ] Included in the mouse passthrough polygon so it remains clickable/visible
- [ ] Coin HUD moves upward smoothly when the slide menu opens (same tween timing as menu)
- [ ] Returns to original position when menu closes

### US-021: Shop Window Positioning and Visual Sequence
**Description:** As a player, I want the shop window to appear next to the menu in a smooth visual sequence so the UI feels cohesive.

**Acceptance Criteria:**
- [ ] Shop panel appears adjacent to (left of) the slide menu panel
- [ ] Shop opens with a tween animation that follows the menu open animation (slight delay or chained)
- [ ] Shop closes before or simultaneously with the menu when the menu is closed
- [ ] Shop panel is included in the mouse passthrough polygon when visible

### US-022: Bulk Purchase in Shop
**Description:** As a player, I want to buy multiple units of the same furniture item at once so I can furnish my space efficiently.

**Acceptance Criteria:**
- [ ] Each shop item row includes a quantity selector (- / number / + controls)
- [ ] Default quantity is 1, minimum is 1
- [ ] Total cost displayed dynamically (unit price × quantity)
- [ ] "Buy" button purchases the selected quantity if the player has enough coins
- [ ] Purchased items go directly to the inventory (not immediate placement)
- [ ] Items previously marked "Owned" can now be purchased again (no single-purchase limit)
- [ ] Coins deducted for full quantity on purchase

### US-023: Inventory System
**Description:** As a player, I want an inventory to store purchased furniture and items removed from the scene so I can manage my collection.

**Acceptance Criteria:**
- [ ] New "Inventory" button added to the slide menu
- [ ] Inventory panel displays all stored furniture with icon, name, and quantity per type
- [ ] Unlimited capacity — no slot or quantity restrictions
- [ ] Inventory persisted in `save_data.json` (e.g., `"inventory": {"table": 2, "sofa": 1}`)
- [ ] Selecting an item from inventory triggers placement mode for that item
- [ ] Successfully placing an item decrements its inventory count by 1
- [ ] Items with 0 quantity are hidden or grayed out

### US-024: Discard Furniture Interface
**Description:** As a player, I want to discard furniture from my inventory and receive a partial coin refund so I can recoup some value from unwanted items.

**Acceptance Criteria:**
- [ ] Each inventory item row includes a "Discard" button (trash icon or similar)
- [ ] Clicking discard shows a confirmation dialog with the refund amount
- [ ] Refund amount is configurable per furniture item via a new `discard_refund_ratio` field on `FurnitureData` (e.g., 0.5 = 50%)
- [ ] Coins are credited immediately upon confirmation
- [ ] Item quantity in inventory decrements by 1
- [ ] Discard is only available for inventory items (not placed furniture — that uses edit mode)

### US-025: Furniture Removal in Edit Mode
**Description:** As a player, I want to remove placed furniture from the scene during edit mode and send it back to my inventory.

**Acceptance Criteria:**
- [ ] Each furniture piece shows a remove button (X icon or chest icon) when edit mode is active
- [ ] Clicking the remove button sends the furniture to inventory (increments count)
- [ ] Furniture instance is removed from the scene
- [ ] Pet that was standing on removed furniture enters FALLING state
- [ ] A "Save Edit" button is displayed during edit mode (can be the Edit button changing label/state or a new button)
- [ ] Clicking "Save Edit" exits edit mode and persists all changes
- [ ] Pressing Escape also exits edit mode and persists changes (existing behavior)

### US-026: Store-to-Inventory During Placement
**Description:** As a player, I want to store a newly purchased furniture item directly into inventory during placement mode instead of placing it in the scene.

**Acceptance Criteria:**
- [ ] A chest/inventory icon button is visible during placement mode (near the ghost sprite or in a fixed UI position)
- [ ] Clicking the chest icon cancels placement and sends the item to inventory (no coin refund needed — item is kept)
- [ ] This replaces the current right-click/Escape cancel behavior that refunds coins
- [ ] Right-click/Escape during placement still cancels but now also sends to inventory instead of refunding

### US-027: Settings — Language Selection
**Description:** As a player, I want to select my preferred language from a settings menu so the game displays text in my language.

**Acceptance Criteria:**
- [ ] "Settings" button in the slide menu replaces the "Settings (coming soon)" placeholder
- [ ] Settings panel opens adjacent to the menu (similar positioning to shop)
- [ ] Language dropdown with available languages (start with English and Portuguese)
- [ ] Changing language updates all UI text immediately (uses Godot's built-in `TranslationServer`)
- [ ] Selected language persisted in `save_data.json`
- [ ] Language loads on startup

### US-028: Settings — Monitor Selection
**Description:** As a player, I want to choose which monitor the game renders on so I can position my desktop pet on my preferred screen.

**Acceptance Criteria:**
- [ ] Monitor selection dropdown in settings panel listing all connected displays
- [ ] Each entry shows monitor name/index and resolution (e.g., "Monitor 1 — 1920×1080")
- [ ] Selecting a monitor moves the game window to that screen
- [ ] Floor Y recalculated for the new screen's usable rect
- [ ] All furniture repositioned relative to new screen bounds
- [ ] Selected monitor persisted in `save_data.json`
- [ ] Falls back to primary monitor if saved monitor is no longer connected

### US-029: Pet Selection UI
**Description:** As a player, I want to select my pet from a menu driven by available SpriteFrames resources so I can choose my companion.

**Acceptance Criteria:**
- [ ] "Select Pet" button added to the slide menu
- [ ] Pet selection panel opens with a scrollable grid/list of available pets
- [ ] Pets are discovered dynamically by scanning a directory for `.tres` SpriteFrames files (e.g., `res://pet/`)
- [ ] Each pet entry shows a preview sprite (first frame of idle animation) and the pet name (derived from filename)
- [ ] UI scales to any number of pets (scrollable grid layout)
- [ ] Selecting a pet swaps the `AnimatedSprite2D.sprite_frames` on the pet node
- [ ] Currently selected pet is highlighted/indicated
- [ ] Selected pet persisted in `save_data.json`
- [ ] Ozzy is the default if no selection is saved

### US-030: Pet Mood Speech Bubble
**Description:** As a player, I want my pet to display its mood via image-based speech bubbles so I can understand how it feels.

**Acceptance Criteria:**
- [ ] Speech bubble appears above the pet's head with a mood image inside (no text)
- [ ] Mood images: happy, neutral, sad/hungry (minimum set; loaded from assets)
- [ ] Bubble appears on mood change events (coin threshold crossings)
- [ ] Bubble appears on interactions (feed, play, sleep)
- [ ] For SAD/hungry mood: bubble reappears at random intervals (e.g., every 15-45 seconds) as a reminder
- [ ] Bubble auto-hides after 3-5 seconds with a fade-out animation
- [ ] Bubble follows pet position (anchored above head)
- [ ] Pet color/modulate must NOT be altered by the mood system (remove existing mood tinting)
- [ ] Bubble included in mouse passthrough polygon when visible

### US-031: Pet Dragged Animation
**Description:** As a player, I want my pet to play a unique `dragged` animation when I'm holding/dragging it so the interaction feels alive.

**Acceptance Criteria:**
- [ ] `dragged` animation built from a dedicated sprite sheet row (distinct from idle), configurable via `dragged_row` export var
- [ ] Animation plays when pet enters DRAGGED state
- [ ] Animation loops while the pet is held
- [ ] Reverts to `fall` animation on release
- [ ] Works with any pet SpriteFrames (animation name convention: `dragged`)
- [ ] If the dragged row has no frames, falls back to `idle`

## Functional Requirements

- FR-1: Replace the current `CoinLabel` with a game-style HUD panel (icon + animated counter) anchored next to the menu toggle button
- FR-2: Animate the coin HUD upward when the slide menu opens and back down when it closes
- FR-3: Position the shop panel adjacent to the slide menu with a chained open/close animation
- FR-4: Add a quantity selector to each shop item row; calculate and display total cost dynamically
- FR-5: Remove the single-purchase restriction — allow buying any furniture multiple times
- FR-6: Create an inventory data structure (`Dictionary[String, int]`) tracking item ID → quantity, persisted in `save_data.json`
- FR-7: Add an Inventory panel accessible from the slide menu, showing stored items with quantity and action buttons
- FR-8: Placing an item from inventory decrements its count; removing a placed item increments it
- FR-9: Add a `discard_refund_ratio: float` export to `FurnitureData`; default to 0.5 for existing items
- FR-10: Discard action shows confirmation and credits `coin_cost × discard_refund_ratio` coins
- FR-11: Show a remove button on each placed furniture during edit mode; removal sends to inventory
- FR-12: Display a "Save Edit" button during edit mode; clicking it exits edit mode and saves
- FR-13: Show a chest/inventory icon during placement mode; clicking it stores the item in inventory instead of placing
- FR-14: Change right-click/Escape during placement to send item to inventory (no refund, item kept)
- FR-15: Add a Settings panel with language dropdown using Godot `TranslationServer`
- FR-16: Add a monitor selection dropdown in Settings using `DisplayServer.screen_get_count()` and related APIs
- FR-17: Recalculate `floor_y` and reposition furniture when monitor changes
- FR-18: Add a pet selection panel that dynamically scans `res://pet/` for `.tres` SpriteFrames files
- FR-19: Swap `AnimatedSprite2D.sprite_frames` when a new pet is selected
- FR-20: Implement a speech bubble node (Sprite2D or TextureRect inside a Panel) anchored above the pet
- FR-21: Trigger speech bubble on mood changes and interactions; for SAD mood, trigger at random 15-45s intervals
- FR-22: Remove all `modulate` color changes from the pet mood system — mood is communicated only via speech bubbles
- FR-23: Build a distinct `dragged` animation from its own sprite sheet row; play it during DRAGGED state with fallback to `idle`
- FR-24: All new UI panels must be included in the mouse passthrough polygon when visible

## Non-Goals

- No crafting or combining furniture items
- No multiplayer or online features
- No pet stats beyond mood (no hunger bar, health bar, etc.)
- No furniture rotation or multi-tile furniture
- No in-app purchases or real currency — coins are earned only through keyboard/mouse input
- No pet AI personality differences (all pets share the same behavior logic)
- No animated transitions between monitors
- No cloud save — all persistence is local `save_data.json`

## Design Considerations

- The bottom-right corner is the UI anchor point: menu button → coin HUD → panels extend leftward
- All panels (shop, inventory, settings, pet selection) should share a consistent visual style
- The inventory and shop panels should not be open simultaneously to avoid clutter
- Speech bubble images should be simple, expressive icons (think emoji-style) that read clearly at small sizes
- Pet selection grid should use consistent thumbnail sizes with a subtle highlight/border for the active pet
- The "Save Edit" button should be visually prominent (e.g., green accent) to signal the user is in a temporary mode

## Technical Considerations

- **Inventory storage:** Extend `save_data.json` schema with `"inventory": {}` dictionary and `"selected_pet": "ozzy"` string
- **Furniture data migration:** Add `discard_refund_ratio` export to `FurnitureData` resource; existing `.tres` files need this field added
- **Translation:** Use Godot's `TranslationServer` with `.csv` or `.po` translation files in a `res://translations/` directory
- **Monitor API:** Use `DisplayServer.screen_get_count()`, `DisplayServer.screen_get_position()`, `DisplayServer.screen_get_size()` to enumerate monitors; `DisplayServer.window_set_current_screen()` to switch
- **Pet discovery:** Use `DirAccess.open("res://pet/")` to list `.tres` files at runtime; each must be a valid `SpriteFrames` resource
- **Speech bubble:** Implement as a child node of the pet with a `Sprite2D` for the bubble background and a `TextureRect` for the mood image; use `Tween` for fade-in/fade-out
- **Passthrough:** Every new UI element must be added to `_update_passthrough()` in `main.gd`
- **Mood refactor:** Remove `modulate` changes from `pet.gd` mood handling; route all mood display through the speech bubble system

## Success Metrics

- Player can purchase, store, place, remove, and discard furniture in a complete lifecycle
- Coin HUD is always visible and correctly positioned relative to the menu in all states (open/closed)
- Pet mood is communicated clearly through speech bubbles without altering pet sprite colors
- Language and monitor settings persist across sessions
- Pet selection UI works with 1 pet (Ozzy) and will scale to N pets without code changes

## Open Questions

- What specific coin icon asset should be used for the HUD? (placeholder can be a yellow circle until art is provided)
- What mood images should be used for the speech bubble? (placeholder icons can be used initially)
- Should the dragged animation be a completely new sprite sheet row, or a programmatic effect (e.g., squish/wobble) applied to existing frames?
- What languages beyond English and Portuguese should be supported initially?
- Should furniture in inventory be sortable or filterable, or is a simple list sufficient for now?
