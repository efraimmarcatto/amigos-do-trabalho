# Amigos do Trabalho

A desktop pet companion that lives on your screen as a transparent overlay. Your pet reacts to your keyboard and mouse activity — stay active to keep it happy, earn coins, and furnish its world.

Built with Godot 4.6 using the GL Compatibility renderer for transparent, always-on-top windows with per-pixel click-through.

## Features

- **Transparent desktop overlay** — the pet sits on top of your desktop with click-through on empty areas
- **Pixel-art pet with state machine AI** — idle, walk, jump, fall, drag, and interact states with smooth transitions
- **Furniture system** — buy and place furniture from the shop; pet interacts with items (sit on sofa, eat from bowl, play with toy)
- **Shop and inventory** — purchase furniture with coins, store extras in inventory, place and rearrange freely
- **Coin economy** — earn coins through real keyboard and mouse activity via the GlobalInput native extension
- **Mood system** — pet mood (Sad, Neutral, Happy) changes based on coin balance with a visual bubble indicator
- **Multi-monitor support** — choose which monitor the pet lives on
- **Multi-language support** — English and Portuguese translations via CSV-based localization
- **Save/load persistence** — coins, furniture positions, inventory, selected pet, language, and monitor saved to JSON
- **Pet selection** — swap between different pets; new pets are auto-discovered from the `pet/data/` directory
- **Furniture Creator editor plugin** — visual tool inside the Godot editor for creating and editing furniture data resources

## Installation & Running

### Prerequisites

