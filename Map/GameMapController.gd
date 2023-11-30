extends NavigationRegion3D
class_name GameMapController

@export var chunk_scene: PackedScene;
@export var chunk_tile_size: int;
@export var _chunk_map: PackedScene;
@export var _player: Player;

@export var _savage_chunk_noise: FastNoiseLite;
var _noise_texture: ImageTexture;

@export var _world_map: Node3D;

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

# Called when the node enters the scene tree for the first time.
func _ready():
	update_noise();
	var tile_chunk_map: TileMap = _chunk_map.instantiate();
	var chunks_xy_to_instantiate = range(-10, 10);
	
	for chunk_x in chunks_xy_to_instantiate:
		var start_chunk_x = (chunk_x * chunk_tile_size);
		for chunk_z in chunks_xy_to_instantiate:
			var start_chunk_z = (chunk_z * chunk_tile_size);
			var local_chunk_position = Vector2(chunk_x, chunk_z);
			var chunk_global_position = Vector3(start_chunk_x, 0, start_chunk_z);
			var chunk_cell_id = tile_chunk_map.get_cell_atlas_coords(0, local_chunk_position);
			if _is_a_city(chunk_cell_id):
				_load_city_at(chunk_global_position, chunk_cell_id);
			else:
				_generate_savage_chunk_at(chunk_global_position);
	bake_navigation_mesh();

func update_noise() -> void:
	randomize();
	_savage_chunk_noise.seed = randf_range(0, 1000);
	_noise_texture = ImageTexture.create_from_image(
		_savage_chunk_noise.get_image(chunk_tile_size * chunk_tile_size, chunk_tile_size * chunk_tile_size)
	);

func _load_city_at(chunk_global_position: Vector3, chunk_cell_id: Vector2i):
	var chunk_cell_type = _get_chunk_cell_type(chunk_cell_id);
	var city_instance: Node3D = chunk_cell_type.scene.instantiate();
	var chunk_city_container = city_instance.get_node('NavigationRegion3D');
	var chunk_city = city_instance.get_node('NavigationRegion3D/Chunk');
	var ground_city = city_instance.get_node('Grounds');
	chunk_city.is_city = true;
	_world_map.add_child(city_instance);
	city_instance.global_position = chunk_global_position + Vector3(32, 0, 32);
	chunk_city_container.global_position.y = ground_city.global_position.y;
	ground_city.visible = false;
	_reparent_items_by_parent('MapItems', chunk_global_position, city_instance);
	_reparent_items_by_parent('MapDecorations', chunk_global_position, city_instance);
	_reparent_items_by_parent('PNJs', chunk_global_position, city_instance);

func _reparent_items_by_parent(parent_name: String, chunk_global_position: Vector3, city_instance: Node3D):
	var city_map_items = city_instance.get_node(parent_name);
	var world_map_items = _world_map.get_node(parent_name);
	for item in city_map_items.get_children():
		item.reparent(world_map_items);

func _generate_savage_chunk_at(chunk_global_position: Vector3):
	var chunk_instance = chunk_scene.instantiate();
	_world_map.add_child(chunk_instance);
	chunk_instance.global_position = chunk_global_position;
	chunk_instance.init_chunk(_tile_scene_ground_placeable, _savage_chunk_noise, _noise_texture);

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
