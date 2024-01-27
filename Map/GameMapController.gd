extends Node3D
class_name GameMapController

@export var chunk_scene: PackedScene;
@export var chunk_tile_size: int;
@export var _chunk_map: PackedScene;
@export var _path_finding: PathFinding;
@export var _player: Player;

@export var _savage_chunk_noise: FastNoiseLite;
var _noise_texture: ImageTexture;

@export var _world_map: GameGridMapController;

@export var _tile_scene_ground_placeable: Array[Texture2D];
@onready var _tile_count = _tile_scene_ground_placeable.size();

@onready var spawned_interior_houses: Dictionary = {};

var _tile_size: int = 32;

const chunk_city_cell_types = {
	'CITY_1': {
		'scene': preload("res://Map/Cities/City1.tscn"),
		'id': Vector2i(8, 0)},
	'CITY_2': {
		'scene': preload("res://Map/Cities/City2.tscn"),
		'id': Vector2i(9, 0)}
}

var _chunk_shader: Shader = preload("res://MapChunkShader.tres");
@onready var _tile_chunk_map: TileMap = _chunk_map.instantiate();
var _distance_chunk: Vector3 = Vector3(3, 0, 2);

var _chunks = {};
var chunks_visible := {};

var _previous_player_position = Vector3(-1000, -1000, -1000);

# Called when the node enters the scene tree for the first time.
func _ready():
	update_noise();
	
func _process(delta):
	var player_chunk_position: Vector3 = (_player.global_position / chunk_tile_size).floor();
	if _previous_player_position != player_chunk_position:
		_previous_player_position = player_chunk_position;
		_update_chunks(player_chunk_position);
		_path_finding.update_pathfinding(chunks_visible, chunk_tile_size, _tile_size);

func _update_chunks(player_chunk_position: Vector3):
	var distance_with_gap = _distance_chunk * 2;
	var chunks_x_to_update: Array = range(player_chunk_position.x - distance_with_gap.x, player_chunk_position.x + distance_with_gap.x);
	var chunks_z_to_update: Array = range(player_chunk_position.z - distance_with_gap.z, player_chunk_position.z + distance_with_gap.z);
	var _chunks_visible = {};
	for chunk_x in chunks_x_to_update:
		var start_chunk_x = (chunk_x * chunk_tile_size);
		_chunks_visible[chunk_x] = {};
		for chunk_z in chunks_z_to_update:
			var start_chunk_z = (chunk_z * chunk_tile_size);
			var local_chunk_position = Vector2(chunk_x, chunk_z);
			var chunk_global_position = Vector3(start_chunk_x, 0, start_chunk_z);
			var chunk_cell_id = _tile_chunk_map.get_cell_atlas_coords(0, local_chunk_position);
			var should_visible = chunk_x >= player_chunk_position.x - _distance_chunk.x\
				and chunk_x < player_chunk_position.x + _distance_chunk.x\
				and chunk_z >= player_chunk_position.z - _distance_chunk.z\
				and chunk_z < player_chunk_position.z + _distance_chunk.z;
			var chunk_instance: ChunkController = _get_or_instantiate_chunk(chunk_x, chunk_z, chunk_cell_id);
			chunk_instance.visible = should_visible;
			if should_visible:
				init_map_objects(chunk_instance);
				_chunks_visible[chunk_x][chunk_z] = chunk_instance;
	chunks_visible = _chunks_visible;

func init_map_objects(chunk_instance: ChunkController):
	if chunk_instance.map_objects_initiated:
		return;
	var map_items = chunk_instance.get_node('MapItems').get_children();
	var map_decorations = chunk_instance.get_node('MapDecorations').get_children();
	var map_collisions = chunk_instance.mesh_instance.get_node('Collisions').get_children();
	var chunk_objects := {};
	for map_item in map_items:
		chunk_objects[map_item.global_position] = map_item;
		_world_map._init_posable(map_item, map_item.global_position, "");
	for map_decoration in map_decorations:
		chunk_objects[map_decoration.global_position] = map_decoration;
		_world_map._init_decorations(map_decoration);
	for map_collision in map_collisions:
		chunk_objects[map_collision.global_position] = map_collision;
	chunk_instance.chunk_objects = chunk_objects;
	chunk_instance.map_objects_initiated = true;

