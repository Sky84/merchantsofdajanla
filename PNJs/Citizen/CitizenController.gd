extends Alive

var actions_queue = [];

func _ready() -> void:
	super();
	_alive_status.hunger.value = 0;
	_process_actions_queue();

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
	var action = Actions.get_action_by_id(action_id);
	match action.id:
		Actions.EAT:
			actions_queue.pop_back();
			Actions.try_eat(action, _owner_id, consume, _add_fallback_to_action);
		_:
			printerr('_process_action: No action for action_id:'+action_id);
			return;
	
	_process_actions_queue();

func _add_fallback_to_action(action: Dictionary) -> void:
	actions_queue.push_back(action.id);
