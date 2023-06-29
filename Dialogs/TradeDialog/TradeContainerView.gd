extends InventoryView
class_name TradeContainerView

@export var item_texture_rect: TextureRect;
@export var desired_price_value: Label;
@export var amount_value: Label;
@export var trade_item_container: Control;
@export var total_label: Label;
@export var remove_button: TextureButton;

var desired_price_items := {};
var _current_item_id: String;
var _seller_container_id: String;
var _buyer_container_id: String;
var total_price = 0;
signal update_containers_views;

func _ready():
	trade_item_container.visible = false;

func _init_container(trade_container_id: String, seller_container_id: String, buyer_container_id: String):
	container_id = trade_container_id;
	_seller_container_id = seller_container_id;
	_buyer_container_id = buyer_container_id;
	_load_container_config();
	var items = MarketController.get_items(trade_container_id);
	_update_items(items);
	visible = true;

func _update_custom_item(slot_x: int, slot_y: int, slot_instance: SlotButton) -> void:
	var slots = ContainersController.get_container_data(container_id);
	var slot = slots[slot_x][slot_y];
	if (not slot.is_empty()) and (not slot.id in desired_price_items):
		desired_price_items[slot.id] = MarketController.get_current_price(slot);

func _update_items(slots: Dictionary):
	super._update_items(slots);
	_compute_total();
	if not _current_item_id.is_empty():
		var item_data = ContainersController.find_item_in_containers([container_id], _current_item_id);
		if not item_data.is_empty():
			amount_value.text = str(item_data.item.amount);
	trade_item_container.visible = not _current_item_id.is_empty();

func _on_slot_pressed(button_index: int, slot: Dictionary, slot_x: int, slot_y: int):
	_current_item_id = '';
	if not slot.is_empty():
		_current_item_id = slot.id;
		item_texture_rect.texture = load(slot.icon_path);
		desired_price_value.text = str(desired_price_items[_current_item_id]);
		amount_value.text = str(slot.amount);
	trade_item_container.visible = not _current_item_id.is_empty();

func _on_minus_button_pressed():
	desired_price_items[_current_item_id] = max(1, desired_price_items[_current_item_id] - 1);
	desired_price_value.text = str(desired_price_items[_current_item_id]);
	_compute_total();

func _on_plus_button_pressed():
	desired_price_items[_current_item_id] = desired_price_items[_current_item_id] + 1;
	desired_price_value.text = str(desired_price_items[_current_item_id]);
	_compute_total();

func _compute_total():
	total_price = 0;
	var slots = ContainersController.get_container_data(container_id);
	for x in slots:
		for y in slots[x]:
			var item = slots[x][y];
			if not item.is_empty():
				total_price = total_price + (item.amount * desired_price_items[item.id]);
	total_label.text = str(total_price);

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
	else:
		NotificationEvents.notify.emit(NotificationEvents.NotificationType.ERROR, 'MARKET.NOT_ENOUGH');
	_current_item_id = '';
	update_containers_views.emit();

func _on_remove_button_pressed():
	var item_data = ContainersController.find_item_in_containers([container_id], _current_item_id).duplicate(true);
	ContainersController.remove_item([container_id], item_data.item.id, item_data.item.amount);
	ContainersController.add_item([_seller_container_id], item_data.item.id, item_data.item.amount);
	_current_item_id = '';
	update_containers_views.emit();

func _on_amount_minus_button_pressed():
	var item_data = ContainersController.find_item_in_containers([container_id], _current_item_id).duplicate(true);
	ContainersController.remove_item([container_id], item_data.item.id, 1);
	ContainersController.add_item([_seller_container_id], item_data.item.id, 1);
	if item_data.item.amount == 1:
		_current_item_id = '';
	update_containers_views.emit();

func _on_amount_plus_button_pressed():
	var item_data = ContainersController.find_item_in_containers([container_id], _current_item_id).duplicate(true);
	if not item_data.is_empty():
		if MarketController.have_enough(_seller_container_id, item_data.item.id, 1):
			ContainersController.remove_item([_seller_container_id], item_data.item.id, 1);
			ContainersController.add_item([container_id], item_data.item.id, 1);
	update_containers_views.emit();

