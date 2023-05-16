extends Action
class_name EatAction

func execute(params: Dictionary) -> void:
	var _owner_id: String = params._owner_id;
	var consume_callback: Callable = params.consume_callback;
	var fallback_callback: Callable = params.fallback_callback;

	var items_target: Array[Dictionary] = GameItems.get_items_by_subtype(target);
	var container_ids: Array[String] = ContainersController.get_container_ids_by_owner_id(_owner_id);
	var item_to_eat = items_target.map(
		func(item: Dictionary):
			return ContainersController.find_item_in_containers(container_ids, item.id)
	)[0];
	if !item_to_eat.is_empty():
		consume_callback.call(item_to_eat.item);
	else:
		fallback_callback.call(fallback);
	on_action_finished.emit(id, null);
