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
	for tile_x in range(0, 64, 8):
		for tile_z in range(0, 64, 8):
			var plant_position = Vector3(
				global_position.x + (tile_x),
				global_position.y,
				global_position.z + (tile_z)
			);
			var noise_value: float = noise.get_noise_2d(plant_position.x, plant_position.z);
			var plant_resource: Resource = plants_scenes[floori(noise_value * plants_scenes.size())];
			if plant_resource:
				var plant: MapMesh = plants.move_instance(plant_position);
				plant.texture = plant_resource.texture;
				plant.tile_atlas_size = plant_resource.tile_atlas_size;
				plant.position.y = plant_resource.origin_y;
				plant.simulate_wind = plant_resource.simulate_wind;
				plant.rotation_degrees.x = 60;
				plant.scale.x = -1 if randf() > 0.5 else 1;
				plant.update_for_atlas();

func init_decorations() -> void:
	pass
