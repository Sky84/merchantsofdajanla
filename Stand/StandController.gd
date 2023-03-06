extends Posable

@onready var _container: PosableContainer = $Container;
@onready var sprite_item_3d: Sprite3D = $Sprite3D;
@onready var animation_player = $AnimationPlayer

func _init_posable(_owner: String):
	super._init_posable(_owner);
	_container.register_container(id, _owner);
	InventoryEvents.item_in_container_selected.connect(_on_item_container_clicked);

func _on_item_container_clicked(mouse_item: Dictionary) -> void:
	var item = MarketController.get_first_item(_container.container_id);
	if item:
		sprite_item_3d.texture = load(item.icon_path);
		animation_player.play("floating");
	else:
		sprite_item_3d.texture = null;

func interact(_interract_owner_id: String) -> void:
	print("_container_owner: "+_container._container_owner);
	print("_interract_owner_id: "+_interract_owner_id);
	if _is_interact_from_owner(_interract_owner_id):
		HudEvents.open_stand.emit(_container.container_id);
	else:
		print('buy from _interract_owner_id:'+ _interract_owner_id);
