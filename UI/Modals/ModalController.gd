extends Node
class_name ModalController

var _modal_container: Node;

var _modals : Array[String] = [];

var has_modal: bool:
	get:
		return !_modals.is_empty();
  
func _init(modal_container: Node):
	_modal_container = modal_container;
	_modal_container.hide();

# Add the modal if it's not already in the _modals container
func register_modal(path_node_to_instance: String, params: Dictionary) -> void:
	if !_modals.has(params.id):
		var instance = load(path_node_to_instance).instantiate();
		var instance_id = params.id;
		_modals.push_back(instance_id);
		for param in params:
			instance[param] = params[param];
		_modal_container.add_child(instance);
		_modal_container.show();
		var _result = await instance.close_modal;
		_remove_modal(instance_id, instance);

func _remove_modal(instance_id: String, instance: Variant) -> void:
	var idx = _modals.find(instance_id);
	assert(idx != -1, 'Modal with id ' + instance_id + ' not found');
	_modals.remove_at(idx);
	_modal_container.remove_child(instance);
	if (_modals.is_empty()):
		_modal_container.hide();
