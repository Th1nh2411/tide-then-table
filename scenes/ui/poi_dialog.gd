class_name PoiDialog
extends CanvasLayer
## Small talk box for places on the map (shrine, hut, lighthouse, raft).
## `ask()` pauses the game, shows a title, a text and numbered options, and
## returns the chosen index (-1 = closed with Esc / E). Built in code.
## Put it after PauseMenu/HoldUI and before PhoneApp in the scene tree.

signal _answered(index: int)

@export var panel_width: float = 380.0

var _opened_pause: bool = false
var _option_count: int = 0

var _title: Label
var _body: Label
var _options: VBoxContainer
var _hint: Label
var _panel: PanelContainer
var _portrait: TextureRect


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
	_body.text = body
	_portrait.texture = Art.texture("portraits/%s/base" % speaker_id) if speaker_id != "" else null
	_portrait.visible = _portrait.texture != null
	_panel.custom_minimum_size.x = minf(panel_width + 264.0, get_viewport().get_visible_rect().size.x - 24.0) \
		if _portrait.visible else panel_width
	for child in _options.get_children():
		child.queue_free()
	for i in options.size():
		var button := Button.new()
		button.text = "%d. %s" % [i + 1, options[i]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 10)
		button.pressed.connect(_answered.emit.bind(i))
		_options.add_child(button)
	_option_count = options.size()
	_hint.visible = GameState.is_first_day()
	_opened_pause = not get_tree().paused
	get_tree().paused = true
	show()
	var index: int = await _answered
	hide()
	if _opened_pause:
		get_tree().paused = false
	return index


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
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(panel_width, 0)
	center.add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
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
	_title = Label.new()
	_title.add_theme_color_override("font_color", Color(1.0, 0.75, 0.45))
	_title.add_theme_font_size_override("font_size", 12)
	box.add_child(_title)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("font_size", 10)
	box.add_child(_body)
	_options = VBoxContainer.new()
	box.add_child(_options)
	_hint = Label.new()
	_hint.text = "Phím số / click để chọn · E / Esc: đi tiếp"
	_hint.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	_hint.add_theme_font_size_override("font_size", 8)
	box.add_child(_hint)
