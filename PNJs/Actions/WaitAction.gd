extends Action
class_name WaitAction

var navigation_agent: NavigationAgent3D;

func execute(params: Dictionary) -> void:
	navigation_agent = params.navigation_agent;
	
	_update_target_position(params.start_position);
	if navigation_agent.is_target_reachable():
		await navigation_agent.target_reached;
	
	var next_action: Action = null;
	if target == 'Food':
		next_action = Actions.get_action_by_id(Actions.BUY);
	on_action_finished.emit(id, next_action);

func _update_target_position(start_position: Vector3):
	var target_position: Vector3 = start_position + Vector3(randf_range(1, 2), 0, randf_range(1, 2));
	navigation_agent.target_position = target_position;

