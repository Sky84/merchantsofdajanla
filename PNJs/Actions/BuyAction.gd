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

signal on_enter_building;

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
		return ;

	#seller can be Alive or Stand
	var seller = grid_map.get_map_item(seller_container_config.container_id);
	seller_alive = AlivesController.get_alive_by_owner_id(seller_container_config.container_owner);
	if not seller:
		seller = seller_alive;
	_start_update_alive_target_position(seller);
	astar_agent.target_reached.connect(on_agent_target_reached);

func on_agent_target_reached():
	if seller_alive.is_busy:
		_end_action(false);
	else:
		_on_seller_position_reached();

func _start_update_alive_target_position(seller: Node3D):
	if seller.is_busy:
		print('seller.is_busy');
		return;
	print('_start_update_alive_target_position', seller);
	var is_target_in_same_place = await _update_target_target_position(seller);
	if is_target_in_same_place:
		await scene_tree.create_timer(1).timeout;
		seller_container_config = MarketController.get_seller_container_config_by_subtype(target);
		if seller_container_config.is_empty():
			_end_action();
			return ;
		var new_seller = grid_map.get_map_item(seller_container_config.container_id);
		if not new_seller:
			new_seller = AlivesController.get_alive_by_owner_id(seller_container_config.container_owner);
		_start_update_alive_target_position(new_seller);

func _update_target_target_position(seller: Node3D) -> bool:
	var buyer: Alive = AlivesController.get_alive_by_owner_id(buyer_owner_id);
	var target_position: Vector3 = seller.global_position;
	if seller.current_interior != buyer.current_interior:
		if buyer.current_interior != null:
			_end_action(false, Actions.LEAVE_CURRENT_BUILDING);
		elif seller.current_interior != null:
			enter_building(buyer, seller.current_exterior_house);
			await on_enter_building;
			_end_action(false);
		return false;
	astar_agent.target_position = target_position;
	return true;

func enter_building(buyer: Node3D, exterior: ExteriorHouseController):
	astar_agent.target_reached.disconnect(on_agent_target_reached);
	astar_agent.target_position = exterior.door_instance.global_position;
	await astar_agent.target_reached;
	buyer._nearest_interactive = exterior.door_instance;
	buyer._nearest_interactive.interact(buyer_owner_id);
	buyer._nearest_interactive = null;
	on_enter_building.emit();

func _end_action(unlock_player: bool = true, next_action_id: String = Actions.WAIT):
	if astar_agent.target_reached.is_connected(on_agent_target_reached):
		astar_agent.target_reached.disconnect(on_agent_target_reached);
	var _next_action = await Actions.get_action_by_id(next_action_id);
	is_running = false;
	on_action_finished.emit(id, buyer_owner_id, _next_action);
	if unlock_player:
		PlayerEvents.on_player_block.emit(false);

func _on_seller_position_reached():
	if not is_running:
		return ;
	var item = GameItems.get_items_by_subtype(target)[0];
	if "player" in seller_container_config.container_owner.to_lower():
		_process_target_player(item);
	else:
		_on_accept(item);

func _on_accept(item: Dictionary, notify: bool = false) -> void:
	if notify:
		NotificationEvents.notify.emit(NotificationEvents.NotificationType.SUCCESS, 'MARKET.TRADE_SUCCESS');
	print(buyer_owner_id, " is buying things of ", seller_container_config.container_owner);
	MarketController.trade(seller_container_config.container_id, item.id, 1, seller_container_config.container_owner, \
							buyer_owner_id);
	InventoryEvents.container_data_changed.emit(seller_container_config.container_id);
	_end_action();

func _on_decline() -> void:
	_end_action();

func _process_target_player(item) -> void:
	is_running = false;
	astar_agent.target_reached.disconnect(on_agent_target_reached);

	PlayerEvents.on_player_block.emit(true);
	var modal_params = {
		'id': DIALOG_TITLE,
		'global_position': Vector2.ONE * 200,
		'modal_on_left': false,
		'ask_translation': tr('MARKET.ASK_BUY') + " 1 " + tr(item.name),
		'name_translation': pnj_name,
		'answers': [
			{'text': tr('MARKET.ACCEPT'), 'callback': _on_accept.bind(item, true)},
			{'text': tr('MARKET.DECLINE'), 'callback': _on_decline}
		]
	};
	HudEvents.open_modal.emit('res://UI/Modals/DialogModal/DialogModal.tscn', modal_params);
