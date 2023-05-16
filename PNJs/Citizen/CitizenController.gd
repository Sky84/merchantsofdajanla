extends Alive

@export var navigation_agent: NavigationAgent3D;

var actions_queue = [];
var is_running_int = 0;

func _ready() -> void:
	super();
	_alive_status.hunger.value = 0;
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
		var action_id = Actions.get_action_id_by_triggers(_alive_status);
		if !action_id.is_empty():
			actions_queue.push_back(action_id);
			_process_actions_queue();

func _process_action(action_id: String) -> void:
	var action: Action = Actions.get_action_by_id(action_id);
	actions_queue.pop_back();
	var params = {};
	
	if action is EatAction:
		params = {
			'_owner_id': _owner_id,
			'consume_callback': consume,
			'fallback_callback': _add_fallback_to_action
		};
	elif action is BuyAction:
		params = {
			'owner_id': _owner_id,
			'navigation_agent': navigation_agent
		};
	elif action is WaitAction:
		params = {
			'start_position': global_position,
			'navigation_agent': navigation_agent
		};
	if !action.on_action_finished.is_connected(_on_action_finished):
		action.on_action_finished.connect(_on_action_finished);
	action.execute(params);

func _on_action_finished(action_id: String, next_action: Action):
	if next_action:
		actions_queue.push_back(next_action.id);
	_process_actions_queue();

func _add_fallback_to_action(action: Action) -> void:
	actions_queue.push_back(action.id);
