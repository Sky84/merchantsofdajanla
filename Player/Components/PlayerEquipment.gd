extends Node

const SLOT_NODES := {"shirt": "ShirtsAnimatedSprite3D", "pants": "PantsAnimatedSprite3D", "weapon": "WeaponsAnimatedSprite3D"};
const DEFAULT_ITEMS := {"shirt": "shirt_basic", "pants": "pants_basic", "weapon": "sword_basic"};
var _equipped := {};

@onready var _player = get_parent();
@onready var _cloth = _player.get_node("ClothAnimations");

func _ready() -> void:
	PlayerEvents.equip_item_requested.connect(func(item_id): equip(item_id));
	for slot in SLOT_NODES:
		var layer = _cloth.get_node_or_null(SLOT_NODES[slot]);
		if layer != null and layer.sprite_frames != null:
			_equipped[slot] = DEFAULT_ITEMS[slot];

func equip(item_id: String) -> void:
	var item = GameItems._items.get(item_id);
	if item == null or item.get("type") != "Equipment" or not item.has("slot"):
		return;
	var slot = item["slot"];
	var layer = _cloth.get_node_or_null(SLOT_NODES[slot]);
	if layer == null:
		return;
	if _equipped.has(slot):
		unequip(slot);
	layer.sprite_frames = load(item["sprite_frames"]);
	layer.visible = true;
	_equipped[slot] = item_id;
	var container_ids = ContainersController.get_container_ids_by_owner_id(_player._owner_id);
	if not ContainersController.find_item_in_containers(container_ids, item_id).is_empty():
		ContainersController.remove_item(container_ids, item_id, 1);
	PlayerEvents.equipment_changed.emit();

func unequip(slot: String) -> void:
	if not _equipped.has(slot) or not _has_empty_slot():
		return;
	var item_id = _equipped[slot];
	_cloth.get_node_or_null(SLOT_NODES[slot]).visible = false;
	_equipped.erase(slot);
	ContainersController.add_item(ContainersController.get_container_ids_by_owner_id(_player._owner_id), item_id, 1);
	PlayerEvents.equipment_changed.emit();

func _has_empty_slot() -> bool:
	for cid in ContainersController.get_container_ids_by_owner_id(_player._owner_id):
		var slots = ContainersController.get_container_data(cid);
		for x in slots:
			for y in slots[x]:
				if slots[x][y].is_empty():
					return true;
	return false;

func is_equipped(slot: String) -> bool:
	return _equipped.has(slot);

func get_equipped_item(slot: String) -> Dictionary:
	return GameItems._items.get(_equipped.get(slot, ""), {});
