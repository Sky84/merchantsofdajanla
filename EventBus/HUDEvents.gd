extends Node

signal update_player_mouse_action();

signal open_stand_setup(container_id: String, screen_position: Vector2);

signal open_stand_transaction(container_id: String, _interract_owner_id: String, screen_position: Vector2);

signal price_item_changed(item: Dictionary);

signal open_modal(path_node_to_instance: String, params: Dictionary);

signal closed_modal(result: Dictionary);

signal close_modal(result: Dictionary);
