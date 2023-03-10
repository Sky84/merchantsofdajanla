extends Panel

@onready var name_label = $NameLabel
@onready var type_label = $TypeLabel
@onready var description_label = $DescriptionLabel
@onready var icon = $Icon

# Called when the node enters the scene tree for the first time.
func _ready():
	hide();
	name_label.text = "";
	type_label.text = "";
	description_label.text = "";
	icon.texture = null;
	InventoryEvents.show_info_item.connect(open);

func open(item: Dictionary):
	if(!visible):
		show();
	name_label.text = tr(item.name);
	type_label.text = item.type;
	description_label.text = tr(item.description);
	icon.texture = load(item.icon_path);

