extends Action
class_name TradeAction

var navigation_agent: NavigationAgent3D;

func execute(params: Dictionary) -> void:
	var navigation_agent = params.navigation_agent;
	var _owner_id = params._owner_id;
	var seller = AlivesController.get_alive_by_owner_id(_owner_id);
	var shop_position = params.shop_position;
	navigation_agent.target_position = shop_position;
	await navigation_agent.target_reached;
	seller.is_trading = true;	
	var timer: SceneTreeTimer = params.grid_map.get_tree().create_timer(1);
	await timer.timeout;
	seller.is_trading = false;
	on_action_finished.emit(id, _owner_id, null);
