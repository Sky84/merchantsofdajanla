extends Panel

@export var _trade_player_container_id: String = "player_dynamic_trade";
@export var _trade_container_id: String = "dynamic_trade";
@export var info_panel: Panel;
@onready var total_label = $TotalLabel
@onready var trade_item_container: TradeItemController = $TradeItemContainer

@onready var merchant_container_view: MerchantContainerView = $HBox/MerchantContainerView;
@onready var trade_container_view: TradeContainerView = $HBox/TradeMerchantContainerView;
@onready var trade_player_container_view: TradeContainerView = $HBox/TradePlayerContainerView;
@onready var player_container_view: PlayerContainerView = $HBox/PlayerContainerView;

@onready var views = [
		player_container_view,
		merchant_container_view,
		trade_container_view,
		trade_player_container_view
	];

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false;
	for view in views:
		view.update_containers_views.connect(_on_update_views);

func _on_update_views() -> void:
	for view in views:
		var view_slots = ContainersController.get_container_data(view.container_id);
		view._update_items(view_slots);
	
	var total_price = trade_player_container_view.total_price - trade_container_view.total_price;
	total_label.text = str(total_price);

func open(merchant_container_id: String) -> void:
	ContainersController.register_container(_trade_container_id,\
		2, trade_container_view._items_container.columns, {}, "dynamic");
	ContainersController.register_container(_trade_player_container_id,\
		2, trade_player_container_view._items_container.columns, {}, "player_dynamic");
	player_container_view._init_container(_trade_player_container_id);
	merchant_container_view._init_container(_trade_container_id, merchant_container_id, player_container_view.container_id);
	trade_container_view._init_container(_trade_container_id, merchant_container_id, player_container_view.container_id);
	trade_player_container_view._init_container(_trade_player_container_id, player_container_view.container_id, merchant_container_id);
	info_panel.global_position = global_position - Vector2(info_panel.size.x + 30, 0);
	visible = true;
	trade_item_container.current_item_id = '';
	_on_update_views();

func _on_close_button_pressed():
	for view in views:
		view.on_close();
	visible = false;
	
