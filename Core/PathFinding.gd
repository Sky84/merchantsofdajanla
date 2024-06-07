extends Node3D
class_name PathFinding

@export var debug: bool:
	get:
		return _debug;
	set(value):
		_set_debug(value);
		_debug = value;

var _debug: bool = false;

var pathfinding: AStar3D = AStar3D.new();
var points := {};
var reachable_object_points = [];

var debug_cubes = {};

var gap_between_points: int = 4;

func _set_debug(value):
	for key in debug_cubes:
		debug_cubes[key].visible = value;

func update_pathfinding(chunks, chunk_tile_size: int, _tile_size: int):
	for chunk_x in chunks:
		for chunk_z in chunks[chunk_x]:
			var chunk: ChunkController = chunks[chunk_x][chunk_z];
			for reachable_object in get_tree().get_nodes_in_group('reachable_objects'):
				if not (reachable_object.global_position in points):
					_add_point(reachable_object.global_position);
					reachable_object_points.append(reachable_object.global_position);
			for tile_x in range(0, chunk_tile_size, gap_between_points):
				for tile_z in range(0, chunk_tile_size, gap_between_points):
					var point_position = Vector3(
						(chunk_x*chunk_tile_size) + (tile_x),
						chunk.global_position.y,
						(chunk_z*chunk_tile_size) + (tile_z)
					);
					if point_position in points or _is_object_on_point(chunk, point_position):
						continue;
					_add_point(point_position);
	_connect_all_points();

func _add_point(point_position: Vector3):
	var id = pathfinding.get_available_point_id();
	points[point_position] = id;
	pathfinding.add_point(id, point_position);
	if not point_position in debug_cubes and debug:
		var debug_mesh := DebugMesh.new(Vector3(0.3, 1, 0.3));
		add_child(debug_mesh);
		debug_cubes[point_position] = debug_mesh;
		debug_mesh.global_position = point_position;

func _is_object_on_point(chunk: ChunkController, point_position: Vector3):
	var result := false;
	for key in chunk.chunk_objects:
		var object = chunk.chunk_objects[key];
		var object_position = Vector3(object.global_position.x, 0, object.global_position.z);
		var object_size: Vector3 = Vector3(3, 3, 3);
		var aabb = AABB(object_position, object_size);
		var aabb_point = AABB(point_position, Vector3(1, 1, 1));
		if object is StaticBody3D:
			var collision_shapes: Array = object.get_children().filter(func(c): return 'CollisionShape3D' in c.name);
			for collision_shape in collision_shapes:
				object_size = collision_shape.shape.size if 'size' in collision_shape.shape\
					 else Vector3(collision_shape.shape.radius, 0, collision_shape.shape.radius);
				var object_aabb = AABB(collision_shape.global_position, object_size);
				aabb = aabb.merge(object_aabb);
			
		result = aabb.intersects(aabb_point);
		if result:
			break;
	return result;

func _connect_all_points():
	var neighbors_to_connect = [-gap_between_points, 0, gap_between_points];
	for point in points:
		for x in neighbors_to_connect:
			for z in neighbors_to_connect:
				var offset = Vector3(x, 0, z);
				var is_diagonal = x + z == 0;
				if offset == Vector3.ZERO or is_diagonal:
					continue;
				var neighbor_point = point + Vector3(x, 0, z);
				if neighbor_point in points:
					_connect_points(point, neighbor_point);
		for reachable_object_point in reachable_object_points:
			if point.distance_to(reachable_object_point) < gap_between_points*2:
				_connect_points(point, reachable_object_point);

func _connect_points(point: Vector3, neighbor_point: Vector3):
	var current_id: int = points[point];
	var neighbor_id: int = points[neighbor_point];
	if not pathfinding.are_points_connected(current_id, neighbor_id) and current_id != neighbor_id:
		pathfinding.connect_points(current_id, neighbor_id);

func find_path(from: Vector3, to: Vector3) -> Array:
	var start: int = pathfinding.get_closest_point(from);
	var end: int = pathfinding.get_closest_point(to);
	var path: Array = pathfinding.get_point_path(start, end);
	return path;
