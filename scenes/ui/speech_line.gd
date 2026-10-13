class_name SpeechLine
extends Control
## What used to be on-screen notices, said by someone instead: small speech
## bubbles over the speakers that fade after a few seconds and never pause
## the game. "Name: text" picks the speaker (Bảo, Cô Năm...), lines starting
## with "[" or "NEO: " come from NEO, the assistant in the phone app (bottom
## left, with its hologram NeoAvatar; "[WARN]" / "[ERR]" lines in red),
## anything else is Rin talking to himself. Each speaker has their own bubble, so Bảo calling out
## doesn't wipe what Rin just said; a speaker's next line waits until the
## current one has been up for `min_seconds` (a short queue). Speakers are
## placed with `anchors` (name -> Callable returning a screen point above
## their head); the rest stack up from the bottom of the screen.

const ASSISTANT := "NEO"

@export var max_width: float = 220.0
## NEO's bubble sits this far above the bottom-left corner (over the
## Nhịp Sóng badge).
@export var assistant_bottom: float = 34.0
@export var font_size: int = 9
@export var fade_seconds: float = 0.25
## A speaker's next line waits for the current one to finish, at least
## `min_seconds` and at most `max_wait` (long lines don't hold up the queue).
@export var min_seconds: float = 1.0
@export var max_wait: float = 2.5
## Lines waiting per speaker; older ones are dropped.
@export var max_queue: int = 3
@export var speaker_colors: Dictionary = {
	"Rin": Color(0.55, 0.8, 1.0), "Bảo": Color(1.0, 0.7, 0.35), "Cô Năm": Color(0.6, 0.9, 0.6),
	ASSISTANT: Color(0.35, 0.95, 1.0),
}

## name -> Callable () -> Vector2 (screen point above the head).
var anchors: Dictionary = {}
## () -> float seconds; real time by default (tests pass a fake clock).
var clock: Callable = Callable()

## speaker -> Bubble
var _bubbles: Dictionary = {}


class Bubble:
	var panel: PanelContainer
	var name_label: Label
	var text_label: Label
	var speaker: String = ""
	var avatar: NeoAvatar
	var shown_at: float = -100.0
	var hide_at: float = -100.0
	var queue: Array[Array] = []  # [text, seconds]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Says `line` for `seconds` (0 = until that speaker's next line).
func say(line: String, seconds: float = 2.0) -> void:
	var speaker := "Rin"
	var text := line
	if line.begins_with("["):
		speaker = ASSISTANT
		text = line.trim_prefix("[MSG] ")
	else:
		var colon := line.find(": ")
		if colon > 0 and colon <= 14 and not line.left(colon).is_valid_int():
			speaker = line.left(colon)
			text = line.substr(colon + 2)
	var bubble := _bubble(speaker)
	var now := _now()
	if bubble.panel.visible and now < _free_at(bubble):
		bubble.queue.append([text, seconds])
		if bubble.queue.size() > max_queue:
			bubble.queue.pop_front()
		return
	_show(bubble, text, seconds)


func hide_line() -> void:
	for bubble: Bubble in _bubbles.values():
		bubble.queue.clear()
		bubble.panel.hide()


## The text currently up for `speaker` ("" when none; tests).
func current(speaker: String = "Rin") -> String:
	var bubble: Bubble = _bubbles.get(speaker)
	return bubble.text_label.text if bubble and bubble.panel.visible else ""


func _show(bubble: Bubble, text: String, seconds: float) -> void:
	bubble.text_label.text = text
	var alarm := text.begins_with("[WARN]") or text.begins_with("[ERR]")
	bubble.text_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.45) if alarm else Color(0.92, 0.92, 0.92))
	if bubble.avatar:
		bubble.avatar.alarm = alarm
		bubble.avatar.speak()
		Sfx.play("neo", 0.0)
	# Wrap at max_width but shrink for short lines.
	var font := bubble.text_label.get_theme_font("font")
	var natural := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	bubble.text_label.custom_minimum_size.x = minf(natural + 2.0, max_width)
	bubble.panel.reset_size()
	bubble.panel.show()
	bubble.shown_at = _now()
	bubble.hide_at = INF if seconds <= 0.0 else bubble.shown_at + seconds
	_place_all()  # right away: the game may pause before the next frame


func _process(_delta: float) -> void:
	var now := _now()
	for speaker: String in _bubbles:
		var bubble: Bubble = _bubbles[speaker]
		if not bubble.queue.is_empty() and now >= _free_at(bubble):
			var next: Array = bubble.queue.pop_front()
			_show(bubble, next[0], next[1])
		if bubble.panel.visible and now >= bubble.hide_at + fade_seconds:
			bubble.panel.hide()
	_place_all()


## Fades and places every bubble over its speaker.
func _place_all() -> void:
	var now := _now()
	var view := get_viewport_rect().size
	var bottom := view.y - 20.0  # unanchored bubbles stack up from here
	for speaker: String in _bubbles:
		var bubble: Bubble = _bubbles[speaker]
		if not bubble.panel.visible:
			continue
		var fade_in := clampf((now - bubble.shown_at) / fade_seconds, 0.0, 1.0)
		var fade_out := clampf((bubble.hide_at + fade_seconds - now) / fade_seconds, 0.0, 1.0)
		bubble.panel.modulate.a = minf(fade_in, fade_out)
		bubble.panel.reset_size()  # wrapped text settles its height after a frame
		var size := bubble.panel.size
		if speaker == ASSISTANT:  # always the bottom-left corner
			bubble.panel.position = Vector2(4.0, view.y - assistant_bottom - size.y)
			continue
		var anchor: Callable = anchors.get(speaker, Callable())
		var at := Vector2(view.x * 0.5, bottom)
		if anchor.is_valid():
			at = anchor.call()
		else:
			bottom -= size.y + 3.0
		bubble.panel.position = (at - Vector2(size.x * 0.5, size.y)).clamp(Vector2(4, 4), view - size - Vector2(4, 4))


## When the speaker's current line may give way to the next one.
func _free_at(bubble: Bubble) -> float:
	return bubble.shown_at + clampf(bubble.hide_at - bubble.shown_at, min_seconds, maxf(max_wait, min_seconds))


func _now() -> float:
	if clock.is_valid():
		return clock.call()
	return Time.get_ticks_msec() / 1000.0  # real time: slow-mo doesn't stretch lines


func _bubble(speaker: String) -> Bubble:
	if _bubbles.has(speaker):
		return _bubbles[speaker]
	var bubble := Bubble.new()
	bubble.speaker = speaker
	bubble.panel = PanelContainer.new()
	bubble.panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.11, 0.88)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	bubble.panel.add_theme_stylebox_override("panel", style)
	add_child(bubble.panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if speaker == ASSISTANT:  # hologram + teal frame
		style.border_color = Color(speaker_colors[ASSISTANT], 0.7)
		style.set_border_width_all(1)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bubble.panel.add_child(row)
		bubble.avatar = NeoAvatar.new()
		bubble.avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bubble.avatar)
		row.add_child(box)
	else:
		bubble.panel.add_child(box)
	bubble.name_label = Label.new()
	bubble.name_label.text = speaker
	bubble.name_label.add_theme_font_size_override("font_size", font_size - 1)
	bubble.name_label.add_theme_color_override("font_color", speaker_colors.get(speaker, Color(1, 0.9, 0.6)))
	box.add_child(bubble.name_label)
	bubble.text_label = Label.new()
	bubble.text_label.add_theme_font_size_override("font_size", font_size)
	bubble.text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(bubble.text_label)
	bubble.panel.hide()
	_bubbles[speaker] = bubble
	return bubble
