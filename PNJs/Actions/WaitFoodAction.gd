extends Action
class_name WaitFoodAction

var navigation_agent: NavigationAgent3D;

func execute(params: Dictionary) -> void:
	navigation_agent = params.navigation_agent;
	
#	_update_target_position(params.global_position, params.grid_map);
	var target_position: Vector3 = NodeUtils.get_random_reachable_point(params.global_position, params.grid_map);
	navigation_agent.target_position = target_position;
	await navigation_agent.target_reached;
	var timer: SceneTreeTimer = params.grid_map.get_tree().create_timer(1);
	await timer.timeout;
	var next_action: Action = null;
	if target == 'Food':
		next_action = Actions.get_action_by_id(Actions.BUY);
	on_action_finished.emit(id, next_action);

#func _update_target_position(start_position: Vector3, gridmap_controller: GridMapController):
#	var target_position: Vector3 = NodeUtils.get_random_reachable_point(start_position, gridmap_controller);
#	print(start_position);
#	print(target_position);
#	navigation_agent.target_position = target_position;

