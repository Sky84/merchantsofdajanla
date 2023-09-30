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
@export var pnj_name: String = 'George';

@onready var camera_3d = get_node('/root/Root/Game/Camera3D');
@onready var grid_map: GridMapController = get_node('/root/Root/Game/NavigationRegion3D/GridMap');
@onready var default_action_id: String = Actions.WAIT;

var actions_queue = [];
var is_running_int = 0;

var _inactive: bool = false;

func _ready() -> void:
	if inactive:
		return;
	super();
	alive_status.hunger.value = 0;
	_check_actions();

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

func _check_actions() -> void:
	var action_id = await Actions.get_action_id_by_triggers(_owner_id);
	var action = await Actions.get_action_by_id(action_id);
	if action_id and actions_queue.all(func(action_from_queue): return action_from_queue.id!=action.id):
		actions_queue.push_back(action);
	_process_actions_queue();

func _process_actions_queue() -> void:
	var default_action = await Actions.get_action_by_id(default_action_id);
	var current_action = actions_queue.pop_front() if !actions_queue.is_empty() else default_action;
	if !current_action.on_action_finished.is_connected(_on_action_finished):
		current_action.on_action_finished.connect(_on_action_finished);
	current_action.execute(_get_action_params(current_action));

func _get_action_params(action: Action) -> Dictionary:
	var params_to_modify = {};
	for param_key in action.params:
		params_to_modify[param_key] = self[param_key];
	return params_to_modify;

func _on_action_finished(action_id: String, owner_id: String, next_action: Action):
	if owner_id != _owner_id:
		return;
	if next_action:
		actions_queue.push_front(next_action);
	_check_actions();
