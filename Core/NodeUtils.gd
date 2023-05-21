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

func get_random_reachable_point(start_position: Vector3, gridmap_controller: GridMapController):
	var cells = gridmap_controller.get_used_cells();
	var around_gap = 5;
	var around_cells = cells.filter(func (cell: Vector3):
		var is_around_x = abs(start_position.x - cell.x);
		var is_around_y = abs(start_position.y - cell.y);
		return is_around_x < around_gap and is_around_y < around_gap;
	);
	
	var random_point = around_cells[randi_range(0, around_cells.size()-1)];
	var cell_item = gridmap_controller.get_cell_item(random_point);
	if cell_item == 0:
		return random_point;
