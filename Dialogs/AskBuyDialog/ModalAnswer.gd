extends NinePatchRect

@export var _normal_texture: Texture;
@export var _hover_texture: Texture;
@export var _ask_buy_dialog: AskBuyDialog;
@export var _is_accept_button: bool = false;


func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		_ask_buy_dialog.close_parent_modal(_is_accept_button);

func _on_mouse_entered():
	texture = _hover_texture;

func _on_mouse_exited():
	texture = _normal_texture;
