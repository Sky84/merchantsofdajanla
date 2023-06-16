extends Action
class_name WaitAction

var navigation_agent: NavigationAgent3D;

func execute(params: Dictionary) -> void:
	var _owner_id = params._owner_id;
	navigation_agent = params.navigation_agent;
	_update_target_position(params.global_position, params.grid_map);
	await navigation_agent.target_reached;
	var timer: SceneTreeTimer = params.grid_map.get_tree().create_timer(1);
	await timer.timeout;
	on_action_finished.emit(id, _owner_id, null);

func _update_target_position(start_position: Vector3, gridmap_controller: GridMapController):
	var target_position: Vector3 = NodeUtils.get_random_reachable_point(start_position, gridmap_controller);
	navigation_agent.target_position = target_position;

