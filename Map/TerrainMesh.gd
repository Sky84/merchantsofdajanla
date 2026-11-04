class_name TerrainMesh

const CELL_SIZE := 8.0;
const CELLS := 8;
const LEVEL_HEIGHT := 0.8;
const RAMP_WIDTH := 2.0; # fixed slope: every ramp is RAMP_WIDTH wide, one angle
const SNAP_BAND := 2.2;
const CHUNK_SIZE := 64.0;

# city edge bitmask: 1=N(-z) 2=E(+x) 4=S(+z) 8=W(-x)
static func build(chunk, noise: FastNoiseLite, city_edges: int = 0) -> void:
	var levels = _levels(chunk.global_position, noise);
	_flatten_city_borders(levels, city_edges);
	_cap_level_diffs(levels);
	var st = SurfaceTool.new();
	st.begin(Mesh.PRIMITIVE_TRIANGLES);
	for cz in range(1, CELLS + 1):
		for cx in range(1, CELLS + 1):
			_emit_cell(st, levels, cx, cz);
	st.generate_normals();
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
			var near_city = (city_edges & 1 and cz <= 2) or (city_edges & 2 and cx >= CELLS) \
				or (city_edges & 4 and cz >= CELLS) or (city_edges & 8 and cx <= 2);
			if near_city:
				levels[cz][cx] = 0;

static func _cap_level_diffs(levels: Array) -> void:
	for _pass in 4:
		for cz in range(1, CELLS + 1):
			for cx in range(1, CELLS + 1):
				for d in [[0, -1], [1, 0], [0, 1], [-1, 0]]:
					var nl = levels[cz + d[1]][cx + d[0]];
					if levels[cz][cx] - nl > 1:
						levels[cz][cx] = nl + 1;

# Flat cell top + a fixed-angle ramp inside the cell for each side whose
# neighbor is exactly one level higher.
static func _emit_cell(st: SurfaceTool, levels: Array, cx: int, cz: int) -> void:
	var lvl = levels[cz][cx];
	var h = lvl * LEVEL_HEIGHT;
	var x0 = (cx - 1) * CELL_SIZE;
	var z0 = (cz - 1) * CELL_SIZE;
	var x1 = x0 + CELL_SIZE;
	var z1 = z0 + CELL_SIZE;
	_quad(st, Vector3(x0, h, z0), Vector3(x1, h, z0), Vector3(x1, h, z1), Vector3(x0, h, z1));
	var dirs = [[[0, -1], Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(0, 0, RAMP_WIDTH)],
		[[1, 0], Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(-RAMP_WIDTH, 0, 0)],
		[[0, 1], Vector3(x1, 0, z1), Vector3(x0, 0, z1), Vector3(0, 0, -RAMP_WIDTH)],
		[[-1, 0], Vector3(x0, 0, z1), Vector3(x0, 0, z0), Vector3(RAMP_WIDTH, 0, 0)]];
	for d in dirs:
		var edge = d[0];
		if levels[cz + edge[1]][cx + edge[0]] == lvl + 1:
			var a: Vector3 = d[1] + Vector3(0, h + LEVEL_HEIGHT, 0);
			var b: Vector3 = d[2] + Vector3(0, h + LEVEL_HEIGHT, 0);
			var o: Vector3 = d[3];
			_quad(st, a + o - Vector3(0, LEVEL_HEIGHT, 0), b + o - Vector3(0, LEVEL_HEIGHT, 0), b, a);

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, c, b);
	_tri(st, a, d, c);
	_tri(st, a, b, c);
	_tri(st, a, c, d);

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.set_uv(Vector2(a.x, a.z) / CHUNK_SIZE);
	st.add_vertex(a);
	st.set_uv(Vector2(b.x, b.z) / CHUNK_SIZE);
	st.add_vertex(b);
	st.set_uv(Vector2(c.x, c.z) / CHUNK_SIZE);
	st.add_vertex(c);

static func get_height(levels: Array, x: float, z: float) -> float:
	var cx = clampi(int(x / CELL_SIZE) + 1, 1, CELLS);
	var cz = clampi(int(z / CELL_SIZE) + 1, 1, CELLS);
	var lvl = levels[cz][cx];
	var h = lvl * LEVEL_HEIGHT;
	var x0 = (cx - 1) * CELL_SIZE;
	var z0 = (cz - 1) * CELL_SIZE;
	var distances = [[levels[cz][cx - 1], z - z0], [levels[cz][cx + 1], x0 + CELL_SIZE - x],
		[levels[cz + 1][cx], z0 + CELL_SIZE - z], [levels[cz - 1][cx], x - x0]];
	for e in distances:
		if e[0] == lvl + 1 and e[1] < RAMP_WIDTH:
			h = maxf(h, (lvl + 1) * LEVEL_HEIGHT - e[1] / RAMP_WIDTH * LEVEL_HEIGHT);
	return h;

# Snaps a walking entity to the terrain when a heightfield chunk is under
# it. Ignored over cities/interiors or when standing on furniture.
static func snap(entity: Node3D) -> void:
	var map = entity.get_tree().get_first_node_in_group("game_map");
	if map == null:
		return;
	var h = map.get_ground_height(entity.global_position.x, entity.global_position.z);
	if h != null and abs(entity.global_position.y - h) < SNAP_BAND:
		entity.global_position.y = h;
