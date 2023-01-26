extends CharacterBody2D

@export var speed_walk = 100;
@onready var animation_tree = $AnimationTree;
@onready var animated_sprite_2d = $ClothAnimations/SkinsAnimatedSprite2D


var _is_inventory_visible = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	animation_tree.active = true;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_handle_animation();
	move_and_slide();

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
	if velocity.x != 0:
		animated_sprite_2d.scale.x = 1 if velocity.x > 0 else -1;
	animation_tree.set("parameters/conditions/isWalking", velocity != Vector2.ZERO);
	animation_tree.set("parameters/conditions/isIdle", velocity == Vector2.ZERO);
