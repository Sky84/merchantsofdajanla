class_name TerrainMesh

const CELL_SIZE := 8.0;
const CELLS := 8;
const LEVEL_HEIGHT := 0.8;
const RAMP_WIDTH := 2.0; # fixed slope: every ramp is RAMP_WIDTH wide, one angle
const SNAP_BAND := 2.2;
const CHUNK_SIZE := 64.0;

# City-neighbor bitmask: N/E/S/W then NE/SE/SW/NW.
static func build(chunk, noise: FastNoiseLite, city_edges: int = 0) -> void:
	var levels = _levels(chunk.global_position, noise);
	_flatten_city_borders(levels, city_edges);
	var st = SurfaceTool.new();
	st.begin(Mesh.PRIMITIVE_TRIANGLES);
	for cz in range(1, CELLS + 1):
		for cx in range(1, CELLS + 1):
			_emit_cell(st, levels, cx, cz);
	var mesh = st.commit();
	chunk.mesh_instance.mesh = mesh;
	var body := StaticBody3D.new();
	var shape := CollisionShape3D.new();
	shape.shape = mesh.create_trimesh_shape();
	body.add_child(shape);
	chunk.add_child(body);
	chunk._terrain_heights = levels;

# Levels sampled on a global cell grid (halo of 1 around the chunk) so
# borders stay continuous between chunks.
static func _levels(origin: Vector3, noise: FastNoiseLite) -> Array:
	var levels = [];
	for cz in CELLS + 2:
		var row = [];
		for cx in CELLS + 2:
			var n = noise.get_noise_2d(origin.x + (cx - 0.5) * CELL_SIZE, origin.z + (cz - 0.5) * CELL_SIZE);
			row.append(clampi(int((n * 0.5 + 0.5) * 3.0), 0, 2));
		levels.append(row);
	return levels;

static func _flatten_city_borders(levels: Array, city_edges: int) -> void:
	if city_edges == 0:
		return;
	for cz in CELLS + 2:
		for cx in CELLS + 2:
			var near_city = (city_edges & 1 and cz <= 1) or (city_edges & 2 and cx >= CELLS) \
				or (city_edges & 4 and cz >= CELLS) or (city_edges & 8 and cx <= 1) \
				or (city_edges & 16 and cz <= 1 and cx >= CELLS) \
				or (city_edges & 32 and cz >= CELLS and cx >= CELLS) \
				or (city_edges & 64 and cz >= CELLS and cx <= 1) \
				or (city_edges & 128 and cz <= 1 and cx <= 1);
			if near_city:
				levels[cz][cx] = 0;

# Each cell is one continuous surface. The inner area stays flat and the
# outer strip rises toward a higher cardinal neighbor at one fixed angle.
static func _emit_cell(st: SurfaceTool, levels: Array, cx: int, cz: int) -> void:
	var lvl = levels[cz][cx];
	var x0 = (cx - 1) * CELL_SIZE;
	var z0 = (cz - 1) * CELL_SIZE;
	var cuts = [0.0, RAMP_WIDTH, RAMP_WIDTH * 2.0,
		CELL_SIZE - RAMP_WIDTH * 2.0, CELL_SIZE - RAMP_WIDTH, CELL_SIZE];
	cuts.sort();
	var unique_cuts: Array[float] = [];
	for cut in cuts:
		if unique_cuts.is_empty() or not is_equal_approx(unique_cuts.back(), cut):
			unique_cuts.append(cut);
	for iz in unique_cuts.size() - 1:
		for ix in unique_cuts.size() - 1:
			var lx0: float = unique_cuts[ix];
			var lx1: float = unique_cuts[ix + 1];
			var lz0: float = unique_cuts[iz];
			var lz1: float = unique_cuts[iz + 1];
			_quad(st,
				Vector3(x0 + lx0, _vertex_height(levels, cx, cz, lx0, lz0), z0 + lz0),
				Vector3(x0 + lx1, _vertex_height(levels, cx, cz, lx1, lz0), z0 + lz0),
				Vector3(x0 + lx1, _vertex_height(levels, cx, cz, lx1, lz1), z0 + lz1),
				Vector3(x0 + lx0, _vertex_height(levels, cx, cz, lx0, lz1), z0 + lz1));

