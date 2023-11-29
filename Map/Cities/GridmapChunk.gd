@tool
extends GridMap

var cell_value_map: Dictionary = {
	'Dirt':[0],
	'Sand':[1],
	'Grass':[2],
	'Water':[3],
}

var _chunk: ChunkController;

@export var _tile_scene_ground_placeable: Array[Texture2D];
@export var chunk: ChunkController:
	set(value):
		_chunk = value;
		if value:
			_update_chunk_image();
	get:
		return _chunk;

@export var chunk_image: Image;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _update_chunk_image():
	chunk_image = _capture_heightmap();
	var texture_tiles = Texture2DArray.new();
	texture_tiles.create_from_images(
		_tile_scene_ground_placeable.map(NodeUtils.get_image_from_texture)
	);
	_chunk.init_shader(texture_tiles, _tile_scene_ground_placeable.size(), ImageTexture.create_from_image(chunk_image));

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
	return cell_item[0];
