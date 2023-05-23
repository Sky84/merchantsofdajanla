@tool
extends MeshInstance3D

@export var texture: Texture:
	get:
		return texture;
	set(value):
		texture = value;
		_on_texture_changed(value);

var _material: StandardMaterial3D = preload("res://UI/Shaders/PixelMaterial.tres");

func _on_texture_changed(new_texture: Texture):
	mesh = PlaneMesh.new();
	texture = new_texture;
	var new_material: StandardMaterial3D = _material.duplicate(true);
	new_material.albedo_texture = texture;
	set_surface_override_material(0, new_material);
