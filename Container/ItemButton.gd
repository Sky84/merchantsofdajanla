extends Button

@onready var _label_name = $Name;
@onready var _label_amount = $Amount;

func init_item(item_data: Dictionary):
	_label_name.text = item_data.name;
	_label_amount.text = str(item_data.amount);
