extends CitizenController
class_name MerchantController

const DIALOG_TITLE := 'merchant-interaction';
var is_merchant: bool = true;
var shop_position = Vector3(10, 0, 10);
var _is_trading = false;
var dialog_configuration: String = "merchant-unavailable";

var is_trading: bool:
	get:
		return _is_trading;
	set(value):
		_is_trading = value;

func _ready():
	super();

func interact(_interract_owner_id: String) -> void:
	dialog_configuration = "merchant" if _is_trading else "merchant-unavailable";
	_is_blocked = true;
	is_busy = true;
	PlayerEvents.on_player_block.emit(true);
	print("_interract_owner_id: "+_interract_owner_id);
	var trader = AlivesController.get_alive_by_owner_id(_interract_owner_id);
	var gap_modal = Vector2(-170, 0) if global_position.x - trader.global_position.x < 0\
		else Vector2(170, 0);
	var dialog_state = DialogsController.load_dialog(dialog_configuration);
	while dialog_state.current:
		var modal_params = {
			'id': DIALOG_TITLE,
			'global_position':  camera_3d.unproject_position(global_position) + gap_modal,
			'modal_on_left': gap_modal.x < 0,
			'ask_translation': dialog_state.current.value,
			'name_translation': pnj_name,
			'answers': DialogsController.get_answers_from_dialog_state(self, dialog_state)
		};
		HudEvents.open_modal.emit('res://UI/Modals/DialogModal/DialogModal.tscn', modal_params);
		var result = await HudEvents.close_modal;
		if result[0] == DIALOG_TITLE:
			DialogsController.next(result[1]);

func _on_trade() -> void:
	_is_blocked = false;
	is_busy = false;
	PlayerEvents.on_player_block.emit(false);
	var container_id: String = ContainersController.get_container_ids_by_owner_id(_owner_id)[0];
	HudEvents.open_trade_view.emit(container_id);

func _on_goodbye() -> void:
	print('tradergoodbye')
	_is_blocked = false;
	is_busy = false;
	PlayerEvents.on_player_block.emit(false);
