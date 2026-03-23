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
