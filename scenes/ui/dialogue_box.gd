class_name DialogueBox
extends CanvasLayer
## Conversation box at the bottom of the screen: speaker name + text typed
## out letter by letter. E / Space / click: finish the line, then next line;
## Esc: skip the rest. The game is paused while it's open. Built in code.
## Stardew-like: a placeholder portrait (colored square + initial) for the
## speaker, and `choose()` for answers (number keys / click). Text may use
## {pet} (the cat's name). Usage: `await play_lines(lines)`,
## `await play(dialogue)` (also marks it seen), `await choose(options)`.

signal _advanced
signal _chosen(index: int)
## Esc pressed: the rest of the conversation (or cutscene) is skipped.
signal skipped

@export var chars_per_second: float = 45.0
## Name colors; others use the default.
@export var speaker_colors: Dictionary = {
	"Rin": Color(0.55, 0.75, 1.0),
	"Bảo": Color(1.0, 0.7, 0.4),
	"Mèo": Color(1.0, 0.75, 0.35),
}
@export var default_color: Color = Color(1.0, 0.95, 0.8)

var _name_label: Label
var _text_label: Label
var _portrait: ColorRect
var _portrait_letter: Label
var _choices: VBoxContainer
var _choice_count: int = 0
## Keep the tree paused after the last line (a cutscene owns the pause).
var hold_pause: bool = false
var _skip: bool = false
var _opened_pause: bool = false


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
	speaker = CutsceneScript.fill(speaker)
	_name_label.text = speaker
	_name_label.add_theme_color_override("font_color", speaker_colors.get(speaker, default_color))
	_portrait.visible = speaker != ""
	_portrait.color = speaker_colors.get(speaker, default_color).darkened(0.3)
	_portrait_letter.text = speaker.left(1)
	_text_label.text = CutsceneScript.fill(text)
	_text_label.visible_characters = 0


func await_advance() -> void:
	await _advanced


## Shows answers under the current line; returns the chosen index.
func choose(options: PackedStringArray) -> int:
	_open()
	_text_label.visible_characters = -1
	for child in _choices.get_children():
		child.queue_free()
	for i in options.size():
		var button := Button.new()
		button.text = "%d. %s" % [i + 1, options[i]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 10)
		button.pressed.connect(_chosen.emit.bind(i))
		_choices.add_child(button)
	_choice_count = options.size()
	_choices.show()
	var index: int = await _chosen
	_choice_count = 0
	_choices.hide()
	return index


func _open() -> void:
	if visible:
		return
	_opened_pause = not get_tree().paused
	get_tree().paused = true
	show()


func _close() -> void:
	hide()
	if _opened_pause and not hold_pause:
		get_tree().paused = false
	_opened_pause = false


func _process(delta: float) -> void:
	if visible and _text_label.visible_characters < _text_label.text.length():
		_text_label.visible_characters = mini(_text_label.text.length(),
			_text_label.visible_characters + maxi(1, roundi(chars_per_second * delta)))


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
		if _text_label.visible_characters < _text_label.text.length():
			_text_label.visible_characters = _text_label.text.length()
		else:
			_advanced.emit()


func _build() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 20
	panel.offset_right = -20
	panel.offset_top = -84
	panel.offset_bottom = -8
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	_portrait = ColorRect.new()
	_portrait.custom_minimum_size = Vector2(44, 44)
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_portrait)
	_portrait_letter = Label.new()
	_portrait_letter.set_anchors_preset(Control.PRESET_FULL_RECT)
	_portrait_letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_letter.add_theme_font_size_override("font_size", 20)
	_portrait.add_child(_portrait_letter)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(box)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 10)
	box.add_child(_name_label)
	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 10)
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_text_label)
	_choices = VBoxContainer.new()
	_choices.hide()
	box.add_child(_choices)
