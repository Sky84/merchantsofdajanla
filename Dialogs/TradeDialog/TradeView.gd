extends Panel

@export var _trade_player_container_id: String = "player_dynamic_trade";
@export var _trade_container_id: String = "dynamic_trade";
@export var info_panel: Panel;

@onready var merchant_container_view: MerchantContainerView = $HBox/MerchantContainerView;
@onready var trade_container_view: TradeContainerView = $HBox/TradeContainerView;
@onready var trade_player_container_view: TradeContainerView = $HBox/TradePlayerContainerView;
@onready var player_container_view: PlayerContainerView = $HBox/PlayerContainerView;

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false;
	player_container_view.update_containers_views.connect(_on_update_views);
	trade_container_view.update_containers_views.connect(_on_update_views);
	trade_player_container_view.update_containers_views.connect(_on_update_views);
	merchant_container_view.update_containers_views.connect(_on_update_views);

func _on_update_views() -> void:
	var merchant_slots = ContainersController.get_container_data(merchant_container_view.container_id);
	merchant_container_view._update_items(merchant_slots);
	var player_slots = ContainersController.get_container_data(player_container_view.container_id);
	player_container_view._update_items(player_slots);
	var trade_slots = ContainersController.get_container_data(trade_container_view.container_id);
	trade_container_view._update_items(trade_slots);
	var trade_player_slots = ContainersController.get_container_data(trade_player_container_view.container_id);
	trade_player_container_view._update_items(trade_player_slots);

func open(merchant_container_id: String) -> void:
	ContainersController.register_container(_trade_container_id,\
		2, trade_container_view._items_container.columns, {}, "dynamic");
	ContainersController.register_container(_trade_player_container_id,\
		2, trade_player_container_view._items_container.columns, {}, "player_dynamic");
	player_container_view._init_container();
	merchant_container_view._init_container(_trade_container_id, merchant_container_id, player_container_view.container_id);
	trade_container_view._init_container(_trade_container_id, merchant_container_id, player_container_view.container_id);
	trade_player_container_view._init_container(_trade_player_container_id, player_container_view.container_id, merchant_container_id);
	info_panel.global_position = global_position - Vector2(info_panel.size.x + 30, 0);
	visible = true;

func _on_close_button_pressed():
	visible = false;
