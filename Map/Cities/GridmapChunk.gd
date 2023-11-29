@tool
extends GridMap

var cell_value_map: Dictionary = {
	'Dirt':[0,1],
	'Sand':[2,3],
	'Grass':[4,5],
	'Water':[6],
}

var _chunk: ChunkController;

@export var _shader_chunk_city: ShaderMaterial;
@export var _tile_scene_ground_placeable: Array[Texture2D];
@export var _update_chunk: bool:
	set(value):
		if _chunk:
			_update_chunk_image();

@export var chunk: ChunkController:
	set(value):
		_chunk = value;
	get:
		return _chunk;

@export var chunk_image: Image;

func _ready():
	_update_chunk_image();

func _update_chunk_image():
	if Engine.is_editor_hint():
		_update_collisions();
	chunk_image = _capture_heightmap();
	var texture_tiles = Texture2DArray.new();
	texture_tiles.create_from_images(
		_tile_scene_ground_placeable.map(NodeUtils.get_image_from_texture)
	);
	_chunk.set_surface_override_material(0, _shader_chunk_city);
	_chunk.init_shader(texture_tiles, _tile_scene_ground_placeable.size(), ImageTexture.create_from_image(chunk_image));

func _update_collisions():
	var water_cells: Array[Vector3i] = get_used_cells_by_item(4);
	for child in _chunk.get_children():
		_chunk.remove_child(child);
		child.queue_free();
	for cell_position in water_cells:
		var static_body = StaticBody3D.new();
		var collision_shape = CollisionShape3D.new();
		collision_shape.shape = BoxShape3D.new();
		collision_shape.shape.size = Vector3(2, 2, 2);
		static_body.add_child(collision_shape);
		_chunk.add_child(static_body);
		static_body.global_position = (cell_position * 2) + Vector3i(1, 0, 1);
		static_body.global_position.y = _chunk.global_position.y;
		static_body.owner = get_tree().edited_scene_root;
		collision_shape.owner = get_tree().edited_scene_root;

func _capture_heightmap() -> Image:
	var chunk_size: float = 32;
	var heightmap = Image.create(chunk_size, chunk_size, false, Image.FORMAT_RGB8);

	for x in range(chunk_size):
		for z in range(chunk_size):
			var cell_type = float(get_cell_maped_item(Vector3(x-chunk_size/2, 0, z-chunk_size/2)));
			var cell_height: float = cell_type / float(_tile_scene_ground_placeable.size() - 1);
			heightmap.set_pixel(x, z, Color(cell_height, cell_height, cell_height));
	return heightmap;

func get_cell_maped_item(position: Vector3) -> int:
	var cell_value = get_cell_item(position);
	var cell_name = mesh_library.get_item_name(cell_value);
	var cell_item = cell_value_map[cell_name];
	return cell_item[randi_range(0, cell_item.size()-1)];
