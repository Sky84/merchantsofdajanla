@tool
extends Node3D
class_name ChunkController

@export var is_city: bool;
@export var border_texture_noise: Texture;
@export var decorations_scenes: Array[PackedScene];
@export var mesh_instance: MeshInstance3D;
@export var decorations: Node3D;

var noise_texture: ImageTexture;
var noise: FastNoiseLite;
var map_objects_initiated: bool = false;

var chunk_objects = [];

func init_chunk(_tile_scene_ground_placeable: Array[Texture2D], _noise: FastNoiseLite, _noise_texture: ImageTexture) -> void:
	noise_texture = _noise_texture;
	noise = _noise;
	if not is_city:
		var texture_tiles = Texture2DArray.new();
		texture_tiles.create_from_images(
			_tile_scene_ground_placeable.map(NodeUtils.get_image_from_texture)
		);
		init_shader(mesh_instance.get_surface_override_material(0), texture_tiles, _tile_scene_ground_placeable.size(), _noise_texture);
		init_decorations();

func init_shader(shader_to_init: ShaderMaterial, texture_tiles: Texture2DArray, tile_type_count: int, _noise_texture: ImageTexture):
	var material = shader_to_init.duplicate();
	material.set_shader_parameter('border_noise_texture', border_texture_noise);
	material.set_shader_parameter('terrain_noise_texture', _noise_texture);
	material.set_shader_parameter('tile_type_count', tile_type_count);
	material.set_shader_parameter('textures_tiles', texture_tiles);
	mesh_instance.set_surface_override_material(0, material);

func init_decorations() -> void:
	for tile_x in range(0, 64, 8):
		for tile_z in range(0, 64, 8):
			var plant_position = Vector3(
				(tile_x),
				position.y,
				(tile_z)
			);
			var noise_value: float = noise.get_noise_2d(plant_position.x, plant_position.z);
			var plant_scene = decorations_scenes[floori(noise_value * decorations_scenes.size())];
			var plant: MapMesh = plant_scene.instantiate();
			decorations.add_child(plant);
			plant.position = Vector3(plant_position.x, plant.position.y, plant_position.z);
			plant.scale.x = -1 if randf() > 0.5 else 1;
			plant.update_for_atlas();

