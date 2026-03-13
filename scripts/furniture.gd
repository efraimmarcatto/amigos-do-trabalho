class_name Furniture
extends Node2D

## Runtime furniture node that displays a furniture piece and handles pet interaction.
## Instantiated from scenes/furniture.tscn with a FurnitureData resource.

signal pet_interacted(furniture: Furniture)

@export var data: FurnitureData

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D


func _ready() -> void:
	if data and data.texture:
		sprite.texture = data.texture
		# Size the collision shape to match the texture
		var tex_size := data.texture.get_size()
		var shape := RectangleShape2D.new()
		shape.size = tex_size
		collision_shape.shape = shape


## Returns the global Y coordinate of the walkable surface (top of sprite + offset).
func get_surface_y() -> float:
	if not data or not data.texture:
		return global_position.y
	var half_h := data.texture.get_size().y / 2.0
	return global_position.y - half_h + data.walk_surface_y_offset


## Returns the global X coordinate of the left edge of the furniture.
func get_left_x() -> float:
	if not data or not data.texture:
		return global_position.x
	return global_position.x - data.texture.get_size().x / 2.0


## Returns the global X coordinate of the right edge of the furniture.
func get_right_x() -> float:
	if not data or not data.texture:
		return global_position.x
	return global_position.x + data.texture.get_size().x / 2.0
