extends Node

func get_mesh_in_child(parent_node: Node3D) -> MeshInstance3D:
	var meshes = parent_node.find_children("*", "MeshInstance3D", true, false);
	if not meshes.is_empty():
		return meshes[0];
	printerr("PlayerMouseAction::_get_mesh_in_child:: no mesh in:");
	parent_node.print_tree_pretty();
	return;

func get_map_item_id(map_item: MapItem) -> String:
	var map_id = PackedStringArray([map_item.name, map_item.position.x, map_item.position.y, map_item.position.z])
	return '_'.join(map_id);