# A boundary vertex is owned by 2 or 4 cells. Taking all adjacent cells into
# account guarantees they emit the exact same position and prevents cracks.
static func _vertex_height(levels: Array, cx: int, cz: int, x: float, z: float) -> float:
	var x_cells = [[cx, x]];
	var z_cells = [[cz, z]];
	if is_zero_approx(x):
		x_cells.append([cx - 1, CELL_SIZE]);
	elif is_equal_approx(x, CELL_SIZE):
		x_cells.append([cx + 1, 0.0]);
	if is_zero_approx(z):
		z_cells.append([cz - 1, CELL_SIZE]);
	elif is_equal_approx(z, CELL_SIZE):
		z_cells.append([cz + 1, 0.0]);
	var h = -INF;
	for x_cell in x_cells:
		for z_cell in z_cells:
			var candidate_cx: int = x_cell[0];
			var candidate_cz: int = z_cell[0];
			if candidate_cx < 0 or candidate_cx >= levels[0].size() \
					or candidate_cz < 0 or candidate_cz >= levels.size():
				continue;
			var candidate_level: int = levels[candidate_cz][candidate_cx];
			h = maxf(h, _cell_height(levels, candidate_cx, candidate_cz,
				candidate_level, x_cell[1], z_cell[1]));
	return h;

static func _cell_height(levels: Array, cx: int, cz: int, lvl: int, x: float, z: float) -> float:
	var h = lvl * LEVEL_HEIGHT;
	var max_x = levels[0].size() - 1;
	var max_z = levels.size() - 1;
	var neighbors = [
		[levels[maxi(cz - 1, 0)][cx], z],
		[levels[cz][mini(cx + 1, max_x)], CELL_SIZE - x],
		[levels[mini(cz + 1, max_z)][cx], CELL_SIZE - z],
		[levels[cz][maxi(cx - 1, 0)], x]];
	for neighbor in neighbors:
		var level_diff: int = neighbor[0] - lvl;
		var ramp_width = level_diff * RAMP_WIDTH;
		if level_diff > 0 and neighbor[1] < ramp_width:
			h = maxf(h, neighbor[0] * LEVEL_HEIGHT - neighbor[1] / RAMP_WIDTH * LEVEL_HEIGHT);
	return h;

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, c, b);
	_tri(st, a, d, c);

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal = (b - a).cross(c - a).normalized();
	if normal.y < 0.0:
		var swap = b;
		b = c;
		c = swap;
		normal = -normal;
	for v in [a, b, c]:
		st.set_uv(Vector2(v.x, v.z) / CHUNK_SIZE);
		st.set_normal(normal);
		st.add_vertex(v);

static func get_height(levels: Array, x: float, z: float) -> float:
	var cx = clampi(int(x / CELL_SIZE) + 1, 1, CELLS);
	var cz = clampi(int(z / CELL_SIZE) + 1, 1, CELLS);
	var x0 = (cx - 1) * CELL_SIZE;
	var z0 = (cz - 1) * CELL_SIZE;
	var local_x = x - x0;
	var local_z = z - z0;
	var cuts = [0.0, RAMP_WIDTH, RAMP_WIDTH * 2.0,
		CELL_SIZE - RAMP_WIDTH * 2.0, CELL_SIZE - RAMP_WIDTH, CELL_SIZE];
	cuts.sort();
	var unique_cuts: Array[float] = [];
	for cut in cuts:
		if unique_cuts.is_empty() or not is_equal_approx(unique_cuts.back(), cut):
			unique_cuts.append(cut);
	var ix = _cut_index(unique_cuts, local_x);
	var iz = _cut_index(unique_cuts, local_z);
	var lx0: float = unique_cuts[ix];
	var lx1: float = unique_cuts[ix + 1];
	var lz0: float = unique_cuts[iz];
	var lz1: float = unique_cuts[iz + 1];
	var h00 = _vertex_height(levels, cx, cz, lx0, lz0);
	var h10 = _vertex_height(levels, cx, cz, lx1, lz0);
	var h11 = _vertex_height(levels, cx, cz, lx1, lz1);
	var h01 = _vertex_height(levels, cx, cz, lx0, lz1);
	var u = inverse_lerp(lx0, lx1, local_x);
	var v = inverse_lerp(lz0, lz1, local_z);
	# Match the a-c diagonal used by _quad().
	if v <= u:
		return h00 + u * (h10 - h00) + v * (h11 - h10);
	return h00 + v * (h01 - h00) + u * (h11 - h01);

static func _cut_index(cuts: Array[float], value: float) -> int:
	for i in cuts.size() - 1:
		if value <= cuts[i + 1]:
			return i;
	return cuts.size() - 2;

# Snaps a walking entity to the terrain when a heightfield chunk is under
# it. Ignored over cities/interiors or when standing on furniture.
static func snap(entity: Node3D) -> void:
	var map = entity.get_tree().get_first_node_in_group("game_map");
	if map == null:
		return;
	var h = map.get_ground_height(entity.global_position.x, entity.global_position.z);
	if h != null and abs(entity.global_position.y - h) < SNAP_BAND:
		entity.global_position.y = h;
