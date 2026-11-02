class_name DialogueBox
extends CanvasLayer
## Conversation as subtitles (horror build): plain text centred at the
## bottom of the screen, "Bảo: ..." with the speaker's name in their colour,
## no portrait, no paper box; narration is the same text in grey. Text
## types out letter by letter.
## E / Space / click: finish the line, then next line; Esc: skip the rest.
## The game is paused while it's open. A speaker's "(mood)" is dropped
## ("Rin (vui): ..." shows "Rin:"). Text may use
## {pet} (the cat's name). Usage: `await play_lines(lines)`,
## `await play(dialogue)` (also marks it seen), `await choose(options)`.

signal _advanced
signal _chosen(index: int)
## Esc pressed: the rest of the conversation (or cutscene) is skipped.
signal skipped

@export var chars_per_second: float = 45.0
## Colour band on the speaker's name tag; others use the default.
@export var speaker_colors: Dictionary = {
	"Rin": Color("4f8fba"),
	"Bảo": Color("de9e41"),
	"Mèo": Color("be772b"),
}
@export var default_color: Color = Color("a53030")
@export var ink_color: Color = Color("efe6d2")
@export var narration_color: Color = Color("b9b3a6")
## How far a new line slides up as it appears.
@export var enter_pixels: float = 14.0

var _name_label: Label
var _text_label: Label
var _bubble: PanelContainer
var _name_tag: PanelContainer
var _back: Control
var _front: Control
var _choices: VBoxContainer
var _choice_count: int = 0
## Keep the tree paused after the last line (a cutscene owns the pause).
var hold_pause: bool = false
var _skip: bool = false
var _opened_pause: bool = false
var _has_speaker: bool = false
var _time: float = 0.0
var _enter: float = 1.0  # 0 -> 1 slide-in of the bubble when the box opens


func _ready() -> void:
	layer = 24
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	hide()


func is_open() -> bool:
	return visible


func play(dialogue: Dialogue) -> void:
	await play_lines(DialogueLibrary.parse(dialogue.script_text))
	DialogueLibrary.mark_done(dialogue)


func play_lines(lines: Array[Dictionary]) -> void:
	_skip = false
	_open()
	for line in lines:
		if _skip:
			break
		show_line(line["speaker"], line["text"])
		await _advanced
	_close()


## Shows one line without waiting (cutscenes call this, then await_advance()).
func show_line(speaker: String, text: String) -> void:
	_open()
	# "Rin (vui)": the mood was for portraits; subtitles show the name only.
	var paren := speaker.find("(")
	if paren > 0 and speaker.ends_with(")"):
		speaker = speaker.left(paren).strip_edges()
	speaker = CutsceneScript.fill(speaker)
	_has_speaker = speaker != ""
	_name_label.text = speaker + ":"
	_name_tag.visible = _has_speaker
	_name_label.add_theme_color_override("font_color", speaker_colors.get(speaker, default_color))
	_text_label.add_theme_color_override("font_color", ink_color if _has_speaker else narration_color)
	_text_label.text = CutsceneScript.fill(text)
	_text_label.visible_characters = 0
	Sfx.play("blip")


func await_advance() -> void:
	await _advanced


## Shows answers under the current line; returns the chosen index.
func choose(options: PackedStringArray) -> int:
	_open()
	_text_label.visible_characters = -1
	for child in _choices.get_children():
		child.queue_free()
	for i in options.size():
		_choices.add_child(_choice_button(i, options[i]))
	_choice_count = options.size()
	_choices.show()
	var index: int = await _chosen
	_choice_count = 0
	_choices.hide()
	return index


## One answer: a paper price-tag button with its number key cap.
func _choice_button(index: int, text: String) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"PaperButton"
	button.text = "        " + text  # room for the key cap
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_size_override("font_size", 10)
	button.pressed.connect(_chosen.emit.bind(index))
	var key := Label.new()
	key.theme_type_variation = &"KeyLabel"
	key.text = str(index + 1)
	key.add_theme_font_size_override("font_size", 8)
	key.position = Vector2(5, 4)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(key)
	UiFx.hover_lift(button, 0.03)
	UiFx.pop_in(button, 0.05 * index)
	return button


