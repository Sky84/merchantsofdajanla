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
	_is_blocked = true;
	is_busy = true;
	PlayerEvents.on_player_block.emit(true);
	print("_interract_owner_id: "+_interract_owner_id);
	var trader = AlivesController.get_alive_by_owner_id(_interract_owner_id);
	var gap_modal = Vector2(-170, 0) if global_position.x - trader.global_position.x < 0\
		else Vector2(170, 0);
	var answers = [{'text':tr('MARKET.SELLER.BYE'), 'callback': _on_goodbye}];
	if _is_trading:
		answers.push_front({'text':tr('MARKET.SELLER.TRADE'), 'callback': _on_trade.bind(trader)});
	var modal_params = {
		'global_position':  camera_3d.unproject_position(global_position) + gap_modal,
		'modal_on_left': gap_modal.x < 0,
		'ask_translation': tr('MARKET.WELCOME_MARKET'),
		'name_translation': pnj_name,
		'answers': answers
	};
	HudEvents.open_modal.emit('res://Dialogs/AskDialog/AskDialog.tscn', modal_params);

func _on_trade(trader: Alive) -> void:
	print(trader)
	_is_blocked = false;
	is_busy = false;
	PlayerEvents.on_player_block.emit(false);

func _on_goodbye() -> void:
	print('tradergoodbye')
	_is_blocked = false;
	is_busy = false;
	PlayerEvents.on_player_block.emit(false);
