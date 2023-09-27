extends Action
class_name EatAction


func execute(params: Dictionary) -> void:
	var _owner_id: String = params._owner_id;
	var consume_callback: Callable = params.consume;

	var items_target: Array[Dictionary] = GameItems.get_items_by_subtype(target);
	var container_ids: Array[String] = ContainersController.get_container_ids_by_owner_id(_owner_id);
	var item_to_eat = items_target.map(
		func(item: Dictionary):
			return ContainersController.find_item_in_containers(container_ids, item.id)
	)[0];
	var next_action = null;
	if !item_to_eat.is_empty():
		print(_owner_id, ' is eating ', item_to_eat.item.name);
		consume_callback.call(item_to_eat.item);
	else:
		next_action = await Actions.get_action_by_id(Actions.BUY);
	on_action_finished.emit(id, _owner_id, next_action);
