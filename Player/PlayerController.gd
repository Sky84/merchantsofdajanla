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
var _current_mouse_target: Control;

var _detected_posables = {};
var _closest_posable: Posable = null;

# Called when the node enters the scene tree for the first time.
func _ready():
	animation_tree.active = true;
	HudEvents.on_mouse_current_target.connect(_on_mouse_current_target_changed);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	_handle_movement();
	_handle_animation();
	move_and_slide();
	_update_closest_posable();

func _input(event):
	if event is InputEventKey:
		if event.is_action_released("TAB"):
			_is_inventory_visible = !_is_inventory_visible;
			InventoryEvents.visibility_inventory.emit(_is_inventory_visible);

func _on_mouse_current_target_changed(target: Control):
	_current_mouse_target = target;

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
		"is_attacking": Input.get_action_strength("attack") and _current_mouse_target == null
	};

#set by animation in AnimationPlayer
func _on_animation_set_block(value: bool):
	_is_blocked = value;

func _distance_to_obj(body: Node3D) -> float:
	return global_position.distance_to(body.get_global_position());

func _update_closest_posable() -> void:
	var closest_changed = false;
	if _detected_posables.is_empty() and _closest_posable:
		_closest_posable = null;
		closest_changed = true;
	for key in _detected_posables:
		var posable = _detected_posables[key];
		if not _closest_posable:
			_closest_posable = posable;
			closest_changed = true;
		elif _closest_posable == posable:
			continue;
		elif _distance_to_obj(posable) < _distance_to_obj(_closest_posable):
			_closest_posable = posable;
			closest_changed = true;
	if closest_changed:
		PlayerEvents._new_closest_posable.emit(_closest_posable);

func _on_object_detector_body_entered(body: Node3D):
	if body is Posable:
		_detected_posables[body.name] = body;


func _on_object_detector_body_exited(body: Node3D):
	if body is Posable and _detected_posables.has(body.name):
		_detected_posables.erase(body.name);
