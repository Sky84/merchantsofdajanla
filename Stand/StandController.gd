extends Posable

@onready var _container: PosableContainer = $Container;
@onready var _sprite_item_3d: Sprite3D = $Sprite3D;
@onready var _animation_player = $AnimationPlayer;
@onready var _price_label_3d = $PriceLabel3D;
@onready var _camera = get_node("/root/Root/Game/Camera3D");

func _ready():
	super._ready();
	_price_label_3d.visible = false;

func _init_posable(__owner: String):
	await super._init_posable(__owner);
	_container.register_container(id, __owner);
	InventoryEvents.item_in_container_selected.connect(_on_item_container_changed);
	HudEvents.price_item_changed.connect(_on_item_container_changed);

func _on_item_container_changed(_mouse_item: Dictionary) -> void:
	var item = MarketController.get_first_item(_container.container_id);
	if item:
		_price_label_3d.text = str(item.current_price);
		_price_label_3d.position.x = 0.1 * (_price_label_3d.text.length());
		_sprite_item_3d.texture = load(item.icon_path);
		_animation_player.play("floating");
		_price_label_3d.visible = true;
	else:
		_sprite_item_3d.texture = null;
		_price_label_3d.visible = false;

func interact(_interract_owner_id: String) -> void:
	print("_container_owner: "+_container._container_owner);
	print("_interract_owner_id: "+_interract_owner_id);
	var screen_position: Vector2 = _camera.unproject_position(global_position) - Vector2(64,80);
	if _is_interact_from_owner(_interract_owner_id):
		HudEvents.open_stand_setup.emit(_container.container_id, screen_position);
	else:
		print('buy from _interract_owner_id:'+ _interract_owner_id);
		HudEvents.open_stand_transaction.emit(_container.container_id, _interract_owner_id, screen_position);
