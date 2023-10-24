@tool
extends MeshInstance3D
class_name MapMesh

@export var tile_atlas_size: float = 32;
@export var init_atlas: bool:
	get:
		return false;
	set(value):
		_update_for_atlas();

@export var rotate_60: bool:
	get:
		return floor(rotation_degrees.x) == 60;
	set(value):
		if !value:
			rotation_degrees.x = 0;
			return;
		rotation_degrees.x = 0 if floor(rotation_degrees.x) == 60 else 60;

var _texture: Texture;

@export var texture: Texture:
	get:
		return _texture;
	set(value):
		_texture = value;
		_on_texture_changed(value);

var _shader: Shader = preload("res://MapMeshShader.tres");

func _ready():
	_update_for_atlas();

func _on_texture_changed(new_texture: Texture):
	mesh = PlaneMesh.new();
	_texture = new_texture;
	
	if _texture is AtlasTexture:
		return;
	var _material: ShaderMaterial = ShaderMaterial.new();
	_material.shader = _shader;
	_material.albedo_texture = _texture;
	set_surface_override_material(0, _material);

func _update_for_atlas():
	if _texture is AtlasTexture:
		var _material: ShaderMaterial = ShaderMaterial.new();
		_material.shader = _shader;
		var tile_number_width = _texture.region.size.x / tile_atlas_size;
		var tile_number_height = _texture.region.size.y / tile_atlas_size;
		var uv1_scale = NodeUtils.get_atlas_tile_scale_uv1(_texture, tile_atlas_size);
		var uv1_offset = NodeUtils.get_atlas_tile_offset_uv1(_texture, tile_atlas_size);
		_material.set_shader_parameter('texture_atlas', _texture.atlas);
		_material.set_shader_parameter('uv1_offset', uv1_offset);
		_material.set_shader_parameter('uv1_scale', uv1_scale);
		mesh.size.x = tile_number_width;
		mesh.size.y = tile_number_height;
		set_surface_override_material(0, _material);
