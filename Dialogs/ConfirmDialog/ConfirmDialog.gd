extends Panel

@onready var rich_text_label = $RichTextLabel
@onready var confirm_button = $ConfirmButton

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func open(message: String, on_confirm: Callable):
	if(!confirm_button.is_connected("button_up", _on_confirm_button.bind(on_confirm))):
		InventoryEvents.visibility_current_item.emit(false);
		rich_text_label.text = "[center]"+message+"[/center]";
		confirm_button.connect("button_up", _on_confirm_button.bind(on_confirm));
		show();

func _on_confirm_button(on_confirm: Callable):
	reset();
	on_confirm.call();

func _on_cancel_button_button_up():
	reset();

func reset():
	confirm_button.disconnect("button_up", _on_confirm_button);
	InventoryEvents.visibility_current_item.emit(true);
	hide();
