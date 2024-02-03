extends CharacterBody3D
class_name Alive

const GROUP_NAME = 'alive';

@export var MAX_HEALTH: int = 100;
@export var MAX_HUNGER: int = 100;

@export var _owner_id: String;

@export var speed_walk: float = 30.0;
@export var speed_run_factor: float = 2.0;
@export var run_animation_gap = 3;

@onready var animation_tree = $AnimationTree;
@onready var cloth_animations = $ClothAnimations;
@onready var animated_sprite_3d = $ClothAnimations/SkinsAnimatedSprite3D;

signal on_set_owner_id;

var _is_player = false;

var _is_blocked = false;

var _speed_walk_factor: float = 10.0;

var _nearest_interactives = {};
var _nearest_interactive: Node3D = null;

var _item_in_hand: Dictionary = {};

var is_busy = false;
var alive_status: Dictionary = {
	"health": {"value": MAX_HEALTH, "max": MAX_HEALTH},
	"hunger": {"value": MAX_HUNGER, "max": MAX_HUNGER}
};

# equal to the house if the alive is in interior
var current_interior: Node3D = null;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group(GROUP_NAME);
	animation_tree.active = true;
	_update_owner_id();
	AliveEvents.on_alive_ready.emit(self);

func _update_owner_id():
	_owner_id = name+str(global_position.floor());
	on_set_owner_id.emit();

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	_handle_movement();
	_handle_animation();
	move_and_slide();
	_update_nearest_interactive();

func consume(_item: Dictionary, notify: bool = false) -> void:
	var success = false;
	for effect_key in _item.effects:
		if effect_key in alive_status:
			var _alive_stat = alive_status[effect_key];
			_alive_stat.value = clampi(_alive_stat.value + _item.effects[effect_key], 0, _alive_stat.max);
			success = true;
			if notify:
				NotificationEvents.notify\
					.emit(NotificationEvents.NotificationType.SUCCESS, 'CONSOMABLE.SUCCESS_CONSUME_'+effect_key.to_upper());
	if success:
		var container_ids = ContainersController.get_container_ids_by_owner_id(_owner_id);
		ContainersController.remove_item(container_ids, _item.id, 1);
		for container_id in container_ids:
			InventoryEvents.container_data_changed.emit(container_id);

func _handle_movement() -> void:
	pass;

func _handle_animation() -> void:
	if velocity.x != 0:
		animated_sprite_3d.scale.x = 1 if velocity.x > 0 else -1;
	var state = get_state();
	animation_tree.set("parameters/conditions/isIdle", state.is_idle);
	animation_tree.set("parameters/conditions/isWalking", state.is_walking);
	animation_tree.set("parameters/conditions/isRunning", state.is_running);

func get_state() -> Dictionary:
	return {
		"is_idle": velocity == Vector3.ZERO,
		"is_walking": velocity != Vector3.ZERO and velocity.length() <= run_animation_gap,
		"is_running": velocity != Vector3.ZERO and velocity.length() > run_animation_gap
	};

#set by animation in AnimationPlayer
func _on_animation_set_block(value: bool) -> void:
	_is_blocked = value;

func _distance_to_obj(body: Node3D) -> float:
	return global_position.distance_to(body.get_global_position());

func _update_nearest_interactive() -> void:
	var nearest_interactive_changed = false;
	if _nearest_interactives.is_empty() and _nearest_interactive:
		_nearest_interactive = null;
		nearest_interactive_changed = true;
	for key in _nearest_interactives:
		var interactive = _nearest_interactives[key];
		if not _nearest_interactive:
			_nearest_interactive = interactive;
			nearest_interactive_changed = true;
		elif _nearest_interactive == interactive:
			continue;
		elif _distance_to_obj(interactive) < _distance_to_obj(_nearest_interactive):
			_nearest_interactive = interactive;
			nearest_interactive_changed = true;
	if nearest_interactive_changed:
		PlayerEvents.on_nearest_interactive_changed.emit(_nearest_interactive);

func _on_item_in_hand_changed(item: Dictionary) -> void:
	if _item_in_hand.has('id') and item.has('id') and _item_in_hand.id == item.id:
		return;
	elif _item_in_hand == item: # We know item is obviously null
		return;
	_item_in_hand = item;

func _on_object_detector_body_entered(body: Node3D) -> void:
	if body.get_node_or_null(InteractComponent.SCENE_NAME):
		_nearest_interactives[body.name] = body;

func _on_object_detector_body_exited(body: Node3D) -> void:
	if body.get_node_or_null(InteractComponent.SCENE_NAME) and _nearest_interactives.has(body.name):
		_nearest_interactives.erase(body.name);
