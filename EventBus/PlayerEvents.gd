extends Node

signal on_nearest_interactive_changed(object: MapItem);
signal on_item_in_hand_changed(item);
signal on_player_block(value: bool);
signal player_status_changed(status: Dictionary);
signal equipment_changed();
signal equip_item_requested(item_id: String);
signal player_died();
signal respawn();
