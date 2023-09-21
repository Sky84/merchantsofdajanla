@tool
extends MeshInstance3D

@export var init_atlas: bool:
	get:
		return false;
	set(value):
		_update_for_atlas();

var _texture: Texture;

@export var texture: Texture:
	get:
		return _texture;
	set(value):
		_texture = value;
		_on_texture_changed(value);

var _material: StandardMaterial3D = preload("res://UI/Shaders/PixelMaterial.tres");

func _on_texture_changed(new_texture: Texture):
	mesh = PlaneMesh.new();
	_texture = new_texture;
	
	if _texture is AtlasTexture:
		return;
	var new_material: StandardMaterial3D = _material.duplicate(true);
	new_material.albedo_texture = _texture;
	set_surface_override_material(0, new_material);

func _update_for_atlas():
	if _texture is AtlasTexture:
		var new_material: StandardMaterial3D = _material.duplicate(true);
		new_material.albedo_texture = _texture.atlas;
		new_material.uv1_offset.x = _texture.region.position.x / _texture.atlas.get_width();
		new_material.uv1_offset.y = _texture.region.position.y / _texture.atlas.get_height();
		new_material.uv1_scale.x = 0.2;
		new_material.uv1_scale.y = 0.07;
		set_surface_override_material(0, new_material);
