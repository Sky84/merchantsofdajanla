extends TextureButton
class_name SlotButton

signal pressed_with(click_index, slot, x, y)

func _gui_input(event):
	if event is InputEventMouseButton && event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT:
				emit_signal("pressed_with", event.button_index);