func _get_or_instantiate_chunk(chunk_x: int, chunk_z: int, chunk_cell_id: Vector2i) -> ChunkController:
	if not chunk_x in _chunks:
		_chunks[chunk_x] = {chunk_z: _instantiate_chunk(chunk_x, chunk_z, chunk_cell_id)};
	elif not chunk_z in _chunks[chunk_x]:
		_chunks[chunk_x][chunk_z] = _instantiate_chunk(chunk_x, chunk_z, chunk_cell_id);
	return _chunks[chunk_x][chunk_z];

func _instantiate_chunk(chunk_x: int, chunk_z: int, chunk_cell_id: Vector2i): 
	var chunk_global_position = Vector3(chunk_x * chunk_tile_size, 0, chunk_z * chunk_tile_size);
	var chunk_instance: ChunkController;
	if _is_a_city(chunk_cell_id):
		return _load_city_at(chunk_global_position, chunk_cell_id);
	else:
		return _generate_savage_chunk_at(chunk_global_position);

func update_noise() -> void:
	randomize();
	_savage_chunk_noise.seed = randf_range(0, 1000);
	_noise_texture = ImageTexture.create_from_image(
		_savage_chunk_noise.get_image(chunk_tile_size * chunk_tile_size, chunk_tile_size * chunk_tile_size)
	);

func _load_city_at(chunk_global_position: Vector3, chunk_cell_id: Vector2i) -> ChunkController:
	var chunk_cell_type = _get_chunk_cell_type(chunk_cell_id);
	var city_instance: Node3D = chunk_cell_type.scene.instantiate();
	var chunk_city: ChunkController = city_instance.get_node('Chunk');
	var ground_city = city_instance.get_node('Grounds');
	chunk_city.is_city = true;
	_world_map.add_child(city_instance);
	city_instance.global_position = chunk_global_position + Vector3(32, 0, 32);
	chunk_city.global_position.y = ground_city.global_position.y;
	ground_city.visible = false;
	return chunk_city;

func _generate_savage_chunk_at(chunk_global_position: Vector3)  -> ChunkController:
	var chunk_instance: ChunkController = chunk_scene.instantiate();
	var chunk_mesh = chunk_instance.get_node('MeshInstance3D');
	chunk_instance.init_chunk(_tile_scene_ground_placeable, _savage_chunk_noise, _noise_texture);
	_world_map.add_child(chunk_instance);
	chunk_instance.global_position = chunk_global_position;
	return chunk_instance;

func add_interior_house(house_id: String, interior_scene: PackedScene) -> Node3D:
	var interior_instance = interior_scene.instantiate();
	_world_map.get_node('Interiors').add_child(interior_instance);
	interior_instance.position.y = 1000 * spawned_interior_houses.values().size();
	spawned_interior_houses[house_id] = {'node_path': interior_instance.get_path()};
	return interior_instance;

func _get_chunk_cell_type(chunk_id: Vector2i):
	for chunk_cell_type in chunk_city_cell_types:
		var chunk_cell = chunk_city_cell_types[chunk_cell_type];
		if chunk_id == chunk_cell.id:
			return chunk_cell;

func _is_a_city(chunk_cell_id: Vector2i):
	return _get_chunk_cell_type(chunk_cell_id) != null;

func _get_global_tile_position(chunk_global_position: Vector3, local_tile_position: Vector3) -> Vector3:
	return Vector3(chunk_global_position.x + local_tile_position.x,\
			0,\
			chunk_global_position.z + local_tile_position.z);

func get_image_from_texture(_texture: Texture) -> Image:
	var image_pixels: Image = _texture.get_image();
	if _texture is AtlasTexture:
		var image_from_texture: Image;
		image_from_texture = image_pixels.get_region(_texture.region);
		return image_from_texture;
	else:
		return image_pixels;
