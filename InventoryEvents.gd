extends Node

signal player_action_inventory;

signal item_in_container_selected(item);

signal container_data_changed(container_id, items);

signal dialog_confirm_delete_item(container_id, item);

signal visibility_current_item(value:bool);

signal reset_current_item;
