extends Control
class_name TradeItemController
	
var _current_item: Dictionary;
var _container_id: String;
var _desired_prices: Dictionary;

@onready var preview_texture_rect: TextureRect = $TextureRect;
@onready var price_value_label: Label = $DesiredPriceVBoxContainer/TextureRect/Value
@onready var amount_value: Label = $AmountVBoxContainer2/TextureRect/Value

var current_item_id: String: 
	get:
		return  _current_item.id if _current_item else '';

var current_container_id: String:
	get:
		return _container_id;

func set_trade_item(container_id: String, item: Dictionary, desired_prices: Dictionary):
	_container_id = container_id;
	_current_item = item;
	_desired_prices = desired_prices;
	update_labels();
	visible = true;
	
func update_labels() -> void:
	preview_texture_rect.texture = load(_current_item.icon_path);
	amount_value.text = str(_current_item.amount);
	price_value_label.text = str(_desired_prices[_current_item.id]);
	
func reset_trade_item():
	_container_id = '';
	_current_item = {};
	preview_texture_rect.texture = null;
	amount_value.text = '';
	price_value_label.text = '';
	visible = false;
