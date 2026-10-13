class_name DialogueBox
extends CanvasLayer
## Conversation box, Nine Sols style: the speaker's big bust in a bottom
## corner (DialoguePortrait: Rin on the left, everyone else on the right) and
## a cream speech bubble with a tail pointing at them; lines without a
## speaker are narration in a dark box. Text types out letter by letter.
## E / Space / click: finish the line, then next line; Esc: skip the rest.
## The game is paused while it's open. A speaker may carry a mood for the
## portrait art: "Rin (vui): ..." / `speak "Rin (vui)" "..."`. Text may use
## {pet} (the cat's name). Usage: `await play_lines(lines)`,
## `await play(dialogue)` (also marks it seen), `await choose(options)`.

signal _advanced
signal _chosen(index: int)
## Esc pressed: the rest of the conversation (or cutscene) is skipped.
signal skipped

@export var chars_per_second: float = 45.0
## Name tag colors; others use the default.
@export var speaker_colors: Dictionary = {
	"Rin": Color(0.55, 0.75, 1.0),
	"Bảo": Color(1.0, 0.7, 0.4),
	"Mèo": Color(1.0, 0.75, 0.35),
}
@export var default_color: Color = Color(1.0, 0.95, 0.8)
## Speakers whose portrait sits on the left (the rest face them from the right).
@export var left_speakers: PackedStringArray = ["rin"]
@export var portrait_size: float = 136.0
@export var bubble_width: float = 300.0
@export var bubble_color: Color = Color(0.96, 0.94, 0.87)
@export var ink_color: Color = Color(0.13, 0.11, 0.14)

var _name_label: Label
var _text_label: Label
var _portrait: DialoguePortrait
var _bubble: PanelContainer
var _bubble_style: StyleBoxFlat
var _narration_style: StyleBoxFlat
var _back: Control
var _front: Control
var _choices: VBoxContainer
var _choice_count: int = 0
## Keep the tree paused after the last line (a cutscene owns the pause).
var hold_pause: bool = false
var _skip: bool = false
var _opened_pause: bool = false
var _has_speaker: bool = false
var _on_right: bool = false
var _time: float = 0.0


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
	var mood := ""
	var paren := speaker.find("(")
	if paren > 0 and speaker.ends_with(")"):
		mood = DialoguePortrait.slug(speaker.substr(paren + 1, speaker.length() - paren - 2))
		speaker = speaker.left(paren).strip_edges()
	var is_cat := speaker == "{pet}" or speaker == "Mèo"
	speaker = CutsceneScript.fill(speaker)
	var id := "cat" if is_cat else DialoguePortrait.slug(speaker)
	_has_speaker = speaker != ""
	_on_right = not left_speakers.has(id)
	_name_label.text = speaker
	_name_label.add_theme_color_override("font_color", speaker_colors.get(speaker, default_color))
	_name_label.visible = _has_speaker
	_portrait.visible = _has_speaker
	if _has_speaker:
		_portrait.set_speaker(id, mood, _on_right)
	_bubble.add_theme_stylebox_override("panel", _bubble_style if _has_speaker else _narration_style)
	_text_label.add_theme_color_override("font_color", ink_color if _has_speaker else Color(0.9, 0.9, 0.85))
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
	var ink := ink_color if _has_speaker else Color(0.9, 0.9, 0.85)
	for i in options.size():
		var button := Button.new()
		button.text = "%d. %s" % [i + 1, options[i]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 10)
		for state in ["font_color", "font_hover_color", "font_pressed_color"]:
			button.add_theme_color_override(state, ink)
		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(ink, 0.15)
		hover.set_corner_radius_all(4)
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", hover)
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


func _typing() -> bool:
	return _text_label.visible_characters < _text_label.text.length() and _text_label.visible_characters >= 0


func _process(delta: float) -> void:
	if not visible:
		return
	var real := delta / maxf(Engine.time_scale, 0.01)  # typing ignores cutscene slow-mo
	_time += real
	if _typing():
		_text_label.visible_characters = mini(_text_label.text.length(),
			_text_label.visible_characters + maxi(1, roundi(chars_per_second * real)))
	_portrait.talking = _typing()
	_layout()
	_front.queue_redraw()


