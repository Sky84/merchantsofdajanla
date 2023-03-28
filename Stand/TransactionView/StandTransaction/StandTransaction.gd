extends InventoryView
class_name StandTransactionView

@onready var _amount_label = $VBoxContainer/TextureRect/Value;

@onready var plus_button = $VBoxContainer/PlusButton;
@onready var minus_button = $VBoxContainer/MinusButton;
@onready var buy_button = $BuyButton;

var _amount_to_buy := 1;

var _current_buyer_id: String;

func open(_container_id: String, _buyer_owner_id: String, _position: Vector2) -> void:
	_current_buyer_id = _buyer_owner_id;
	container_id = _container_id;
	_load_container_config();
	var items = MarketController.get_items(container_id);
	_update_items(items);
	global_position = _position;
	visible = true;

func _update_items(slots: Dictionary) -> void:
	super._update_items(slots);
	_update_amount();

func _update_amount() -> void:
	var item = MarketController.get_first_item(container_id);
	var _item_exist = "amount" in item;
	plus_button.disabled = not _item_exist;
	minus_button.disabled = not _item_exist;
	buy_button.disabled = not _item_exist;
	if _item_exist:
		_amount_to_buy = clampi(_amount_to_buy, 1, item.amount);
	else:
		_amount_to_buy = 1;
	_amount_label.text = str(_amount_to_buy);

func close() -> void:
	visible = false;

func _on_plus_button_pressed():
	var item = MarketController.get_first_item(container_id);
	_amount_to_buy = clampi(_amount_to_buy + 1, 1, item.amount);
	_update_amount();

func _on_minus_button_pressed():
	var item = MarketController.get_first_item(container_id);
	_amount_to_buy = clampi(_amount_to_buy - 1, 1, item.amount);
	_update_amount();

func _on_buy_button_pressed():
	var item = MarketController.get_first_item(container_id);
	var seller = {
		'container_id': container_id,
		'item_id': item.id,
		'amount_to_buy': _amount_to_buy,
		'container_owner': _container_owner
	};
	MarketController.trade(seller.container_id, seller.item_id, seller.amount_to_buy, seller.container_owner,\
		_current_buyer_id);
	NotificationEvents.notify.emit(NotificationEvents.NotificationType.SUCCESS, 'MARKET.TRADE_SUCCESS');
	var items = MarketController.get_items(container_id);
	_update_items(items);

func _on_close_button_pressed():
	close();

func _ready():
	pass

func _input(event):
	pass

func _handle_mouse_click(event: InputEventMouseButton) -> void:
	pass

func _on_slot_pressed(button_index: int, slot: Dictionary, slot_x: int, slot_y: int):
	pass
