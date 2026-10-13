class_name SpeechLine
extends Control
## What used to be on-screen notices, said by someone instead: a small
## speech bubble over the speaker that fades after a few seconds and never
## pauses the game. "Name: text" picks the speaker (Bảo, Cô Năm...), lines
## starting with "[" come from the phone app ("Rin's Catch"), anything else
## is Rin talking to himself. Speakers are placed with `anchors` (name ->
## Callable returning a screen position above their head); unknown ones,
## and Rin when he has no anchor, use the bottom of the screen.

@export var max_width: float = 220.0
@export var font_size: int = 9
@export var fade_seconds: float = 0.25
@export var speaker_colors: Dictionary = {
	"Rin": Color(0.55, 0.8, 1.0), "Bảo": Color(1.0, 0.7, 0.35), "Cô Năm": Color(0.6, 0.9, 0.6),
	"Rin's Catch": Color(0.5, 1.0, 0.8),
}

## name -> Callable () -> Vector2 (screen point above the head).
var anchors: Dictionary = {}

var _panel: PanelContainer
var _name: Label
var _text: Label
var _speaker: String = ""
var _token: int = 0
var _sticky: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.11, 0.88)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(box)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", font_size - 1)
	box.add_child(_name)
	_text = Label.new()
	_text.add_theme_font_size_override("font_size", font_size)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_text)
	_panel.modulate.a = 0.0
	_panel.hide()


## Says `line` for `seconds` (0 = until the next line).
func say(line: String, seconds: float = 2.0) -> void:
	_token += 1
	var token := _token
	_speaker = "Rin"
	var text := line
	if line.begins_with("["):
		_speaker = "Rin's Catch"
	else:
		var colon := line.find(": ")
		if colon > 0 and colon <= 14 and not line.left(colon).is_valid_int():
			_speaker = line.left(colon)
			text = line.substr(colon + 2)
	_name.text = _speaker
	_name.add_theme_color_override("font_color", speaker_colors.get(_speaker, Color(1, 0.9, 0.6)))
	_text.text = text
	# Wrap at max_width but shrink for short lines.
	var font := _text.get_theme_font("font")
	var natural := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_text.custom_minimum_size.x = minf(natural + 2.0, max_width)
	_panel.reset_size()
	_panel.show()
	_sticky = seconds <= 0.0
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 1.0, fade_seconds)
	if _sticky:
		return
	await get_tree().create_timer(seconds).timeout
	if token != _token:
		return
	tween = create_tween()
	tween.tween_property(_panel, "modulate:a", 0.0, fade_seconds)
	await tween.finished
	if token == _token:
		_panel.hide()


func hide_line() -> void:
	_token += 1
	_panel.hide()


func _process(_delta: float) -> void:
	if not _panel.visible:
		return
	var view := get_viewport_rect().size
	var anchor: Callable = anchors.get(_speaker, anchors.get("Rin", Callable()))
	var at := Vector2(view.x * 0.5, view.y - 20.0)
	if anchor.is_valid() and (anchors.has(_speaker) or _speaker == "Rin"):
		at = anchor.call()
	_panel.reset_size()  # wrapped text settles its height after a frame
	var size := _panel.size
	_panel.position = (at - Vector2(size.x * 0.5, size.y)).clamp(Vector2(4, 4), view - size - Vector2(4, 4))
