extends Control
class_name AskBuyDialog

@onready var _indicator_left: TextureRect = $AskContainer/IndicatorLeft;
@onready var _indicator_right: TextureRect = $AskContainer/IndicatorRight;
@onready var _ask_label: Label = $AskContainer/AskLabel;
@onready var _name_label: Label = $AskContainer/NameContainer/NameLabel

signal close_modal(result: bool);

var modal_on_left: bool = false;
var ask_translation: String;
var name_translation: String;

func _ready():
	_indicator_left.visible = modal_on_left;
	_indicator_right.visible = !modal_on_left;
	_ask_label.text = ask_translation;
	_name_label.text = name_translation;

func close_parent_modal(result: bool):
	close_modal.emit(result);

