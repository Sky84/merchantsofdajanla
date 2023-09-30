extends NavigationRegion3D

@export var chunk_tile_size: int;
@export var _chunk_map: PackedScene;
@export var _player: Player;

@export var _savage_chunk_noise: FastNoiseLite;

@export var _world_map: GridMap;

@onready var _tile_count = _world_map.mesh_library.get_item_list().size();

const chunk_city_cell_types = {
	'CITY_1': {
		'scene': preload("res://Map/Cities/City1.tscn"),
		'id': Vector2i(8, 0)},
	'CITY_2': {
		'scene': preload("res://Map/Cities/City2.tscn"),
		'id': Vector2i(9, 0)}
}

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize();
	_savage_chunk_noise.seed = randf_range(0, 1000);
	var tile_chunk_map: TileMap = _chunk_map.instantiate();
	var player_chunk_position: Vector3i = _player.global_position.floor() / float(chunk_tile_size);
	var chunks_xy_to_instantiate = [-2, -1, 0, 1, 2];
	
	for chunk_x in chunks_xy_to_instantiate:
		var start_chunk_x = player_chunk_position.x + (chunk_x * chunk_tile_size);
		for chunk_z in chunks_xy_to_instantiate:
			var start_chunk_z = player_chunk_position.z + (chunk_z * chunk_tile_size);
			var local_chunk_position = Vector2(chunk_x, chunk_z);
			var chunk_global_position = Vector3(start_chunk_x, 0, start_chunk_z);
			var chunk_cell_id = tile_chunk_map.get_cell_atlas_coords(0, local_chunk_position);
			if _is_a_city(chunk_cell_id):
				_load_city_at(chunk_global_position, chunk_cell_id);
			else:
				_generate_savage_chunk_at(chunk_global_position);

func _load_city_at(chunk_global_position: Vector3, chunk_cell_id: Vector2i):
	var chunk_cell_type = _get_chunk_cell_type(chunk_cell_id);
	var city_instance: GridMap = chunk_cell_type.scene.instantiate();
	var used_cells = city_instance.get_used_cells();
	var half_chunk_size = chunk_tile_size * 0.5;
	for tile_x in range(-half_chunk_size, half_chunk_size):
		for tile_y in range(-half_chunk_size, half_chunk_size):
			for tile_z in range(-half_chunk_size, half_chunk_size):
				var local_tile_position = Vector3i(tile_x, tile_y, tile_z);
				var cell_item = -1;
				var tile_position = Vector3(
						chunk_global_position.x + (half_chunk_size + local_tile_position.x),
						chunk_global_position.y + (local_tile_position.y),
						chunk_global_position.z + (half_chunk_size + local_tile_position.z)
					);
				if used_cells.has(local_tile_position):
					cell_item = city_instance.get_cell_item(local_tile_position);
				elif tile_y == 0:
					cell_item = 0;
				
				_world_map.set_cell_item(tile_position, cell_item);
	
	_load_items_by_parent('MapItems', chunk_global_position, city_instance);
	_load_items_by_parent('MapDecorations', chunk_global_position, city_instance);
	_load_items_by_parent('PNJs', chunk_global_position, city_instance);

func _load_items_by_parent(parent_name: String, chunk_global_position: Vector3, city_instance: GridMap):
	var city_map_items = city_instance.get_node(parent_name);
	var world_map_decorations = _world_map.get_node(parent_name);
	var half_chunk_size = (chunk_tile_size * 0.5);
	var city_center = chunk_global_position + Vector3(half_chunk_size,0,half_chunk_size);
	var global_city_center = _world_map.map_to_local(city_center);
	for item in city_map_items.get_children():
		city_map_items.remove_child(item);
		world_map_decorations.add_child(item);
		item.global_position = global_city_center + item.position - Vector3(1,0,1);

func _generate_savage_chunk_at(chunk_global_position: Vector3):
	for tile_x in chunk_tile_size:
		for tile_z in chunk_tile_size:
			var local_tile_position = Vector3(tile_x, 0, tile_z);
			var tile_position = Vector3(chunk_global_position.x + local_tile_position.x, 0,\
					chunk_global_position.z + local_tile_position.z);
			var tile_noise = _savage_chunk_noise.get_noise_2d(tile_position.x* chunk_tile_size, tile_position.z* chunk_tile_size);
			var tile_to_place = (tile_noise + 1.0) * 0.5 * _tile_count;
			_world_map.set_cell_item(tile_position, tile_to_place);

func _get_chunk_cell_type(chunk_id: Vector2i):
	for chunk_cell_type in chunk_city_cell_types:
		var chunk_cell = chunk_city_cell_types[chunk_cell_type];
		if chunk_id == chunk_cell.id:
			return chunk_cell;
			
func _is_a_city(chunk_cell_id: Vector2i):
	return _get_chunk_cell_type(chunk_cell_id) != null;
