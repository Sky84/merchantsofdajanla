extends CharacterBody3D

@export var speed_walk: float = 1.0;
@export var camera: Camera3D;
@onready var animation_tree = $AnimationTree;
@onready var cloth_animations = $ClothAnimations;
@onready var animated_sprite_3d = $ClothAnimations/SkinsAnimatedSprite3D;


var _speed_walk_factor: float = 10.0;
var _is_inventory_visible = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	animation_tree.active = true;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_handle_movement();
	_handle_animation();
	move_and_slide();

func _input(event):
	if event is InputEventKey:
		if event.is_action_released("TAB"):
			_is_inventory_visible = !_is_inventory_visible;
			InventoryEvents.visibility_inventory.emit(_is_inventory_visible);

func _handle_movement():
	var direction_x = Input.get_action_strength("right") - Input.get_action_strength("left");
	var direction_z = Input.get_action_strength("down") - Input.get_action_strength("up");
	var speed = speed_walk / _speed_walk_factor;
	velocity = Vector3(direction_x*speed, 0, direction_z*speed);

func _handle_animation():
	cloth_animations.rotation.x = camera.rotation.x;
	if velocity.x != 0:
		animated_sprite_3d.scale.x = 1 if velocity.x > 0 else -1;
	animation_tree.set("parameters/conditions/isWalking", velocity != Vector3.ZERO);
	animation_tree.set("parameters/conditions/isIdle", velocity == Vector3.ZERO);
