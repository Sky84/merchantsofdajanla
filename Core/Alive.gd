extends CharacterBody3D
class_name Alive

@export var MAX_HEALTH: int = 100;
@export var MAX_HUNGER: int = 100;

@export var _owner_id: String;

var _alive_status: Dictionary = {
	"health": {"value": MAX_HEALTH, "max": MAX_HEALTH},
	"hunger": {"value": MAX_HUNGER, "max": MAX_HUNGER}
};

func consume(_item: Dictionary):
	var success = false;
	for effect_key in _item.effects:
		if effect_key in _alive_status:
			var _alive_stat = _alive_status[effect_key];
			_alive_stat.value = clampi(_item.effects[effect_key], 0, _alive_stat.max);
			success = true;
			NotificationEvents.notify\
				.emit(NotificationEvents.NotificationType.SUCCESS, 'CONSOMABLE.SUCCESS_CONSUME_'+effect_key.to_upper());
	if success:
		var container_ids = ContainersController.get_container_ids_by_owner_id(_owner_id);
		ContainersController.remove_item(container_ids, _item.id, 1);
		for container_id in container_ids:
			InventoryEvents.container_data_changed.emit(container_id);
