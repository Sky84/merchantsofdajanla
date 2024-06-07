extends Action
class_name BuyAction

var astar_agent: AStarAgent;
var scene_tree: SceneTree;
var camera_3d: Camera3D;
var pnj_name: String;
var is_running: bool;
var grid_map: GameGridMapController;
var buyer_owner_id: String;
var seller_container_config: Dictionary;
var seller_alive: Alive;
const DIALOG_TITLE := 'buy-action-modal';

var _target_is_door := false;

func execute(_params: Dictionary) -> void:
	is_running = true;
	buyer_owner_id = _params._owner_id;
	grid_map = _params.grid_map;
	astar_agent = _params.astar_agent;
	scene_tree = astar_agent.get_tree();
	camera_3d = _params.camera_3d;
	pnj_name = _params.pnj_name;
	seller_container_config = MarketController.get_seller_container_config_by_subtype(target);
	if seller_container_config.is_empty():
		_end_action();
		return;

	#seller can be Alive or Stand
	var seller = grid_map.get_map_item(seller_container_config.container_id);
	seller_alive = AlivesController.get_alive_by_owner_id(seller_container_config.container_owner);
	if not seller:
		seller = seller_alive;
	_start_update_alive_target_position(seller);
	if _target_is_door:
		await astar_agent.target_reached;
		seller._nearest_interactive.interact(buyer_owner_id);
		_update_target_target_position(seller);
	await astar_agent.target_reached;
	if seller_alive.is_busy:
		_end_action(false);
	else:
		_on_target_reached();

func _start_update_alive_target_position(seller: Node3D):
	_update_target_target_position(seller);
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

func _update_target_target_position(seller: Node3D):
	var buyer = AlivesController.get_alive_by_owner_id(buyer_owner_id);
	var target_position: Vector3 = seller.global_position;
	if 'current_interrior' in seller and seller.current_interrior != buyer.current_interrior:
		target_position = seller.current_interrior.door_instance.global_position;
		_target_is_door = true;
	else:
		_target_is_door = false;
	astar_agent.target_position = target_position;

func _end_action(unlock_player: bool = true):
	var next_action = await Actions.get_action_by_id(Actions.WAIT);
	is_running = false;
	on_action_finished.emit(id, buyer_owner_id, next_action);
	if unlock_player:
		PlayerEvents.on_player_block.emit(false);

func _on_target_reached():
	if not is_running:
		return;
	var item = GameItems.get_items_by_subtype(target)[0];
	seller_alive.is_busy = true;
	if "player" in seller_container_config.container_owner.to_lower():
		_process_target_player(item);
	else:
		_on_accept(item);

func _on_accept(item: Dictionary, notify: bool = false) -> void:
	if notify:
		NotificationEvents.notify.emit(NotificationEvents.NotificationType.SUCCESS, 'MARKET.TRADE_SUCCESS');
	print(buyer_owner_id, " is buying things of ",seller_container_config.container_owner);
	MarketController.trade(seller_container_config.container_id, item.id, 1, seller_container_config.container_owner,\
							buyer_owner_id);
	InventoryEvents.container_data_changed.emit(seller_container_config.container_id);
	seller_alive.is_busy = false;
	_end_action();

func _on_decline() -> void:
	seller_alive.is_busy = false;
	_end_action();

func _process_target_player(item) -> void:
	var target_position = astar_agent.target_position;
	PlayerEvents.on_player_block.emit(true);
	var nav_path = astar_agent.get_current_navigation_path();
	nav_path.reverse();
	var nav_position = astar_agent.target_position;
	if nav_path.size():
		nav_position = nav_path[2] if nav_path.size() > 2 else nav_path[0]
	var gap_modal = Vector2(-170, 0) if nav_position.x - target_position.x < 0\
		else Vector2(170, 0);
	var modal_params = {
		'id': DIALOG_TITLE,
		'global_position':  camera_3d.unproject_position(target_position) + gap_modal,
		'modal_on_left': gap_modal.x < 0,
		'ask_translation': tr('MARKET.ASK_BUY') + " 1 " + tr(item.name),
		'name_translation': pnj_name,
		'answers': [
			{'text':tr('MARKET.ACCEPT'), 'callback': _on_accept.bind(item, true)},
			{'text':tr('MARKET.DECLINE'), 'callback': _on_decline}
		]
	};
	HudEvents.open_modal.emit('res://UI/Modals/DialogModal/DialogModal.tscn', modal_params);
