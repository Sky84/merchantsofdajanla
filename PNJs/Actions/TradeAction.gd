extends Action
class_name TradeAction

var astar_agent: AStarAgent;

func execute(_params: Dictionary) -> void:
	astar_agent = _params.astar_agent;
	var _owner_id = _params._owner_id;
	var seller: Alive = AlivesController.get_alive_by_owner_id(_owner_id);
	var shop_position = _params.shop_position;
	seller.on_building_changed.connect(_handle_target_building_changed.bind(astar_agent))
	astar_agent.target_position = shop_position;
	await astar_agent.target_reached;
	seller.on_building_changed.disconnect(_handle_target_building_changed.bind(astar_agent))
	seller.is_trading = true;
	var timer: SceneTreeTimer = _params.grid_map.get_tree().create_timer(1);
	await timer.timeout;
	seller.is_trading = false;
	on_action_finished.emit(id, _owner_id, null);

func _handle_target_building_changed(astar_agent: AStarAgent, target: Node3D):
	print(astar_agent, target)
	#TODO assign door position to target, await target reached, assign target to seller
