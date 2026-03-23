extends Node

## Inventory system that tracks furniture items by ID and quantity.
## Emits signals when inventory changes for UI binding.
## Persisted via main.gd save/load system.

signal inventory_changed(furniture_id: String, new_count: int)

# Dictionary mapping furniture_id -> quantity
var _inventory: Dictionary = {}


func add_to_inventory(furniture_id: String, quantity: int = 1) -> void:
	if quantity <= 0:
		return
	if _inventory.has(furniture_id):
		_inventory[furniture_id] += quantity
	else:
		_inventory[furniture_id] = quantity
	inventory_changed.emit(furniture_id, _inventory[furniture_id])


func remove_from_inventory(furniture_id: String, quantity: int = 1) -> bool:
	## Removes quantity from inventory. Returns true if successful, false if insufficient.
	if quantity <= 0:
		return false
	if not _inventory.has(furniture_id) or _inventory[furniture_id] < quantity:
		return false
	_inventory[furniture_id] -= quantity
	if _inventory[furniture_id] <= 0:
		_inventory.erase(furniture_id)
	inventory_changed.emit(furniture_id, get_inventory_count(furniture_id))
	return true


func get_inventory_count(furniture_id: String) -> int:
	if _inventory.has(furniture_id):
		return _inventory[furniture_id]
	return 0


func get_all_inventory() -> Dictionary:
	## Returns a copy of the full inventory dictionary.
	return _inventory.duplicate()


func set_inventory(data: Dictionary) -> void:
	## Replaces inventory with loaded data. Used by main.gd on load.
	_inventory = data.duplicate()


func get_inventory_for_save() -> Dictionary:
	## Returns inventory data formatted for saving to JSON.
	return _inventory.duplicate()
