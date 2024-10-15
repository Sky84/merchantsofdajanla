extends Node

var _start_cut_scene_player_position: Vector3 = Vector3(0, 0, 0);

@export var tutorial_pnj: PackedScene;
@export var angry_pnj: PackedScene;
const DIALOG_TITLE := 'before-intro-modal';

var _game_map_controller: GameMapController;
var _interior_house: Node3D;

func play_state(game_map_controller: GameMapController, player: Player) -> void:
	_game_map_controller = game_map_controller;
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
	_start_dialog("pnj-before-intro", pnj.pnj_name);

# called as answers call_back
func _on_basic_intro_goodbye(game_map_controller: GameMapController) -> void:
	var pnj = angry_pnj.instantiate();
	var spawn_point = _interior_house.get_node('SellingPoint').global_position + Vector3(3, 0, 3);
	_interior_house.get_node('PNJs').add_child(pnj);
	pnj.global_position = spawn_point;
	AlivesController.set_alive_blocked(true);
	await pnj.get_tree().create_timer(0.5).timeout;
	_start_dialog("angry-pnj-after-intro", pnj.pnj_name);
	
func _on_after_angry_pnj() -> void:
	print('AfterAngryPnj'); 

func _start_dialog(dialog_configuration: String, pnj_name: String) -> void:
	var dialog_state = DialogsController.load_dialog(dialog_configuration);
	while dialog_state.current:
		var modal_params = {
			'id': DIALOG_TITLE,
			'global_position': Vector2.ONE * 200,
			'modal_on_left': false,
			'ask_translation': dialog_state.current.value,
			'name_translation': pnj_name,
			'answers': DialogsController.get_answers_from_dialog_state(self, dialog_state)
		};
		HudEvents.open_modal.emit('res://UI/Modals/DialogModal/DialogModal.tscn', modal_params);
		var result = await HudEvents.close_modal;
		if result[0] == DIALOG_TITLE:
			DialogsController.next(result[1]);
