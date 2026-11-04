extends Node

var _start_cut_scene_player_position: Vector3 = Vector3(0, 0, 0);

@export var tutorial_pnj: PackedScene;
@export var angry_pnj: PackedScene;
const DIALOG_TITLE := 'before-intro-modal';

var _game_map_controller: GameMapController;
var _interior_house: Node3D;
var _player: Player;
var _intro_done := false;

const SAVE_PATH := "user://savegame.json";

func play_state(game_map_controller: GameMapController, player: Player) -> void:
	_game_map_controller = game_map_controller;
	_player = player;
	var save = _load_save();
	_intro_done = save.get("intro_done", false);
	GameTimeEvents.on_game_time_changed.connect(func(_t): _save_progress());
	PlayerEvents.save_requested.connect(_save_progress);
	if _intro_done:
		var pos = save.get("pos", [0.0, 0.0, 0.0]);
		if pos[1] < -10.0: # position sauvée dans un intérieur — l'instance n'existe pas au reload
			pos = [0.0, 0.0, 0.0];
		player.global_position = Vector3(pos[0], pos[1], pos[2]);
		return;
	player.global_position = _start_cut_scene_player_position;
	print('BeforeIntroStory Start')
	await player.get_tree().create_timer(1.0).timeout;
	var city: ChunkController = _game_map_controller.get_city('CITY_1');
	var _house_exterior: ExteriorHouseController = city.get_node('MapDecorations/House2');
	player._nearest_interactive = _house_exterior.door_instance;
	player._nearest_interactive.interact(player._owner_id);
	player._nearest_interactive = null;

	var pnj = tutorial_pnj.instantiate();
	_interior_house = get_node(_game_map_controller.spawned_interior_houses[_house_exterior.house_id].node_path);
	_interior_house.get_node('PNJs').add_child(pnj);
	pnj.global_position = _interior_house.get_node('SellingPoint').global_position;
	AlivesController.set_alive_blocked(true);
	
	PlayerEvents.on_player_block.emit(true);
	await _start_dialog("pnj-before-intro", pnj);
	_on_basic_intro_goodbye(_game_map_controller);

# called as answers call_back
func _on_basic_intro_goodbye(game_map_controller: GameMapController) -> void:
	var pnj = angry_pnj.instantiate();
	var spawn_point = _interior_house.get_node('SellingPoint').global_position + Vector3(3, 0, 3);
	_interior_house.get_node('PNJs').add_child(pnj);
	pnj.global_position = spawn_point;
	AlivesController.set_alive_blocked(true);
	await pnj.get_tree().create_timer(0.5).timeout;
	await _start_dialog("angry-pnj-after-intro", pnj);
	AlivesController.set_alive_blocked(false);
	PlayerEvents.on_player_block.emit(false);
	_intro_done = true;
	_save_progress();

func _load_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {};
	var parsed = JSON.parse_string(FileAccess.open(SAVE_PATH, FileAccess.READ).get_as_text());
	return parsed if parsed is Dictionary else {};

func _save_progress() -> void:
	if not _intro_done or _player == null:
		return;
	var pos = _player.global_position;
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE);
	f.store_string(JSON.stringify({"intro_done": true, "pos": [pos.x, pos.y, pos.z]}));

func _on_after_angry_pnj() -> void:
	print('AfterAngryPnj');
	AlivesController.set_alive_blocked(false);
	PlayerEvents.on_player_block.emit(false);

func _start_dialog(dialog_configuration: String, pnj) -> void:
	var dialog_state = DialogsController.load_dialog(dialog_configuration);
	while dialog_state.current:
		var modal_params = {
			'id': DIALOG_TITLE,
			'speaker_alive': pnj,
			'ask_translation': dialog_state.current.value,
			'name_translation': pnj.pnj_name,
			'answers': DialogsController.get_answers_from_dialog_state(self, dialog_state)
		};
		HudEvents.open_modal.emit('res://UI/Modals/DialogModal/DialogModal.tscn', modal_params);
		var result = await HudEvents.close_modal;
		if result[0] == DIALOG_TITLE:
			DialogsController.next(result[1]);
