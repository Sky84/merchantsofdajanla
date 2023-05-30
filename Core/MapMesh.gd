@tool
extends MeshInstance3D

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
	var new_material: StandardMaterial3D = _material.duplicate(true);
	new_material.albedo_texture = _texture;
	set_surface_override_material(0, new_material);
