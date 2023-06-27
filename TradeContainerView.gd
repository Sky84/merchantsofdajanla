extends InventoryView
class_name TradeContainerView

@onready var item_texture_rect: TextureRect = $TradeItemContainer/TextureRect;
@onready var desired_price_value: Label = $TradeItemContainer/DesiredPriceVBoxContainer/TextureRect/Value;
@onready var amount_value = $TradeItemContainer/AmountVBoxContainer2/TextureRect/Value;
@onready var trade_item_container = $TradeItemContainer;

var desired_price_items := {};
var _current_item_id: String;

signal update_containers_views;

func _ready():
	trade_item_container.visible = false;
	pass

func _init_container(trade_container_id: String):
	container_id = trade_container_id;
	_load_container_config();
	var items = MarketController.get_items(trade_container_id);
	_update_items(items);
	visible = true;

func _update_custom_item(slot_x: int, slot_y: int, slot_instance: SlotButton) -> void:
	var slots = ContainersController.get_container_data(container_id);
	var slot = slots[slot_x][slot_y];
	if (not slot.is_empty()) and (not slot.id in desired_price_items):
		desired_price_items[slot.id] = MarketController.get_current_price(slot);

func _on_slot_pressed(button_index: int, slot: Dictionary, slot_x: int, slot_y: int):
	_current_item_id = '';
	if not slot.is_empty():
		_current_item_id = slot.id;
		item_texture_rect.texture = load(slot.icon_path);
		_update_trade_item();
		desired_price_value.text = str(slot.amount);
	trade_item_container.visible = not _current_item_id.is_empty();

func _on_minus_button_pressed():
	desired_price_items[_current_item_id] = desired_price_items[_current_item_id] - 1;
	_update_trade_item();

func _on_plus_button_pressed():
	desired_price_items[_current_item_id] = desired_price_items[_current_item_id] + 1;
	_update_trade_item();

func _update_trade_item():
	print(desired_price_items)
	amount_value.text = str(desired_price_items[_current_item_id]);
