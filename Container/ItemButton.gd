extends Button

@onready var _label_amount = $Amount;

var _item: Dictionary;

func init_item(item_data: Dictionary):
	_label_amount.text = str(item_data.amount);
	_item = item_data;

func _on_mouse_entered():
	InventoryEvents.show_info_item.emit(_item);
