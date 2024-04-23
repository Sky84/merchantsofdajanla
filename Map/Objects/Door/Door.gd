extends Node3D

signal door_activated(owner_id: String);

func interact(_interract_owner_id: String) -> void:
	door_activated.emit(_interract_owner_id);
