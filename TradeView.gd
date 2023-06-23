extends Panel

@onready var merchant_container_view: MerchantContainerView = $HBox/MerchantContainerView;
@onready var trade_container_view = $HBox/TradeContainerView;
@onready var player_container_view: PlayerContainerView = $HBox/PlayerContainerView;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func open(merchant_container_id: String) -> void:
	merchant_container_view._init_container(merchant_container_id);
	player_container_view._init_container();
	visible = true;