- [Godot 4.6+](https://godotengine.org/) (GL Compatibility renderer)
- C++ compiler and SCons (for building the GlobalInput native extension)
- Platform dependencies for GlobalInput — see [addons/global_input/README.md](addons/global_input/README.md)

### Setup

1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd amigos-do-trabalho
   ```

2. Initialize the godot-cpp submodule (needed for GlobalInput):
   ```bash
   git submodule update --init --recursive
   ```

3. Build the GlobalInput native extension:
   ```bash
   cd addons/global_input
   scons platform=linux    # or platform=windows
   cd ../..
   ```

4. Open the project in Godot 4.6+

5. Enable both plugins in **Project > Project Settings > Plugins**:
   - GlobalInput
   - Furniture Creator

6. Run the project (F5)

## Code Organization

### Directory Structure

| Directory | Purpose |
|-----------|---------|
| `scripts/` | Core game scripts (GDScript) |
| `scenes/` | Godot scene files (.tscn) |
| `pet/data/` | Pet SpriteFrames resources (.tres) |
| `furniture/data/` | Furniture data resources (.tres) |
| `addons/global_input/` | GlobalInput native extension plugin (C++ GDExtension) |
| `addons/furniture_creator/` | Furniture Creator editor plugin |
| `assets/` | Sprite sheets and images |
| `translations/` | Localization CSV and compiled .translation files |

### Key Scripts

| Script | Description |
|--------|-------------|
| `scripts/main.gd` | Main scene controller — manages transparent window, passthrough polygons, save/load, furniture spawning |
| `scripts/pet.gd` | Pet behavior — state machine (idle, walk, jump, fall, drag, interact), mood system, speech bubble |
| `scripts/coin_system.gd` | Polls GlobalInput for keyboard/mouse activity, converts to coins, handles decay on inactivity |
| `scripts/furniture.gd` | Runtime furniture node — displays sprite, handles pet interaction, cooldowns |
| `scripts/furniture_data.gd` | FurnitureData resource class — defines furniture properties (cost, walkable, interaction type, etc.) |
| `scripts/shop.gd` | Shop UI — lists available furniture for purchase |
| `scripts/inventory_panel.gd` | Inventory UI — shows owned furniture, place/remove items |
| `scripts/inventory_system.gd` | Inventory data management — tracks owned furniture counts |
| `scripts/interaction_menu.gd` | Right-click context menu for the pet |
| `scripts/slide_menu.gd` | Slide-out side menu for accessing shop, inventory, settings |
| `scripts/coin_hud.gd` | Coin balance display overlay |
| `scripts/settings_panel.gd` | Settings UI — language, monitor selection |
| `scripts/pet_selection_panel.gd` | Pet picker — auto-discovers pets from `pet/data/` directory |

## Furniture Configuration

Furniture items are defined as `FurnitureData` resources (`.tres` files) in `furniture/data/`. Each resource has the following properties:

| Property | Type | Description |
|----------|------|-------------|
| `id` | String | Unique identifier (e.g. `"sofa"`, `"toy"`) |
| `display_name` | String | Name shown in shop and inventory UI |
| `texture` | Texture2D | Sprite texture for the furniture |
| `coin_cost` | int | Purchase price in coins |
| `walkable` | bool | Whether the pet can walk on top of this furniture |
| `walk_surface_y_offset` | int | Y offset from the sprite top for the walkable surface |
| `can_fall_off_edge` | bool | Whether the pet can fall off the edges of this furniture |
| `jumpable` | bool | Whether the pet can jump onto this from the floor |
| `interaction_type` | String | Interaction kind: `"sleep"`, `"eat"`, `"play"`, or `""` (none) |
| `interaction_coin_bonus` | int | Coins awarded when the pet interacts |
| `interaction_cooldown` | float | Seconds before the same item can be interacted with again |
| `discard_refund_ratio` | float | Refund ratio when discarding (0.0–1.0) |
| `display_scale` | Vector2 | Scale applied to the sprite and collision shape |
| `stackable` | bool | Whether this can be placed on top of other walkable furniture |
| `collision_size_override` | Vector2 | Custom collision box size (Vector2.ZERO = auto from texture) |
| `collision_offset` | Vector2 | Collision shape offset from sprite center |
| `standing_size_override` | Vector2 | Custom standing area size for pet placement |
| `standing_offset` | Vector2 | Standing area offset from sprite center |

Current furniture items: `bookshelf.tres`, `food_bowl.tres`, `sofa.tres`, `table.tres`, `toy.tres`.

The **Furniture Creator** editor plugin (`addons/furniture_creator/`) provides a visual panel inside the Godot editor for creating and editing these resources without manually editing `.tres` files. Enable it in **Project > Project Settings > Plugins**.

## Pet Interactions & Animations

### State Machine

The pet uses a finite state machine with seven states:

```
enum PetState { IDLE, WALKING, FALLING, DRAGGED, INTERACTING, JUMP_PREP, JUMPING }
```

**State transitions:**

- **IDLE** → WALKING (idle timer expires, random walk target chosen)
- **WALKING** → IDLE (reached target)
- **WALKING** → FALLING (walked off furniture edge)
- **WALKING** → INTERACTING (overlapped interactive furniture)
- **WALKING** → JUMP_PREP (near jumpable furniture, random chance)
- **IDLE** → DRAGGED (player clicks and drags the pet)
- **DRAGGED** → FALLING (mouse released)
- **FALLING** → IDLE (landed on floor or furniture)
- **JUMP_PREP** → JUMPING (prep animation finished)
- **JUMPING** → IDLE (landed on target)
- **INTERACTING** → IDLE (interaction timer elapsed)

### Animation Names

Each state plays a corresponding animation from the pet's SpriteFrames resource:

| State | Animation | Notes |
|-------|-----------|-------|
| IDLE | `idle` | Looping |
| WALKING | `walk` | Looping, sprite flips horizontally |
| FALLING | `fall` | Non-looping |
| DRAGGED | `dragged` | Falls back to `idle` if missing |
| INTERACTING | `interact` | Falls back to `idle` if missing |
| JUMP_PREP | `jump_prep` | Non-looping |
| JUMPING | `jump` / `fall` | Switches based on vertical velocity |

### Furniture Interactions

When the pet walks into furniture that has a non-empty `interaction_type`, the interaction system triggers:

1. Pet checks `furniture.can_interact()` (enforces cooldown)
2. If allowed, pet enters INTERACTING state and plays the `interact` animation
3. `interaction_coin_bonus` coins are awarded immediately
4. Interaction plays for a duration based on type:
   - `"sleep"`: 2–3 seconds, shows "Zzz" label
   - `"eat"`: 0.3 seconds with bounce animation
   - `"play"`: 0.3 seconds with bounce animation
5. After the timer, pet returns to IDLE
6. The furniture's cooldown timer starts (`interaction_cooldown` seconds)

### Mood System

The pet has three mood states based on coin balance:

```
enum PetMood { SAD, NEUTRAL, HAPPY }
```

- **Sad**: coins < 10
- **Neutral**: coins >= 10 and < 50
- **Happy**: coins >= 50

The mood is displayed in a speech bubble above the pet with a colored circle icon and text label. Developers can assign custom mood textures via the `sad_texture`, `neutral_texture`, and `happy_texture` exported properties on the pet node.

## Creating New Pets

### SpriteFrames Resource

Each pet is a SpriteFrames `.tres` resource in `pet/data/`. The pet selection panel auto-discovers all `.tres` files in this directory that load as SpriteFrames.

### Required Animations

The following animation names should be defined in the SpriteFrames resource:

| Animation | Required | Description |
|-----------|----------|-------------|
| `idle` | Yes | Default resting animation |
| `walk` | Yes | Horizontal movement |
| `jump_prep` | Recommended | Crouch before jumping |
| `jump` | Recommended | Upward jump phase |
| `fall` | Recommended | Falling/descending |
| `interact` | Optional | Playing with furniture (falls back to `idle`) |
| `dragged` | Optional | Being dragged by player (falls back to `idle`) |

Missing optional animations gracefully fall back to `idle`.

### Adding a New Pet

1. Create a sprite sheet with frames for each animation
2. Create a SpriteFrames resource in `pet/data/<petname>.tres`
3. Add animations with the names listed above
4. The pet will automatically appear in the pet selection panel — no code changes needed

The pet selection panel uses the first frame of the `idle` animation as the thumbnail.

## Save Data

Game state is persisted to `user://save_data.json` with the following structure:

```json
{
  "coins": 42,
  "pet_mood": 1,
  "furniture_positions": {
    "sofa": { "x": 200.0, "y": 500.0 },
    "toy": { "x": 400.0, "y": 500.0 }
  },
  "inventory": {
    "food_bowl": 2
  },
  "language": "en",
  "monitor": 0,
  "selected_pet": "ozzy",
  "has_seen_menu_hint": true
}
```

| Field | Type | Description |
|-------|------|-------------|
| `coins` | int | Current coin balance |
| `pet_mood` | int | Mood enum value (0 = Sad, 1 = Neutral, 2 = Happy) |
| `furniture_positions` | dict | Map of furniture ID → screen position for placed items |
| `inventory` | dict | Map of furniture ID → quantity for unplaced items |
| `language` | String | Locale code (`"en"`, `"pt"`) |
| `monitor` | int | Monitor index (0-based) |
| `selected_pet` | String | Pet name matching the `.tres` filename (e.g. `"ozzy"`) |
| `has_seen_menu_hint` | bool | Whether the menu hint arrow has been dismissed |

## GlobalInput Extension

GlobalInput is a C++ GDExtension that captures system-wide keyboard and mouse input even when the Godot window is not focused. This powers the coin economy — the pet rewards you for staying active at your computer.

For full documentation on building, API reference, and platform notes, see [addons/global_input/README.md](addons/global_input/README.md).
