extends Node

func get_mesh_in_child(parent_node: Node3D) -> MeshInstance3D:
	var meshes = parent_node.find_children("*", "MeshInstance3D", true, false);
	if not meshes.is_empty():
		return meshes[0];
	printerr("PlayerMouseAction::_get_mesh_in_child:: no mesh in:");
	parent_node.print_tree_pretty();
	return;

func get_map_item_id(map_item: MapItem) -> String:
	var map_id = PackedStringArray([map_item.name, map_item.position.x, map_item.position.y, map_item.position.z])
	return '_'.join(map_id);

func get_random_reachable_point(nav_mesh: NavigationMesh, navigation_agent: NavigationAgent3D, gridmap_controller: GridMapController):
	if nav_mesh and nav_mesh.get_polygon_count() > 0:
		# Récupérer les sommets du maillage de navigation
		var vertices = nav_mesh.get_vertices();
		
		# Trouver les limites du maillage en parcourant tous les sommets
		var minX = INF;
		var maxX = -INF;
		var minZ = INF;
		var maxZ = -INF;
		
		for vertex in vertices:
			minX = min(minX, vertex.x);
			maxX = max(maxX, vertex.x);
			minZ = min(minZ, vertex.z);
			maxZ = max(maxZ, vertex.z);
		
		var bounds = AABB(Vector3(minX, 0, minZ), Vector3(maxX, 0, maxZ));

		# Tant que le point aléatoire n'est pas atteignable, continuer à en générer un nouveau
		while true:
			# Générer un point aléatoire à l'intérieur des limites rectangulaires
			var random_point = Vector3(
				randi_range(bounds.position.x, bounds.position.x + bounds.size.x),
				0,
				randi_range(bounds.position.z, bounds.position.z + bounds.size.z)
			);
			var map_point = gridmap_controller.global_to_local(random_point);
			var cell_item = gridmap_controller.get_cell_item(map_point);
			if cell_item == 0:
				print(map_point);
				print(random_point)
				return random_point;
