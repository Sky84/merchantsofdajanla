extends CanvasLayer

@onready var confirm_dialog: Panel = $ConfirmDialog

# Called when the node enters the scene tree for the first time.
func _ready():
	InventoryEvents.dialog_confirm_delete_item.connect(_show_dialog);

func _show_dialog(item):
	var message = "Drop and delete "+str(item.amount)+" "+item.name+"(s) ?";
	confirm_dialog.open(message, _on_delete_item.bind(item));

func _on_delete_item(item):
	InventoryEvents.reset_current_item.emit();
