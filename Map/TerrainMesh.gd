class_name TerrainMesh

const CELL_SIZE := 4.0;
const CELLS := 16;
const LEVEL_HEIGHT := 1.5;
const SNAP_BAND := 0.8;

const FLAT_BAND := 0.72; # share of each level band that stays flat; the rest is a ramp

# Builds a terraced heightfield mesh: flat plateaus at 3 levels with a
# short ramp at the end of each band (Gnomoria-like __/ profile).
# Chunk must be positioned before calling.
static func build(chunk, noise: FastNoiseLite) -> void:
	var heights = _heights(chunk.global_position, noise);
	var st = SurfaceTool.new();
	st.begin(Mesh.PRIMITIVE_TRIANGLES);
	for cz in CELLS:
		for cx in CELLS:
			_emit_quad(st, heights, cx, cz);
	st.generate_normals();
	var mesh = st.commit();
	chunk.mesh_instance.mesh = mesh;
	var body := StaticBody3D.new();
	var shape := CollisionShape3D.new();
	shape.shape = mesh.create_trimesh_shape();
	body.add_child(shape);
	chunk.add_child(body);
	chunk._terrain_heights = heights;

static func _heights(origin: Vector3, noise: FastNoiseLite) -> Array:
	var heights = [];
	for vz in CELLS + 1:
		var row = [];
		for vx in CELLS + 1:
			var n = noise.get_noise_2d(origin.x + vx * CELL_SIZE, origin.z + vz * CELL_SIZE) * 0.5 + 0.5;
			var t = clampf(n, 0.0, 0.999) * 3.0;
			var lvl = floor(t);
			var frac = t - lvl;
			var h = lvl * LEVEL_HEIGHT;
			if frac > FLAT_BAND:
				h += (frac - FLAT_BAND) / (1.0 - FLAT_BAND) * LEVEL_HEIGHT;
			row.append(min(h, 2.0 * LEVEL_HEIGHT));
		heights.append(row);
	return heights;

static func _emit_quad(st: SurfaceTool, heights: Array, cx: int, cz: int) -> void:
	var x0 = cx * CELL_SIZE;
	var z0 = cz * CELL_SIZE;
	var h00 = heights[cz][cx];
	var h10 = heights[cz][cx + 1];
	var h01 = heights[cz + 1][cx];
	var h11 = heights[cz + 1][cx + 1];
	_tri(st, Vector3(x0, h00, z0), Vector3(x0 + CELL_SIZE, h11, z0 + CELL_SIZE), Vector3(x0 + CELL_SIZE, h10, z0));
	_tri(st, Vector3(x0, h00, z0), Vector3(x0, h01, z0 + CELL_SIZE), Vector3(x0 + CELL_SIZE, h11, z0 + CELL_SIZE));

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.set_uv(Vector2(a.x, a.z) / (CELLS * CELL_SIZE));
	st.add_vertex(a);
	st.set_uv(Vector2(b.x, b.z) / (CELLS * CELL_SIZE));
	st.add_vertex(b);
	st.set_uv(Vector2(c.x, c.z) / (CELLS * CELL_SIZE));
	st.add_vertex(c);

# Exact triangle interpolation matching the emitted mesh.
static func get_height(heights: Array, x: float, z: float) -> float:
	var cx = clampi(int(floor(x / CELL_SIZE)), 0, CELLS - 1);
	var cz = clampi(int(floor(z / CELL_SIZE)), 0, CELLS - 1);
	var fx = x / CELL_SIZE - cx;
	var fz = z / CELL_SIZE - cz;
	var h00 = heights[cz][cx];
	var h10 = heights[cz][cx + 1];
	var h01 = heights[cz + 1][cx];
	var h11 = heights[cz + 1][cx + 1];
	if fz <= fx:
		return h00 + fx * (h10 - h00) + fz * (h11 - h10);
	return h00 + fz * (h01 - h00) + fx * (h11 - h01);

# Snaps a walking entity to the terrain when a heightfield chunk is under
# it. Ignored over cities/interiors or when standing on furniture.
static func snap(entity: Node3D) -> void:
	var map = entity.get_tree().get_first_node_in_group("game_map");
	if map == null:
		return;
	var h = map.get_ground_height(entity.global_position.x, entity.global_position.z);
	if h != null and abs(entity.global_position.y - h) < SNAP_BAND + LEVEL_HEIGHT:
		entity.global_position.y = h;
