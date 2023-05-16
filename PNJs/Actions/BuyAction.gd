extends Action
class_name BuyAction

var navigation_agent: NavigationAgent3D;

func execute(params: Dictionary) -> void:
	var buyer_owner_id = params.owner_id;
	navigation_agent = params.navigation_agent;
	var seller_container_config = ContainersController.get_container_config_by_subtype(target);
	if seller_container_config.is_empty():
		var next_action = Actions.get_action_by_id(Actions.WAIT);
		on_action_finished.emit(id, next_action);
		return;
	var item = GameItems.get_items_by_subtype(target)[0];
	var trader: Alive = AlivesController.get_alive_by_owner_id(seller_container_config.container_owner);
	var target_position: Vector3 = trader.global_position;
	navigation_agent.target_position = target_position;
	await navigation_agent.target_reached;
	MarketController.trade(seller_container_config.container_id, item.id, 1, seller_container_config.container_owner,\
							buyer_owner_id);
	InventoryEvents.container_data_changed.emit(seller_container_config.container_id);
	NotificationEvents.notify.emit(NotificationEvents.NotificationType.SUCCESS, 'MARKET.TRADE_SUCCESS');
	var next_action: Action = null;
	if target == 'Food':
		next_action = Actions.get_action_by_id(Actions.EAT);
	on_action_finished.emit(id, next_action);

