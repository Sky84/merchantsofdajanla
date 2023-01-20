extends CharacterBody2D

@export var speed_walk = 100;
var _is_inventory_visible = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	move_and_slide();
	_handle_animation();

func _input(event):
	if event is InputEventKey:
		if event.is_action_released("TAB"):
			_is_inventory_visible = !_is_inventory_visible;
			InventoryEvents.visibility_inventory.emit(_is_inventory_visible);
		_handle_movement(event);

func _handle_movement(event: InputEventKey):
	var direction_x = event.get_action_strength("right") - event.get_action_strength("left");
	var direction_y = event.get_action_strength("down") - event.get_action_strength("up");
	velocity = Vector2(direction_x*speed_walk, direction_y*speed_walk);

func _handle_animation():
	pass
