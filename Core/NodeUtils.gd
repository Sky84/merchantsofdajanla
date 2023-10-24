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
	var cells = gridmap_controller.get_items().keys();
	var around_gap = 5;
	var around_cells = cells.filter(func (cell: Vector3):
		return cell.distance_to(gridmap_controller.global_to_local(start_position)) < around_gap;
	);
	var random_point = around_cells[randi_range(0, around_cells.size()-1)];
	var cell_item = gridmap_controller.get_cell_item(random_point);
	var grounds_cell: Array = [0, 1, 2];
	if grounds_cell.has(cell_item):
		return random_point;

func get_atlas_tile_scale_uv1(_texture: AtlasTexture, tile_size: float):
	var tile_number_width = _texture.region.size.x / tile_size;
	var tile_number_height = _texture.region.size.y / tile_size;
	var uv1_scale = Vector2(
		(tile_size * tile_number_width) /  _texture.atlas.get_width(),
		(tile_size * tile_number_height) /  _texture.atlas.get_height()
	);
	return uv1_scale;

func get_atlas_tile_offset_uv1(_texture: AtlasTexture, tile_size: float):
	var tile_number_width = _texture.region.size.x / tile_size;
	var tile_number_height = _texture.region.size.y / tile_size;
	var uv1_offset = Vector2(
		_texture.region.position.x / _texture.atlas.get_width(),
		_texture.region.position.y / _texture.atlas.get_height()
	);
	return uv1_offset;
	
func get_image_from_texture(_texture: Texture) -> Image:
	var image_pixels: Image = _texture.get_image();
	return image_pixels;
