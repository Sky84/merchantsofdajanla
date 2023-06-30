extends NinePatchRect
class_name ModalAnswer

@export var _normal_texture: Texture;
@export var _hover_texture: Texture;
@export var _ask_dialog: AskDialog;
var _callback: Callable;

@onready var label = $Label;

var text: String:
	get:
		return label.text;
	set(value):
		if label == null:
			await ready;
		label.text = value;

func _ready():
	mouse_entered.connect(_on_mouse_entered);
	mouse_exited.connect(_on_mouse_exited);

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		_callback.call();
		_ask_dialog.close_parent_modal();

func _on_mouse_entered():
	texture = _hover_texture;

func _on_mouse_exited():
	texture = _normal_texture;
