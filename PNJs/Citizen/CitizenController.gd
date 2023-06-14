extends Alive
class_name CitizenController

@export_category("Debug")
@export var inactive: bool = false :
	get:
		return _inactive;
	set(value):
		_inactive = value;
		if not _inactive:
			_ready();

@export_category("Citizen")
@export var navigation_agent: NavigationAgent3D;
@onready var camera_3d = %Camera3D;

@onready var grid_map: GridMapController = $"../NavigationRegion3D/GridMap";

var pnj_name: String = 'George';
var actions_queue = [];
var is_running_int = 0;

var _inactive: bool = false;

func _ready() -> void:
	if inactive:
		return;
	super();
	_alive_status.hunger.value = 100;
	_process_actions_queue();

func _handle_movement():
	# Obtenir la prochaine position sur le chemin de navigation
	var next_position = navigation_agent.get_next_path_position();
	var direction = next_position - global_position;
	var distance_to_target = navigation_agent.distance_to_target();
	
	var speed_run = max(1, is_running_int * speed_run_factor);
	var speed = (speed_walk / _speed_walk_factor) * speed_run;
	if _is_blocked or distance_to_target <= navigation_agent.target_desired_distance:
		speed = 0;
	velocity = Vector3(direction.x, 0, direction.z).normalized() * speed;

func _process_actions_queue() -> void:
	var current_action_id = actions_queue.back() if !actions_queue.is_empty() else null;
	if current_action_id:
		_process_action(current_action_id);
	else:
		var action_id = Actions.get_action_id_by_triggers(_owner_id);
		if !action_id.is_empty():
			actions_queue.push_back(action_id);
			_process_actions_queue();

func _init_params_action(params_to_modify: Dictionary, action: Action) -> Dictionary:
	if action is EatAction:
		params_to_modify = {
			'_owner_id': _owner_id,
			'consume_callback': consume,
			'fallback_callback': _add_fallback_to_action
		};
	elif action is BuyAction:
		params_to_modify = {
			'owner_id': _owner_id,
			'navigation_agent': navigation_agent,
			'grid_map': grid_map,
			'camera_3d': camera_3d,
			'pnj_name': pnj_name
		};
	elif action is WaitFoodAction or action is WaitAction:
		params_to_modify = {
			'start_position': global_position,
			'navigation_agent': navigation_agent,
			'gridmap_controller': grid_map
		};
	return params_to_modify;

func _process_action(action_id: String) -> void:
	var params = {};
	var action: Action = Actions.get_action_by_id(action_id);
	actions_queue.pop_back();
	params = _init_params_action(params, action);
	if !action.on_action_finished.is_connected(_on_action_finished):
		action.on_action_finished.connect(_on_action_finished);
	action.execute(params);

func _on_action_finished(action_id: String, next_action: Action):
	if next_action:
		actions_queue.push_back(next_action.id);
	_process_actions_queue();

func _add_fallback_to_action(action: Action) -> void:
	actions_queue.push_back(action.id);
