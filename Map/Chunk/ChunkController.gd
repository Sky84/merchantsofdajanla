extends MeshInstance3D

@export var plants_scenes: Array[PlantResource];
@export var decorations_scenes: Array[PackedScene];

@onready var plants: PoolController = $Plants;
@onready var decorations: PoolController = $Decorations;

var noise_texture: ImageTexture;
var noise: FastNoiseLite;

func init_chunk(_tile_scene_ground_placeable: Array[Texture2D], _noise: FastNoiseLite, _noise_texture: ImageTexture) -> void:
	noise_texture = _noise_texture;
	noise = _noise;
	var texture_tiles = Texture2DArray.new();
	texture_tiles.create_from_images(
		_tile_scene_ground_placeable.map(NodeUtils.get_image_from_texture)
	);
	var material = get_surface_override_material(0);
	material.set_shader_parameter('noise_texture', _noise_texture);
	material.set_shader_parameter('textures_tiles', texture_tiles);
	init_plants();
	init_decorations();

func init_plants() -> void:
	for tile_x in range(64):
		for tile_z in range(64):
			var plant_position = Vector3(global_position.x+tile_x, global_position.y, global_position.z+tile_z);
			var noise_index: float = noise.get_noise_2d(plant_position.x, plant_position.z);
			if roundi(noise_index * 10) % 2 != 0:
				continue;
			var index: int = noise_index * plants_scenes.size();
			var plant_resource: PlantResource = plants_scenes[index];
			var plant_instance: MapMesh = plants.add_instance(plant_position);
			plant_instance.tile_atlas_size = plant_resource.tile_atlas_size;
			plant_instance.texture = plant_resource.texture;
			plant_instance.update_for_atlas();

func init_decorations() -> void:
	pass
