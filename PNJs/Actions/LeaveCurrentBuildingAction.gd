extends Action
class_name LeaveCurrentBuildingAction

var astar_agent: AStarAgent;

func execute(_params: Dictionary) -> void:
	var _owner_id = _params._owner_id;
	astar_agent = _params.astar_agent;
	
	var alive: Alive = AlivesController.get_alive_by_owner_id(_owner_id);
	if 'current_interior' in alive and alive.current_interior != null:
		var target_pos = Vector3(alive.current_interior.door_instance.global_position.x, alive.global_position.y, alive.current_interior.door_instance.global_position.z);
		astar_agent.target_position = target_pos;
		await astar_agent.target_reached;
		alive._nearest_interactive = alive.current_interior.door_instance;
		alive._nearest_interactive.interact(_owner_id);
		alive._nearest_interactive = null;
	on_action_finished.emit(id, _owner_id, null);
	

