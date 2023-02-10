extends CharacterBody3D

@export var speed_walk: float = 1.0;
@export var speed_run_factor: float = 2.0;
@export var run_animation_gap = 3;
@export var camera: Camera3D;
@onready var animation_tree = $AnimationTree;
@onready var cloth_animations = $ClothAnimations;
@onready var animated_sprite_3d = $ClothAnimations/SkinsAnimatedSprite3D;

var _is_blocked = false;
var _speed_walk_factor: float = 10.0;
var _is_inventory_visible = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	animation_tree.active = true;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
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
	if _is_blocked:
		speed = 0;
	velocity = Vector3(direction_x, 0, direction_z).normalized() * speed;

func _handle_animation():
	if velocity.x != 0:
		animated_sprite_3d.scale.x = 1 if velocity.x > 0 else -1;
	var state = get_state();
	animation_tree.set("parameters/conditions/isAttacking", state.is_attacking);
	animation_tree.set("parameters/conditions/isIdle", state.is_idle);
	animation_tree.set("parameters/conditions/isWalking", state.is_walking);
	animation_tree.set("parameters/conditions/isRunning", state.is_running);

func get_state() -> Dictionary:
	return {
		"is_idle": velocity == Vector3.ZERO,
		"is_walking": velocity != Vector3.ZERO and velocity.length() <= run_animation_gap,
		"is_running": velocity != Vector3.ZERO and velocity.length() > run_animation_gap,
		"is_attacking": Input.get_action_strength("attack") && 
	};

#set by animation in AnimationPlayer
func _on_animation_set_block(value: bool):
	_is_blocked = value;
