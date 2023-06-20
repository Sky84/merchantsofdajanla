extends CitizenController
class_name MerchantController

var is_merchant: bool = true;
var shop_position = Vector3(10, 0, 10);
var _is_trading = false;

var is_trading: bool:
	get:
		return _is_trading;
	set(value):
		_is_trading = value;

func _ready():
	super();

func interact(_interract_owner_id: String) -> void:
	print("_interract_owner_id: "+_interract_owner_id);
