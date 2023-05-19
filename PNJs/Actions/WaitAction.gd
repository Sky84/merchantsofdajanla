extends Action
class_name WaitAction

var navigation_agent: NavigationAgent3D;

func execute(params: Dictionary) -> void:
	navigation_agent = params.navigation_agent;
	
	_update_target_position(params.start_position, params.gridmap_controller);
	await navigation_agent.target_reached;
	
	var next_action: Action = null;
	if target == 'Food':
		next_action = Actions.get_action_by_id(Actions.BUY);
	on_action_finished.emit(id, next_action);

func _update_target_position(start_position: Vector3, gridmap_controller: GridMapController):
	var target_position: Vector3 = NodeUtils.get_random_reachable_point(navigation_mesh, navigation_agent, gridmap_controller);
	navigation_agent.target_position = target_position;

