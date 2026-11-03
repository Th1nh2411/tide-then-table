class_name SpeechStrip
extends Control
## Short spoken lines as subtitles (horror build), same look as DialogueBox:
## plain outlined text centred low on the screen, the speaker's name just
## above it in their colour, no box. Used by the 3D restaurant / village and
## the 3D sea. "Bảo: ..." names Bảo; other lines get `default_speaker`
## ("" = none). One line at a time: a line said while another is still fresh
## waits its turn (each shows at least MIN_SECONDS when others are queued).
## It covers its parent's rect on its own, whatever anchors the owner sets.

const MIN_SECONDS := 1.6
const MAX_QUEUE := 4
const NAME_COLORS := {"Rin": Color("4f8fba"), "Bảo": Color("de9e41"), "Mèo": Color("be772b")}
const OTHER_NAME := Color("c0503f")
const INK := Color("efe6d2")

## Speaker for lines without "Name:" (the sea: Rin talking to himself).
@export var default_speaker: String = ""
## Kept for older callers; the subtitle is as wide as the screen allows.
@export var text_width: float = 520.0
@export var font_size: int = 12

var current: String = ""
var _speaker: Label
var _text: Label
var _clock: float = 0.0
var _shown_for: float = 0.0
var _queue: Array[Array] = []  # [words, seconds]
var _fade: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker = _outlined(font_size - 2)
	_speaker.theme_type_variation = &"TitleLabel"
	_text = _outlined(font_size)
	_text.add_theme_color_override("font_color", INK)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hide()


func _outlined(px: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", px)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
	return label


## Shows a line (or queues it behind a fresh one); `seconds` <= 0 keeps it
## until `clear()` or the next line.
func say(words: String, seconds: float = 4.0) -> void:
	if not is_node_ready():
		await ready
	if words == current or _queue.any(func(item: Array) -> bool: return item[0] == words):
		return
	if current != "" and _shown_for < MIN_SECONDS:
		if _queue.size() >= MAX_QUEUE:
			_queue.pop_front()
		_queue.append([words, seconds])
		return
	_show_now(words, seconds)


func _show_now(words: String, seconds: float) -> void:
	current = words
	var speaker := words.get_slice(":", 0)
	var named := speaker != words and speaker.length() <= 10
	var who := speaker if named else default_speaker
	_speaker.visible = who != ""
	_speaker.text = who + ":"
	_speaker.add_theme_color_override("font_color", NAME_COLORS.get(who, OTHER_NAME))
	_text.text = words.substr(speaker.length() + 1).strip_edges() if named else words
	_clock = seconds
	_shown_for = 0.0
	var fresh := not visible or modulate.a < 1.0
	show()
	_place()
	if fresh:  # a quick fade in, no slide (subtitles stay put)
		modulate.a = 0.0
		_fade_to(1.0, 0.15)


## Bottom-centre, like DialogueBox: the line, its speaker just above.
func _place() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view := size if size.x > 0.0 else get_viewport_rect().size
	_text.size = Vector2(view.x - 120.0, 0.0)
	_text.reset_size()
	_text.size.x = view.x - 120.0
	_text.position = Vector2(60.0, view.y - 22.0 - _text.get_minimum_size().y)
	_speaker.reset_size()
	_speaker.position = Vector2((view.x - _speaker.size.x) * 0.5, _text.position.y - _speaker.size.y + 3.0)


## Fades the line away and drops anything queued.
func clear() -> void:
	current = ""
	_clock = 0.0
	_queue.clear()
	if not visible:
		return
	_fade_to(0.0, 0.3).tween_callback(func() -> void:
		if current == "":
			_text.text = ""
			hide())


func _fade_to(alpha: float, seconds: float) -> Tween:
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", alpha, seconds)
	return _fade


func _process(delta: float) -> void:
	if current == "":
		return
	_place()  # wrapped text settles its height after a frame
	_shown_for += delta
	if not _queue.is_empty() and _shown_for >= MIN_SECONDS:
		var next: Array = _queue.pop_front()
		_show_now(str(next[0]), float(next[1]))
		return
	if _clock > 0.0:
		_clock -= delta
		if _clock <= 0.0:
			clear()
