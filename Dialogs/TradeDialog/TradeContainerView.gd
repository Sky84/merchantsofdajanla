extends InventoryView
class_name TradeContainerView

@export var trade_item_container: TradeItemController;

@onready var price_minus_button = $"../../TradeItemContainer/DesiredPriceVBoxContainer/MinusButton";
@onready var price_plus_button = $"../../TradeItemContainer/DesiredPriceVBoxContainer/PlusButton";
@onready var amount_minus_button = $"../../TradeItemContainer/AmountVBoxContainer2/MinusButton";
@onready var amount_plus_button = $"../../TradeItemContainer/AmountVBoxContainer2/PlusButton";
@onready var remove_button = $"../../TradeItemContainer/RemoveButton";

var desired_price_items := {};
var _current_item_id: String:
	get:
		return trade_item_container.current_item_id;
var _seller_container_id: String;
var _buyer_container_id: String;
var total_price = 0;
signal update_containers_views;

func _ready():
	trade_item_container.visible = false;

func _init_container(trade_container_id: String, seller_container_id: String, buyer_container_id: String):
	total_price = 0;
	container_id = trade_container_id;
	_seller_container_id = seller_container_id;
	_buyer_container_id = buyer_container_id;
	_load_container_config();
	_init_events();
	visible = true;

func _init_events():
	if not price_minus_button.pressed.is_connected(_on_minus_button_pressed):
		price_minus_button.pressed.connect(_on_minus_button_pressed);
	if not price_plus_button.pressed.is_connected(_on_plus_button_pressed):
		price_plus_button.pressed.connect(_on_plus_button_pressed);
	if not amount_minus_button.pressed.is_connected(_on_amount_minus_button_pressed):
		amount_minus_button.pressed.connect(_on_amount_minus_button_pressed);
	if not amount_plus_button.pressed.is_connected(_on_amount_plus_button_pressed):
		amount_plus_button.pressed.connect(_on_amount_plus_button_pressed);
	if not remove_button.pressed.is_connected(_on_remove_button_pressed):
		remove_button.pressed.connect(_on_remove_button_pressed);

func _update_custom_item(slot_x: int, slot_y: int, slot_instance: SlotButton) -> void:
	var slots = ContainersController.get_container_data(container_id);
	var slot = slots[slot_x][slot_y];
	if (not slot.is_empty()) and (not slot.id in desired_price_items):
		desired_price_items[slot.id] = MarketController.get_current_price(slot);

func _update_items(slots: Dictionary):
	super._update_items(slots);
	_compute_total();
	if not _current_item_id.is_empty():
		trade_item_container.update_labels();
#		var item_data = ContainersController.find_item_in_containers([container_id], _current_item_id);
#		if not item_data.is_empty():
#			trade_item_container.set_trade_item(container_id, item_data.item, desired_price_items);
	trade_item_container.visible = not _current_item_id.is_empty();

func _on_slot_pressed(button_index: int, slot: Dictionary, slot_x: int, slot_y: int):
	if not slot.is_empty():
		trade_item_container.set_trade_item(container_id, slot, desired_price_items);

func _on_minus_button_pressed():
	if  not _is_container_to_update():
		return;
	desired_price_items[_current_item_id] = max(1, desired_price_items[_current_item_id] - 1);
	var item_data = ContainersController.find_item_in_containers([container_id], _current_item_id);
	trade_item_container.set_trade_item(container_id, item_data.item, desired_price_items);
	_compute_total();
	update_containers_views.emit();

func _on_plus_button_pressed():
	if  not _is_container_to_update():
		return;
	desired_price_items[_current_item_id] = desired_price_items[_current_item_id] + 1;
	var item_data = ContainersController.find_item_in_containers([container_id], _current_item_id);
	trade_item_container.set_trade_item(container_id, item_data.item, desired_price_items);
	_compute_total();
	update_containers_views.emit();

func _compute_total():
	total_price = 0;
	var slots = ContainersController.get_container_data(container_id);
	for x in slots:
		for y in slots[x]:
			var item = slots[x][y];
			if not item.is_empty():
				total_price = total_price + (item.amount * desired_price_items[item.id]);

func _on_validate_trade_pressed():
	var slots = ContainersController.get_container_data(container_id);
	_compute_total();
	if MarketController.have_enough(_buyer_container_id, MarketController.MONEY_ITEM_ID, total_price):
		for x in slots:
			for y in slots[x]:
				var item = slots[x][y];
				if not item.is_empty():
					ContainersController.add_item([_buyer_container_id], item.id, item.amount);
					ContainersController.remove_item([container_id], item.id, item.amount);
		ContainersController.remove_item([_buyer_container_id], MarketController.MONEY_ITEM_ID, total_price);
		ContainersController.add_item([_seller_container_id], MarketController.MONEY_ITEM_ID, total_price);
		NotificationEvents.notify.emit(NotificationEvents.NotificationType.SUCCESS, 'MARKET.TRADE_SUCCESS');
	else:
		NotificationEvents.notify.emit(NotificationEvents.NotificationType.ERROR, 'MARKET.NOT_ENOUGH');
	trade_item_container.reset_trade_item();
	update_containers_views.emit();

func _is_container_to_update() -> bool:
	return trade_item_container.current_container_id == container_id;

func _on_remove_button_pressed():
	if  not _is_container_to_update():
		return;
	var item_data = ContainersController.find_item_in_containers([container_id], _current_item_id).duplicate(true);
	ContainersController.remove_item([container_id], item_data.item.id, item_data.item.amount);
	ContainersController.add_item([_seller_container_id], item_data.item.id, item_data.item.amount);
	trade_item_container.reset_trade_item();
	update_containers_views.emit();

func _on_amount_minus_button_pressed():
	if  not _is_container_to_update():
		return;
	var item_data = ContainersController.find_item_in_containers([container_id], _current_item_id).duplicate(true);
	ContainersController.remove_item([container_id], item_data.item.id, 1);
	ContainersController.add_item([_seller_container_id], item_data.item.id, 1);
	if item_data.item.amount == 1:
		trade_item_container.reset_trade_item();
	update_containers_views.emit();

func _on_amount_plus_button_pressed():
	if  not _is_container_to_update():
		return;
	var item_data = ContainersController.find_item_in_containers([container_id], _current_item_id).duplicate(true);
	if not item_data.is_empty():
		if MarketController.have_enough(_seller_container_id, item_data.item.id, 1):
			ContainersController.remove_item([_seller_container_id], item_data.item.id, 1);
			ContainersController.add_item([container_id], item_data.item.id, 1);
	update_containers_views.emit();

func on_close():
	var slots = ContainersController.get_container_data(container_id);
	for x in slots:
		for y in slots[x]:
			var item = slots[x][y];
			if not item.is_empty():
				ContainersController.add_item([_seller_container_id], item.id, item.amount);
				ContainersController.remove_item([container_id], item.id, item.amount);
