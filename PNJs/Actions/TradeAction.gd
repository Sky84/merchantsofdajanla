extends Action
class_name TradeAction

var astar_agent: AStarAgent;

func execute(params: Dictionary) -> void:
	astar_agent = params.astar_agent;
	var _owner_id = params._owner_id;
	var seller = AlivesController.get_alive_by_owner_id(_owner_id);
	var shop_position = params.shop_position;
	astar_agent.target_position = shop_position;
	await astar_agent.target_reached;
	seller.is_trading = true;
	var timer: SceneTreeTimer = params.grid_map.get_tree().create_timer(1);
	await timer.timeout;
	seller.is_trading = false;
	on_action_finished.emit(id, _owner_id, null);
