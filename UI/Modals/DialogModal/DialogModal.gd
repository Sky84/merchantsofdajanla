extends BaseModal
class_name AskDialog

const ASK_MAX_WIDTH := 300.0;
const ASK_PADDING := Vector2(25, 23);
const NAME_PADDING := Vector2(24, 8);
const ANSWERS_GAP := 8.0;
const SIDE_GAP := 24.0;
const PORTRAIT_SIZE := 28.0;
const PORTRAIT_GAP := 6.0;
const HEAD_REGION := Rect2i(7, 0, 18, 22);
const HEAD_WORLD_OFFSET := Vector3(0, 1.25, 0);
const PORTRAIT_PARTS := ["SkinsAnimatedSprite3D", "PantsAnimatedSprite3D", "ShirtsAnimatedSprite3D", "HairsAnimatedSprite3D"];

@onready var _indicator_left: TextureRect = $AskContainer/IndicatorLeft;
@onready var _indicator_right: TextureRect = $AskContainer/IndicatorRight;
@onready var _ask_container: NinePatchRect = $AskContainer;
@onready var _ask_label: Label = $AskContainer/AskLabel;
@onready var _name_container: NinePatchRect = $AskContainer/NameContainer;
@onready var _name_label: Label = $AskContainer/NameContainer/NameLabel;
@onready var _answers_container = $AnswersContainer;

var _answer_scene: PackedScene = preload("res://UI/Modals/DialogModal/answer.tscn");

signal close_modal();

var modal_on_left = null;
var ask_translation: String;
var name_translation: String;
var answers: Array;
var speaker_alive;

var _speaker_anchor: Vector2;
var _portrait: Control;
var _answers_w := 0.0;
var _fitted := false;

func _ready():
	_speaker_anchor = global_position;
	position = Vector2.ZERO;
	_ask_label.text = ask_translation;
	_name_label.text = name_translation;
	_portrait = Control.new();
	_portrait.name = "Portrait";
	_portrait.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE);
	_name_container.add_child(_portrait);
	if speaker_alive != null and is_instance_valid(speaker_alive):
		for head_tex in _build_portrait_textures(speaker_alive):
			var tex_rect = TextureRect.new();
			tex_rect.texture = head_tex;
			tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT);
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED;
			_portrait.add_child(tex_rect);
	if _portrait.get_child_count() == 0:
		_portrait.visible = false;
	_ask_container.modulate.a = 0;
	_answers_container.modulate.a = 0;
	for answer in answers:
		var answer_instance: ModalAnswer = _answer_scene.instantiate();
		answer_instance._ask_dialog = self;
		answer_instance._callback = answer.callback if answer.has('callback') else Callable();
		answer_instance.text = answer.text;
		answer_instance.dialog_node_id = answer.dialog_node_id if answer.has('dialog_node_id') else '';
		_answers_container.add_child(answer_instance);
	call_deferred("_fit_to_content");

func _fit_to_content() -> void:
	var tree = get_tree();
	_ask_label.autowrap_mode = TextServer.AUTOWRAP_OFF;
	await tree.process_frame;
	if not is_instance_valid(self):
		return;
	var content_w = min(_ask_label.get_combined_minimum_size().x, ASK_MAX_WIDTH - ASK_PADDING.x);
	_ask_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;
	_ask_label.custom_minimum_size.x = content_w;
	await tree.process_frame;
	if not is_instance_valid(self):
		return;
	_ask_container.size = Vector2(content_w, _ask_label.get_combined_minimum_size().y) + ASK_PADDING;
	_place_dialog(_get_speaker_screen_position());
	_indicator_left.offset_left = -35;
	_indicator_left.offset_right = 5;
	_indicator_left.offset_bottom = 15;
	_indicator_left.offset_top = -25;
	_indicator_right.offset_left = -_ask_container.size.x - 5;
	_indicator_right.offset_right = -_ask_container.size.x + 35;
	_indicator_right.offset_bottom = 15;
	_indicator_right.offset_top = -25;
	var portrait_w = (PORTRAIT_SIZE + PORTRAIT_GAP) if _portrait.visible else 0.0;
	_name_container.size = Vector2(_name_label.get_combined_minimum_size().x + portrait_w + NAME_PADDING.x, max(_name_label.get_combined_minimum_size().y, PORTRAIT_SIZE) + NAME_PADDING.y);
	_name_container.position = Vector2(13, -_name_container.size.y - 4);
	_portrait.position = Vector2(8, (_name_container.size.y - PORTRAIT_SIZE) / 2);
	_name_label.offset_left = portrait_w;
	for answer in _answers_container.get_children():
		answer.forced_min_width = _ask_container.size.x;
		if answer.custom_minimum_size.x < _ask_container.size.x:
			answer.custom_minimum_size.x = _ask_container.size.x;
	for answer in _answers_container.get_children():
		_answers_w = max(_answers_w, answer.custom_minimum_size.x);
	_fitted = true;
	_place_dialog(_get_speaker_screen_position());
	_ask_container.modulate.a = 1;
	_answers_container.modulate.a = 1;

func _process(_delta) -> void:
	if _fitted and is_inside_tree() and speaker_alive != null and is_instance_valid(speaker_alive):
		_place_dialog(_get_speaker_screen_position());

func _place_dialog(head_screen_pos: Vector2) -> void:
	var on_left = modal_on_left if modal_on_left != null else head_screen_pos.x > size.x / 2;
	var panel_x = head_screen_pos.x - SIDE_GAP - _ask_container.size.x if on_left else head_screen_pos.x + SIDE_GAP;
	panel_x = clamp(panel_x, 8.0, size.x - _ask_container.size.x - 8.0);
	_ask_container.position = Vector2(panel_x, head_screen_pos.y - _ask_container.size.y + 4);
	_indicator_left.visible = on_left;
	_indicator_right.visible = !on_left;
	var target_pos = _ask_container.position + Vector2((_ask_container.size.x - _answers_w) / 2, _ask_container.size.y + ANSWERS_GAP);
	_answers_container.offset_right = target_pos.x - size.x + _answers_w;
	_answers_container.offset_bottom = target_pos.y - size.y + _answers_container.size.y;
	_answers_container.offset_left = target_pos.x - size.x;
	_answers_container.offset_top = target_pos.y - size.y;

func _get_speaker_screen_position() -> Vector2:
	if is_inside_tree() and speaker_alive != null and is_instance_valid(speaker_alive):
		var cam = get_viewport().get_camera_3d();
		if cam != null:
			return cam.unproject_position(speaker_alive.global_position + HEAD_WORLD_OFFSET);
	return _speaker_anchor;

func _build_portrait_textures(alive) -> Array:
	var textures = [];
	var cloth = alive.get_node_or_null("ClothAnimations");
	if cloth == null:
		return textures;
	for part_name in PORTRAIT_PARTS:
		var spr = cloth.get_node_or_null(part_name);
		if spr == null or spr.sprite_frames == null:
			continue;
		var anim = spr.animation if spr.animation != &"" else &"idle";
		var tex = spr.sprite_frames.get_frame_texture(anim, spr.frame);
		if tex == null:
			continue;
		var head_tex = AtlasTexture.new();
		if tex is AtlasTexture:
			head_tex.atlas = tex.atlas;
			head_tex.region = Rect2(tex.region.position + Vector2(HEAD_REGION.position), Vector2(HEAD_REGION.size));
		else:
			head_tex.atlas = tex;
			head_tex.region = Rect2(HEAD_REGION);
		textures.append(head_tex);
	return textures;

func close_parent_modal(last_node_id: String):
	close_modal.emit();
	HudEvents.close_modal.emit(id, last_node_id);

