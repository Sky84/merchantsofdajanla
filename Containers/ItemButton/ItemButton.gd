extends Button
class_name ItemButton

@onready var _label_amount: Label = $Amount;
@onready var _texture: TextureRect = $Texture

var _item: Dictionary;
var _show_info: bool;

func init_item(item_data: Dictionary, __show_info: bool = true):
	_label_amount.text = str(item_data.amount);
	_texture.texture = load(item_data.icon_path);
	_item = item_data;
	_show_info = __show_info;

func _on_mouse_entered():
	if _show_info:
		InventoryEvents.show_info_item.emit(_item);
