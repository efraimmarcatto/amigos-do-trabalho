class_name FurnitureData
extends Resource

## Data resource defining a piece of furniture's properties.

## Unique identifier for this furniture type
@export var id: String = ""
## Name shown in the shop UI
@export var display_name: String = ""
## Sprite texture for this furniture
@export var texture: Texture2D
## Cost in coins to purchase
@export var coin_cost: int = 0
## Whether the pet can walk on top of this furniture
@export var walkable: bool = false
## Y offset from sprite top for the walkable surface
@export var walk_surface_y_offset: int = 0
## Whether the pet can fall off the edges of this furniture
@export var can_fall_off_edge: bool = true
## Whether the pet can jump onto this furniture from the floor
@export var jumpable: bool = false
## Type of interaction the pet performs (empty string = no interaction)
@export var interaction_type: String = ""
## Bonus coins awarded when the pet interacts
@export var interaction_coin_bonus: int = 0
## Seconds between allowed interactions
@export var interaction_cooldown: float = 0.0
