extends Node

const SLOT_NODES := {"shirt": "ShirtsAnimatedSprite3D", "pants": "PantsAnimatedSprite3D", "weapon": "WeaponsAnimatedSprite3D"};
const SLOTS := ["shirt", "pants", "weapon"];
const DEFAULT_ITEMS := {"shirt": "shirt_basic", "pants": "pants_basic", "weapon": "sword_basic"};
var _equipped := {};
var _equipment_cid := "";

@onready var _player = get_parent();
@onready var _cloth = _player.get_node("ClothAnimations");

func _ready() -> void:
	PlayerEvents.equip_item_requested.connect(func(item_id): equip(item_id));
	for slot in SLOT_NODES:
		var layer = _cloth.get_node_or_null(SLOT_NODES[slot]);
		if layer != null and layer.sprite_frames != null:
			_equipped[slot] = DEFAULT_ITEMS[slot];
	ContainersController.on_registered_container.connect(_on_container_registered);
	var cid = _cid();
	if ContainersController.containers.has(cid):
		_on_container_registered(cid);
	InventoryEvents.container_data_changed.connect(_on_container_data_changed);

func _cid() -> String:
	return _equipment_cid if not _equipment_cid.is_empty() else "equipment_" + _player._owner_id;

func _on_container_registered(cid: String) -> void:
	if cid != _cid():
		return;
	_equipment_cid = cid;
	# keep equipment cells out of the player's storage lookups
	ContainersController.containers[cid].container_owner = _player._owner_id + "_equipment";
	var slots = ContainersController.get_container_data(_equipment_cid);
	for i in SLOTS.size():
		if slots[i][0].is_empty() and _equipped.has(SLOTS[i]):
			var item = GameItems.get_item(_equipped[SLOTS[i]]);
			item.amount = 1;
			slots[i][0] = item;
	InventoryEvents.container_data_changed.emit(_equipment_cid);
	ContainersController.on_registered_container.disconnect(_on_container_registered);

func _on_container_data_changed(cid: String) -> void:
	if cid == _equipment_cid:
		_sync_from_container();

func _sync_from_container() -> void:
	if _equipment_cid.is_empty() or not ContainersController.containers.has(_equipment_cid):
		return;
	var slots = ContainersController.get_container_data(_equipment_cid);
	var storage_ids = ContainersController.get_container_ids_by_owner_id(_player._owner_id);
	var changed = false;
	for i in SLOTS.size():
		var slot = SLOTS[i];
		var cell = slots[i][0];
		var layer = _cloth.get_node_or_null(SLOT_NODES[slot]);
		if layer == null:
			continue;
		if cell.is_empty():
			if _equipped.has(slot):
				layer.visible = false;
				_equipped.erase(slot);
				changed = true;
			continue;
		var data = GameItems._items.get(cell.id);
		if data != null and data.get("type") == "Equipment" and data.get("slot") == slot:
			if _equipped.get(slot) != cell.id:
				layer.sprite_frames = load(data["sprite_frames"]);
				layer.visible = true;
				_equipped[slot] = cell.id;
				changed = true;
		else:
			ContainersController.add_item(storage_ids, cell.id, cell.amount);
			slots[i][0] = {};
			InventoryEvents.container_data_changed.emit(_equipment_cid);
			return;
	if changed:
		PlayerEvents.equipment_changed.emit();

func equip(item_id: String) -> void:
	var item = GameItems._items.get(item_id);
	if item == null or item.get("type") != "Equipment" or not item.has("slot"):
		return;
	var cid = _cid();
	if cid.is_empty() or not ContainersController.containers.has(cid):
		return;
	var slot = item["slot"];
	if not SLOT_NODES.has(slot) or _cloth.get_node_or_null(SLOT_NODES[slot]) == null:
		return;
	var storage_ids = ContainersController.get_container_ids_by_owner_id(_player._owner_id);
	var slots = ContainersController.get_container_data(cid);
	var x = SLOTS.find(slot);
	if not slots[x][0].is_empty():
		ContainersController.add_item(storage_ids, slots[x][0].id, slots[x][0].amount);
	var cell = GameItems.get_item(item_id);
	cell.amount = 1;
	slots[x][0] = cell;
	ContainersController.remove_item(storage_ids, item_id, 1);
	InventoryEvents.container_data_changed.emit(cid);

func unequip(slot: String) -> void:
	var cid = _cid();
	if cid.is_empty() or not SLOTS.has(slot) or not _has_empty_slot():
		return;
	var x = SLOTS.find(slot);
	var slots = ContainersController.get_container_data(cid);
	var cell = slots[x][0];
	if cell.is_empty():
		return;
	slots[x][0] = {};
	ContainersController.add_item(ContainersController.get_container_ids_by_owner_id(_player._owner_id), cell.id, cell.amount);
	InventoryEvents.container_data_changed.emit(cid);

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
