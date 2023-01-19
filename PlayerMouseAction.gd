extends Control

@onready var _label_name = $LabelName;
@onready var _label_amount = $LabelAmount;
@onready var _texture_icon = $TextureIcon;

func _ready():
	visible = false;
	InventoryEvents.item_in_container_selected.connect(_set_item);

func _set_item(item_data: Dictionary):
	if !item_data.is_empty():
		visible = true;
		_label_name.text = item_data.name;
		_label_amount.text = str(item_data.amount);
		_texture_icon.texture = load(item_data.icon_path);
	else:
		visible = false;

func _input(event):
	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position();
