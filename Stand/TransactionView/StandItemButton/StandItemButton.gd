extends ItemButton
class_name StandItemButton

@onready var _label_price: Label = $Price;

func _set_price(price: int):
	_label_price.text = str(price);
