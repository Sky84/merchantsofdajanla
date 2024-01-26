extends Action
class_name WaitAction

var astar_agent: AStarAgent;

func execute(params: Dictionary) -> void:
	var _owner_id = params._owner_id;
	astar_agent = params.astar_agent;
	_update_target_position(params.global_position, params.grid_map);
	await astar_agent.target_reached;
	var timer: SceneTreeTimer = params.grid_map.get_tree().create_timer(1);
	await timer.timeout;
	on_action_finished.emit(id, _owner_id, null);

func _update_target_position(start_position: Vector3, gridmap_controller: GameGridMapController):
	var space_state: PhysicsDirectSpaceState3D = gridmap_controller.get_world_3d().direct_space_state;
	var target_position: Vector3 = NodeUtils.get_random_reachable_point(start_position, gridmap_controller, space_state);
	astar_agent.target_position = target_position;

