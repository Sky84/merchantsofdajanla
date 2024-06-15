extends MeshInstance3D
class_name DebugMesh

func _init(size: Vector3):
	mesh = BoxMesh.new();
	mesh.size = size;
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;
