class_name Furniture
extends Node2D

## Runtime furniture node that displays a furniture piece and handles pet interaction.
## Instantiated from scenes/furniture.tscn with a FurnitureData resource.

signal pet_interacted(furniture: Furniture)

@export var data: FurnitureData

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

# Cooldown tracking (resets on app restart — not persisted)
var _last_interaction_time: float = -9999.0


func _ready() -> void:
	# Disable input picking — Area2D is only used for pet collision detection, not mouse input.
	# Leaving it enabled causes viewport physics picking to consume clicks when pet overlaps furniture.
	area.input_pickable = false
	if data and data.texture:
		sprite.texture = data.texture
		# Apply display scale to the sprite
		sprite.scale = data.display_scale
		# Size the collision shape — use override if set, otherwise auto-calculate from texture
		var shape := RectangleShape2D.new()
		if data.collision_size_override != Vector2.ZERO:
			shape.size = data.collision_size_override
		else:
			shape.size = data.texture.get_size() * data.display_scale
		collision_shape.shape = shape
		collision_shape.position = data.collision_offset


## Returns true if interaction is available (has interaction_type and cooldown elapsed).
func can_interact() -> bool:
	if not data or data.interaction_type == "":
		return false
	var elapsed := Time.get_ticks_msec() / 1000.0 - _last_interaction_time
	return elapsed >= data.interaction_cooldown


## Marks the furniture as just interacted (starts cooldown).
func mark_interacted() -> void:
	_last_interaction_time = Time.get_ticks_msec() / 1000.0
	pet_interacted.emit(self)


## Returns the global Y coordinate of the walkable surface (top of sprite + offset).
func get_surface_y() -> float:
	if not data or not data.texture:
		return global_position.y
	if data.standing_size_override != Vector2.ZERO:
		return global_position.y - data.standing_size_override.y / 2.0 + data.standing_offset.y + data.walk_surface_y_offset
	var half_h := data.texture.get_size().y * data.display_scale.y / 2.0
	return global_position.y - half_h + data.walk_surface_y_offset


## Returns the global X coordinate of the left edge of the furniture.
func get_left_x() -> float:
	if not data or not data.texture:
		return global_position.x
	if data.standing_size_override != Vector2.ZERO:
		return global_position.x - data.standing_size_override.x / 2.0 + data.standing_offset.x
	return global_position.x - data.texture.get_size().x * data.display_scale.x / 2.0


## Returns the global X coordinate of the right edge of the furniture.
func get_right_x() -> float:
	if not data or not data.texture:
		return global_position.x
	if data.standing_size_override != Vector2.ZERO:
		return global_position.x + data.standing_size_override.x / 2.0 + data.standing_offset.x
	return global_position.x + data.texture.get_size().x * data.display_scale.x / 2.0