func _open() -> void:
	if visible:
		return
	_enter = 0.0
	_opened_pause = not get_tree().paused
	get_tree().paused = true
	show()


func _close() -> void:
	hide()
	if _opened_pause and not hold_pause:
		get_tree().paused = false
	_opened_pause = false


func _typing() -> bool:
	return _text_label.visible_characters < _text_label.text.length() and _text_label.visible_characters >= 0


func _process(delta: float) -> void:
	if not visible:
		return
	var real := delta / maxf(Engine.time_scale, 0.01)  # typing ignores cutscene slow-mo
	_time += real
	_enter = minf(_enter + real * 5.0, 1.0)
	if _typing():
		_text_label.visible_characters = mini(_text_label.text.length(),
			_text_label.visible_characters + maxi(1, roundi(chars_per_second * real)))
	_layout()
	_front.queue_redraw()


## Subtitle line centred at the bottom; the speaker's name sits just above it.
func _layout() -> void:
	var view := _back.get_viewport_rect().size
	_bubble.custom_minimum_size.x = view.x - 120.0
	_bubble.reset_size()  # wrapped text settles its height after a frame
	var ease_in := 1.0 - pow(1.0 - _enter, 3.0)
	_bubble.position = Vector2(60.0, view.y - 18.0 - _bubble.size.y + (1.0 - ease_in) * enter_pixels)
	_bubble.modulate.a = ease_in
	_name_tag.reset_size()
	_name_tag.position = Vector2((view.x - _name_tag.size.x) * 0.5, _bubble.position.y - _name_tag.size.y + 2.0)
	_name_tag.modulate.a = ease_in


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var click := event as InputEventMouseButton
	var pressed := event.is_action_pressed("interact") or event.is_action_pressed("cast") \
		or (click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT)
	if _choice_count > 0:
		var key := event as InputEventKey
		if key and key.pressed and not key.echo:
			var index := key.physical_keycode - KEY_1
			if index >= 0 and index < _choice_count:
				get_viewport().set_input_as_handled()
				_chosen.emit(index)
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_skip = true
		skipped.emit()
		_advanced.emit()
	elif pressed:
		get_viewport().set_input_as_handled()
		if _typing():
			_text_label.visible_characters = _text_label.text.length()
		else:
			_advanced.emit()


## No band behind the words: the outline keeps them readable.
func _draw_back() -> void:
	pass


## The small "next" arrow once the line has finished typing.
func _draw_front() -> void:
	if _typing() or _choice_count > 0:
		return
	var r := Rect2(_bubble.position, _bubble.size)
	var bounce := 1.5 if fmod(_time, 0.8) < 0.4 else 0.0
	var at := Vector2(r.get_center().x - 3.5, r.end.y - 2.0 + bounce).round()
	_front.draw_colored_polygon(PackedVector2Array([at, at + Vector2(7, 0), at + Vector2(3.5, 5)]), ink_color)


func _build() -> void:
	_back = Control.new()
	_back.set_anchors_preset(Control.PRESET_FULL_RECT)
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back.draw.connect(_draw_back)
	add_child(_back)
	_bubble = PanelContainer.new()
	_bubble.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(_bubble)
	var pad := MarginContainer.new()  # text room inside the paper
	pad.add_theme_constant_override("margin_left", 6)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 3)
	pad.add_theme_constant_override("margin_bottom", 3)
	_bubble.add_child(pad)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	pad.add_child(box)
	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.add_theme_font_size_override("font_size", 12)
	_text_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_text_label.add_theme_constant_override("outline_size", 4)
	_text_label.custom_minimum_size.y = 34
	box.add_child(_text_label)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 0)
	_choices.hide()
	box.add_child(_choices)
	# Speaker name above the line, in their colour (no tag paper).
	_name_tag = PanelContainer.new()
	_name_tag.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_tag)
	_name_label = Label.new()
	_name_label.theme_type_variation = &"TitleLabel"
	_name_label.add_theme_font_size_override("font_size", 10)
	_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_name_label.add_theme_constant_override("outline_size", 4)
	_name_tag.add_child(_name_label)
	_front = Control.new()
	_front.set_anchors_preset(Control.PRESET_FULL_RECT)
	_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_front.draw.connect(_draw_front)
	add_child(_front)
