extends Node

var _cut_scene_player_position: Vector3 = Vector3(0, 0, 0);

func play_state(game_map_controller: GameMapController, player: Player) -> void:
	player.global_position = _cut_scene_player_position;
	print('BeforeIntro')
	await player.get_tree().create_timer(1.0).timeout;
	var city: ChunkController = game_map_controller.get_city('CITY_1');
	var _house_exterior: ExteriorHouseController = city.get_node('MapDecorations/House2');
	player._nearest_interactive = _house_exterior.door_instance;
	player._nearest_interactive.interact(player._owner_id);
	player._nearest_interactive = null;
	
