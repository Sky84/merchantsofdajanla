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

func get_random_reachable_point(nav_mesh: NavigationMesh, navigation_agent: NavigationAgent3D):
	if nav_mesh and nav_mesh.get_polygon_count() > 0:
		# Récupérer les sommets du maillage de navigation
		var vertices = nav_mesh.get_vertices();
		
		# Trouver les limites du maillage en parcourant tous les sommets
		var minX = INF;
		var maxX = -INF;
		var minY = INF;
		var maxY = -INF;
		var minZ = INF;
		var maxZ = -INF;
		
		for vertex in vertices:
			minX = min(minX, vertex.x);
			maxX = max(maxX, vertex.x);
			minY = min(minY, vertex.y);
			maxY = max(maxY, vertex.y);
			minZ = min(minZ, vertex.z);
			maxZ = max(maxZ, vertex.z);
		
		var bounds = AABB(Vector3(minX, minY, minZ), Vector3(maxX, maxY, maxZ));

		# Tant que le point aléatoire n'est pas atteignable, continuer à en générer un nouveau
		while true:
			# Générer un point aléatoire à l'intérieur des limites rectangulaires
			var random_point = Vector3(
				randi_range(bounds.position.x, bounds.position.x + bounds.size.x),
				0,
				randi_range(bounds.position.z, bounds.position.z + bounds.size.z)
			);
			
			var space_state = get_tree().current_scene.get_world_3d().direct_space_state
			# use global coordinates, not local to node
			# TODO: fix randompoint raycast 
			var query = PhysicsRayQueryParameters3D.create(random_point-Vector3(0, 1, 0),\
						random_point+Vector3(0, 1, 0), 2)
			var result = space_state.intersect_ray(query)
			if !result.is_empty():
				# TODO: return randompoint
				print(result.collider);
