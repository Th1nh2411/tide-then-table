class_name PoiDialog
extends CanvasLayer
## Small talk box for places on the map (shrine, hut, lighthouse, raft).
## `ask()` pauses the game, shows a title, a text and numbered options, and
## returns the chosen index (-1 = closed with Esc / E). Built in code.
## Put it after PauseMenu/HoldUI and before PhoneApp in the scene tree.
## Look: a pinned paper note ("PaperPanel", a little crooked), the place's
## icon + name in red ink, answers as paper price tags with number key caps
## and an icon picked from their words (leave, money, fire...).

## Title word -> icon of the place.
const PLACE_ICONS := {"Miếu": "sparkles", "Hải đăng": "lamp", "Chòi": "house", "Bè": "basket",
	"Ghe": "boat", "Chai": "info"}
## Answer word -> icon (first match wins); answers without one get none.
const ANSWER_ICONS := {"Đi tiếp": "leave", "Ừ": "check", "Bán": "money", "nhang": "fire",
	"Kéo": "anchor", "Đọc": "info", "Hỏi": "help", "Mua": "cart", "Rung": "sparkles"}

signal _answered(index: int)

@export var panel_width: float = 380.0

var _opened_pause: bool = false
var _option_count: int = 0

var _title: Label
var _body: Label
var _options: VBoxContainer
var _hint: Label
var _keys: HBoxContainer
var _panel: PanelContainer
var _portrait: TextureRect
var _title_icon: TextureRect


func _ready() -> void:
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	hide()


func is_open() -> bool:
	return visible


## Shows the dialog and waits for a choice. Options are shown as "1. ...".
func ask(title: String, body: String, options: PackedStringArray, speaker_id: String = "") -> int:
	_title.text = title
	_title_icon.texture = UiIcons.sticker(_icon_for(title, PLACE_ICONS, "map"), 14, Color("a53030"))
	_body.text = body
	_portrait.texture = Art.texture("portraits/%s/base" % speaker_id) if speaker_id != "" else null
	_portrait.visible = _portrait.texture != null
	_panel.custom_minimum_size.x = minf(panel_width + 264.0, get_viewport().get_visible_rect().size.x - 24.0) \
		if _portrait.visible else panel_width
	for child in _options.get_children():
		child.queue_free()
	for i in options.size():
		var button := _option_button(i, options[i])
		_options.add_child(button)
		for state: String in ["normal", "hover", "pressed", "hover_pressed"]:  # room for the key cap
			button.add_theme_stylebox_override(state, _with_left_room(button.get_theme_stylebox(state)))
	_option_count = options.size()
	_keys.visible = GameState.is_first_day()
	_opened_pause = not get_tree().paused
	get_tree().paused = true
	show()
	_play_fx()
	var index: int = await _answered
	hide()
	if _opened_pause:
		get_tree().paused = false
	return index


## Slides the note in once the centre container has placed it.
func _play_fx() -> void:
	_panel.modulate.a = 0.0
	await get_tree().process_frame
	UiFx.tilt(_panel, 0.0)  # text-heavy: crooked pixels break the letters
	UiFx.settle(_panel, Vector2(0, -20), 0.0, -5.0)
	UiFx.stagger(_options, 0.05, 0.15)


static func _icon_for(text: String, table: Dictionary, fallback: String) -> String:
	for word: String in table:
		if text.contains(word):
			return str(table[word])
	return fallback


## Paper price-tag answer: number key cap, then an icon, then the words.
func _option_button(index: int, text: String) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"PaperButton"
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.custom_minimum_size.x = 120
	button.add_theme_font_size_override("font_size", 10)
	var icon := _icon_for(text, ANSWER_ICONS, "")
	if icon != "":
		UiIcons.dress(button, icon, 12, Color("090a14"))
	button.add_theme_constant_override("h_separation", 5)
	button.pressed.connect(_answered.emit.bind(index))
	var key := Label.new()
	key.theme_type_variation = &"KeyLabel"
	key.text = str(index + 1)
	key.add_theme_font_size_override("font_size", 8)
	key.position = Vector2(5, 4)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(key)
	UiFx.hover_lift(button, 0.03)
	return button


## Copy of a button frame with room on the left for the key cap.
static func _with_left_room(box: StyleBox) -> StyleBox:
	var copy := box.duplicate() as StyleBox
	copy.content_margin_left = 22.0
	return copy


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_answered.emit(-1)
	elif event is InputEventKey and event.is_pressed() and not event.is_echo():
		var index: int = (event as InputEventKey).physical_keycode - KEY_1
		if index >= 0 and index < _option_count:
			get_viewport().set_input_as_handled()
			_answered.emit(index)


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.035, 0.04, 0.08, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"PaperPanel"
	_panel.custom_minimum_size = Vector2(panel_width, 0)
	center.add_child(_panel)
	_panel.draw.connect(func() -> void:  # pinned to the night
		UiStickers.draw(_panel, "pin", Vector2(_panel.size.x * 0.5, 3)))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 6)
	_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(256, 256)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Source faces right, toward the text beside it.
	_portrait.hide()
	row.add_child(_portrait)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	row.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 4)
	box.add_child(head)
	_title_icon = UiIcons.make("map", 14, Color("a53030"))
	head.add_child(_title_icon)
	_title = Label.new()
	_title.theme_type_variation = &"HeadingLabel"
	_title.add_theme_font_size_override("font_size", 13)
	head.add_child(_title)
	_body = Label.new()
	_body.theme_type_variation = &"InkLabel"
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("font_size", 10)
	box.add_child(_body)
	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 3)
	box.add_child(_options)
	# First day only: key caps instead of a sentence.
	var keys := HBoxContainer.new()
	keys.add_theme_constant_override("separation", 3)
	keys.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(keys)
	for cap: String in ["1-3", "E", "Esc"]:
		var key := Label.new()
		key.theme_type_variation = &"KeyLabel"
		key.text = cap
		key.add_theme_font_size_override("font_size", 8)
		keys.add_child(key)
		if cap == "1-3":
			keys.add_child(UiIcons.make("mouse", 10, Color("394a50")))
	keys.add_child(UiIcons.make("leave", 10, Color("394a50")))
	_hint = Label.new()  # kept for callers / tests; the key caps say it
	_hint.text = "Phím số / click để chọn · E / Esc: đi tiếp"
	_hint.visible = false
	keys.set_meta("hint", _hint)
	box.add_child(_hint)
	_keys = keys