## Bubble beside the portrait, growing upwards from the bottom.
func _layout() -> void:
	var view := _back.get_viewport_rect().size
	_portrait.size = Vector2(portrait_size, portrait_size)
	_portrait.position = Vector2(view.x - portrait_size - 6.0 if _on_right else 6.0, view.y - portrait_size + 6.0)
	var left := 60.0
	var right := view.x - 60.0
	if _has_speaker:
		left = view.x - portrait_size - bubble_width if _on_right else portrait_size + 2.0
		right = left + bubble_width
	_bubble.custom_minimum_size.x = right - left
	_bubble.reset_size()  # wrapped text settles its height after a frame
	_bubble.position = Vector2(left, view.y - 22.0 - _bubble.size.y)
	_name_label.reset_size()
	var tag_x := _bubble.position.x + 14.0
	if _on_right:
		tag_x = _bubble.position.x + _bubble.size.x - 14.0 - _name_label.size.x
	_name_label.position = Vector2(tag_x, _bubble.position.y - _name_label.size.y + 2.0)


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


## Dark fade at the bottom so the bubble reads over any scene.
func _draw_back() -> void:
	var view := _back.get_viewport_rect().size
	var top := view.y - 130.0
	var colors := PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.55)])
	_back.draw_polygon(PackedVector2Array([Vector2(0, top), Vector2(view.x, top), Vector2(view.x, view.y),
		Vector2(0, view.y)]), colors)


## The bubble's tail towards the speaker's mouth, and the "next" arrow.
func _draw_front() -> void:
	var r := Rect2(_bubble.position, _bubble.size)
	if _has_speaker:
		var side := -1.0 if _on_right else 1.0
		var edge := r.end.x if _on_right else r.position.x
		var base_a := Vector2(edge + side * 1.0, r.position.y + 14.0)
		var base_b := Vector2(edge + side * 1.0, r.position.y + 28.0)
		var tip := Vector2(edge - side * 16.0, r.position.y + 10.0)
		_front.draw_colored_polygon(PackedVector2Array([base_a, tip, base_b]), bubble_color)
		_front.draw_line(base_a, tip, ink_color, 2.0)
		_front.draw_line(tip, base_b, ink_color, 2.0)
	if not _typing() and _choice_count == 0:
		var bounce := 1.5 if fmod(_time, 0.8) < 0.4 else 0.0
		var at := r.end - Vector2(16.0, 11.0 - bounce)
		_front.draw_colored_polygon(PackedVector2Array([at, at + Vector2(7, 0), at + Vector2(3.5, 5)]),
			ink_color if _has_speaker else Color(0.9, 0.9, 0.85))


func _build() -> void:
	_back = Control.new()
	_back.set_anchors_preset(Control.PRESET_FULL_RECT)
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back.draw.connect(_draw_back)
	add_child(_back)
	_portrait = DialoguePortrait.new()
	add_child(_portrait)
	_bubble_style = StyleBoxFlat.new()
	_bubble_style.bg_color = bubble_color
	_bubble_style.border_color = ink_color
	_bubble_style.set_border_width_all(2)
	_bubble_style.set_corner_radius_all(16)
	_bubble_style.content_margin_left = 14
	_bubble_style.content_margin_right = 22
	_bubble_style.content_margin_top = 9
	_bubble_style.content_margin_bottom = 9
	_narration_style = _bubble_style.duplicate() as StyleBoxFlat
	_narration_style.bg_color = Color(0.06, 0.08, 0.12, 0.94)
	_narration_style.border_color = Color(0.55, 0.65, 0.75, 0.5)
	_narration_style.set_border_width_all(1)
	_narration_style.set_corner_radius_all(6)
	_bubble = PanelContainer.new()
	add_child(_bubble)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_bubble.add_child(box)
	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 11)
	_text_label.custom_minimum_size.y = 34
	box.add_child(_text_label)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 0)
	_choices.hide()
	box.add_child(_choices)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 10)
	var tag := StyleBoxFlat.new()
	tag.bg_color = Color(0.1, 0.09, 0.12)
	tag.set_corner_radius_all(4)
	tag.content_margin_left = 6
	tag.content_margin_right = 6
	tag.content_margin_top = 1
	tag.content_margin_bottom = 1
	_name_label.add_theme_stylebox_override("normal", tag)
	add_child(_name_label)
	_front = Control.new()
	_front.set_anchors_preset(Control.PRESET_FULL_RECT)
	_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_front.draw.connect(_draw_front)
	add_child(_front)
