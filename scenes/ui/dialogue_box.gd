class_name DialogueBox
extends CanvasLayer
## Conversation box, Nine Sols style: the speaker's big bust in a bottom
## corner (DialoguePortrait: Rin on the left, everyone else on the right) and
## a paper speech note ("StripPanel") with a tail pointing at them, the name on
## a yellow paper tag; lines without a speaker are narration on a torn
## parchment strip ("JournalPanel", taped, a little crooked, DREDGE journal). Text types out letter by letter.
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
## Colour band on the speaker's name tag; others use the default.
@export var speaker_colors: Dictionary = {
	"Rin": Color("4f8fba"),
	"Bảo": Color("de9e41"),
	"Mèo": Color("be772b"),
}
@export var default_color: Color = Color("a53030")
## Speakers whose portrait sits on the left (the rest face them from the right).
@export var left_speakers: PackedStringArray = ["rin"]
@export var portrait_size: float = 256.0
@export var bubble_width: float = 300.0
## Must match the paper of the "StripPanel" frame (the tail is drawn in it).
@export var bubble_color: Color = Color("e7d5b3")
@export var ink_color: Color = Color("090a14")
## Narration strip: resting tilt (degrees) and how far it slides in.
@export var narration_tilt: float = 0.0
@export var enter_pixels: float = 14.0

var _name_label: Label
var _text_label: Label
var _portrait: DialoguePortrait
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
var _on_right: bool = false
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
	_name_tag.visible = _has_speaker
	_name_tag.set_meta("band", speaker_colors.get(speaker, default_color))
	_name_tag.queue_redraw()
	_portrait.visible = _has_speaker
	if _has_speaker:
		_portrait.set_speaker(id, mood, _on_right)
	_bubble.theme_type_variation = &"StripPanel" if _has_speaker else &"JournalPanel"
	_bubble.rotation_degrees = 0.0 if _has_speaker else narration_tilt
	_text_label.add_theme_color_override("font_color", ink_color)
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
	var ease_in := 1.0 - pow(1.0 - _enter, 3.0)
	_bubble.position = Vector2(left, view.y - 22.0 - _bubble.size.y + (1.0 - ease_in) * enter_pixels)
	_bubble.pivot_offset = _bubble.size * 0.5
	_bubble.modulate.a = ease_in
	_name_tag.reset_size()
	var tag_x := _bubble.position.x + 12.0
	if _on_right:
		tag_x = _bubble.position.x + _bubble.size.x - 14.0 - _name_tag.size.x
	_name_tag.position = Vector2(tag_x, _bubble.position.y - _name_tag.size.y + 4.0)
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


## Stepped dark band at the bottom (no gradient) so the paper reads anywhere.
func _draw_back() -> void:
	var view := _back.get_viewport_rect().size
	var ink := Color("090a14")
	for step: Array in [[120.0, 0.18], [84.0, 0.32], [48.0, 0.46]]:
		var h: float = step[0]
		_back.draw_rect(Rect2(0, view.y - h, view.x, h), Color(ink, float(step[1]) - (0.0 if step[0] == 120.0 else 0.14)))


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
	else:
		# Taped to the screen like a page torn from Rin's journal.
		UiStickers.draw(_front, "tape", r.position + Vector2(14, 1), Color(1, 1, 1, _bubble.modulate.a))
		UiStickers.draw(_front, "tape", Vector2(r.end.x - 16, r.position.y - 1), Color(1, 1, 1, _bubble.modulate.a))
	if not _typing() and _choice_count == 0:
		var bounce := 1.5 if fmod(_time, 0.8) < 0.4 else 0.0
		var at := (r.end - Vector2(16.0, 11.0 - bounce)).round()
		_front.draw_colored_polygon(PackedVector2Array([at, at + Vector2(7, 0), at + Vector2(3.5, 5)]), Color("a53030"))


func _build() -> void:
	_back = Control.new()
	_back.set_anchors_preset(Control.PRESET_FULL_RECT)
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back.draw.connect(_draw_back)
	add_child(_back)
	_portrait = DialoguePortrait.new()
	add_child(_portrait)
	_bubble = PanelContainer.new()
	_bubble.theme_type_variation = &"StripPanel"
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
	_text_label.add_theme_font_size_override("font_size", 11)
	_text_label.custom_minimum_size.y = 34
	box.add_child(_text_label)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 0)
	_choices.hide()
	box.add_child(_choices)
	# Name on a small yellow paper tag, Paytone in ink.
	_name_tag = PanelContainer.new()
	_name_tag.theme_type_variation = &"TagPanel"
	_name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_tag)
	_name_label = Label.new()
	_name_label.theme_type_variation = &"TitleLabel"
	_name_label.add_theme_font_size_override("font_size", 10)
	_name_label.add_theme_color_override("font_color", ink_color)
	_name_label.add_theme_constant_override("outline_size", 0)
	_name_tag.add_child(_name_label)
	_name_tag.draw.connect(func() -> void:  # speaker colour band on the tag
		var band: Color = _name_tag.get_meta("band", default_color)
		_name_tag.draw_rect(Rect2(2, 2, 2, _name_tag.size.y - 6), band))
	_front = Control.new()
	_front.set_anchors_preset(Control.PRESET_FULL_RECT)
	_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_front.draw.connect(_draw_front)
	add_child(_front)
