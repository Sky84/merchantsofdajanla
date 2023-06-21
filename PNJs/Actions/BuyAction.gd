extends Action
class_name BuyAction

var navigation_agent: NavigationAgent3D;
var scene_tree: SceneTree;
var camera_3d: Camera3D;
var pnj_name: String;
var is_running: bool;
var grid_map: GridMapController;
var buyer_owner_id: String;
var seller_container_config: Dictionary;

func execute(params: Dictionary) -> void:
	is_running = true;
	buyer_owner_id = params._owner_id;
	grid_map = params.grid_map;
	navigation_agent = params.navigation_agent;
	scene_tree = navigation_agent.get_tree();
	camera_3d = params.camera_3d;
	pnj_name = params.pnj_name;
	seller_container_config = MarketController.get_seller_container_config_by_subtype(target);
	if seller_container_config.is_empty():
		_end_action();
		return;

	#seller can be Alive or Stand
	var seller = grid_map.get_map_item(seller_container_config.container_id);
	if not seller:
		seller = AlivesController.get_alive_by_owner_id(seller_container_config.container_owner);
	_start_update_alive_target_position(seller);
	var target_position: Vector3 = seller.global_position;
	navigation_agent.target_position = target_position;
	await navigation_agent.target_reached;
	_on_target_reached();

func _start_update_alive_target_position(seller: Node3D):
	var target_position: Vector3 = seller.global_position;
	navigation_agent.target_position = target_position;
	await scene_tree.create_timer(1).timeout;
	if is_running:
		seller_container_config = MarketController.get_seller_container_config_by_subtype(target);
		if seller_container_config.is_empty():
			_end_action();
			return;
		var new_seller = grid_map.get_map_item(seller_container_config.container_id);
		if not new_seller:
			new_seller = AlivesController.get_alive_by_owner_id(seller_container_config.container_owner);
		_start_update_alive_target_position(new_seller);

func _end_action():
	var next_action = Actions.get_action_by_id(Actions.WAIT);
	is_running = false;
	on_action_finished.emit(id, buyer_owner_id, next_action);

func _on_target_reached():
	if not is_running:
		return;
	var item = GameItems.get_items_by_subtype(target)[0];
	var should_trade: bool = true;
	if seller_container_config.container_owner == "player":
		should_trade = await _process_target_player(navigation_agent, item);
	if should_trade:
		print(buyer_owner_id, " is buying things of ",seller_container_config.container_owner);
		MarketController.trade(seller_container_config.container_id, item.id, 1, seller_container_config.container_owner,\
							buyer_owner_id);
		InventoryEvents.container_data_changed.emit(seller_container_config.container_id);
	_end_action();

func _process_target_player(navigation_agent, item) -> bool:
	var target_position = navigation_agent.target_position;
	PlayerEvents.on_player_block.emit(true);
	var nav_path = navigation_agent.get_current_navigation_path();
	nav_path.reverse();
	var nav_position = navigation_agent.target_position;
	if nav_path.size():
		nav_position = nav_path[2] if nav_path.size() > 2 else nav_path[0]
	var gap_modal = Vector2(-170, 0) if nav_position.x - target_position.x < 0\
		else Vector2(170, 0);
	var modal_params = {
		'global_position':  camera_3d.unproject_position(target_position) + gap_modal,
		'modal_on_left': gap_modal.x < 0,
		'ask_translation': tr('MARKET.ASK_BUY') + " 1 " + tr(item.name),
		'name_translation': pnj_name
	};
	HudEvents.open_modal.emit('res://Dialogs/AskBuyDialog/AskBuyDialog.tscn', modal_params);
	var modal_result = await HudEvents.closed_modal;
	PlayerEvents.on_player_block.emit(false);
	if modal_result:
		NotificationEvents.notify.emit(NotificationEvents.NotificationType.SUCCESS, 'MARKET.TRADE_SUCCESS');
	return modal_result;
