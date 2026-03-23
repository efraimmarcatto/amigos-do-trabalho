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
## Ratio of coin_cost refunded when discarding from inventory (0.0–1.0)
@export var discard_refund_ratio: float = 0.5
## Display scale applied to the sprite and collision shape
@export var display_scale: Vector2 = Vector2(1, 1)
## Whether this item can be placed on top of other walkable furniture
@export var stackable: bool = false
## Custom collision size — when non-zero, used instead of auto-calculated (texture * scale)
@export var collision_size_override: Vector2 = Vector2.ZERO
## Offset of the collision shape from sprite center
@export var collision_offset: Vector2 = Vector2.ZERO
## Custom standing area size — when non-zero, defines where the pet can walk/stand
@export var standing_size_override: Vector2 = Vector2.ZERO
## Offset of the standing area from sprite center
@export var standing_offset: Vector2 = Vector2.ZERO
