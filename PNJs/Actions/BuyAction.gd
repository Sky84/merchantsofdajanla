extends Action
class_name BuyAction

var navigation_agent: NavigationAgent3D;

func execute(params: Dictionary) -> void:
	var owner_id_by_subtype = ContainersController.get_owner_id_by_subtype(target);
	navigation_agent = params.navigation_agent;
	var trader: Alive = AlivesController.get_alive_by_owner_id(owner_id_by_subtype);
	var target_position: Vector3 = trader.global_position;
	navigation_agent.target_position = target_position;
	await navigation_agent.target_reached;
	on_action_finished.emit(id);
