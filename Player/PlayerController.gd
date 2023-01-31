extends CharacterBody3D

@export var speed_walk: float = 1.0;
@export var speed_run_factor: float = 2.0;
@export var run_animation_gap = 3;
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
	var speed_run = max(1, Input.get_action_strength("run") * speed_run_factor);
	var speed = (speed_walk / _speed_walk_factor) * speed_run;
	velocity = Vector3(direction_x*speed, 0, direction_z*speed).normalized() * speed;

func _handle_animation():
	cloth_animations.rotation.x = camera.rotation.x;
	if velocity.x != 0:
		animated_sprite_3d.scale.x = 1 if velocity.x > 0 else -1;
	var is_idle = velocity == Vector3.ZERO;
	var is_walking = velocity != Vector3.ZERO and velocity.length() <= run_animation_gap;
	var is_running = velocity != Vector3.ZERO and velocity.length() > run_animation_gap;
	animation_tree.set("parameters/conditions/isIdle", is_idle);
	animation_tree.set("parameters/conditions/isWalking", is_walking);
	animation_tree.set("parameters/conditions/isRunning", is_running);
