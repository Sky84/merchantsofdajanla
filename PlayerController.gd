extends Node2D

var _is_inventory_visible = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event is InputEventKey:
		if event.is_action_released("TAB"):
			_is_inventory_visible = !_is_inventory_visible;
			InventoryEvents.visibility_inventory.emit(_is_inventory_visible);
