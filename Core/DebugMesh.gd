extends MeshInstance3D
class_name DebugMesh


# Called when the node enters the scene tree for the first time.
func _ready():
	transparency = 0.5;
	mesh = BoxMesh.new();
	mesh.size = Vector3(0.3, 1, 0.3);
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;
