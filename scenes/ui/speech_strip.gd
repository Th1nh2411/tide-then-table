class_name SpeechStrip
extends PanelContainer
## Bottom speech note (paper strip, "StripPanel"), shared by the 3D restaurant
## and the 3D sea. "Bảo: ..." puts the name in red ink; other lines get
## `default_speaker` ("" = none). Slides in with a small turn, flashes on a
## new line, fades out.

## Speaker for lines without "Name:" (the sea: Rin talking to himself).
@export var default_speaker: String = ""
## Width of the text column (autowrap needs one).
@export var text_width: float = 520.0
@export var font_size: int = 11

var current: String = ""
var _speaker: Label
var _text: Label
var _clock: float = 0.0


func _ready() -> void:
	theme_type_variation = &"StripPanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_speaker = Label.new()
	_speaker.theme_type_variation = &"HeadingLabel"
	_speaker.add_theme_font_size_override("font_size", font_size + 1)
	_speaker.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_speaker)
	_text = Label.new()
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.custom_minimum_size.x = text_width
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.theme_type_variation = &"InkLabel"
	_text.add_theme_font_size_override("font_size", font_size)
	_text.add_theme_color_override("font_color", HudChips.INK)
	row.add_child(_text)
	hide()


## Shows a line; `seconds` <= 0 keeps it until `clear()`.
func say(words: String, seconds: float = 4.0) -> void:
	if not is_node_ready():
		await ready
	current = words
	var speaker := words.get_slice(":", 0)
	var named := speaker != words and speaker.length() <= 10
	var who := speaker if named else default_speaker
	var body := words.substr(speaker.length() + 1).strip_edges() if named else words
	_speaker.visible = who != ""
	_speaker.text = who
	_text.text = body
	_clock = seconds
	var fresh := not visible or modulate.a < 1.0
	show()
	modulate.a = 1.0
	if fresh:
		UiFx.tilt(self, -0.4)
		UiFx.settle(self, Vector2(0, 18), 0.0, -1.5)
	else:
		UiFx.flash(_text, Color(1.4, 1.3, 1.0))


## Fades the strip away.
func clear() -> void:
	current = ""
	_clock = 0.0
	if not visible:
		return
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.3)
	fade.tween_callback(func() -> void:
		if current == "":
			_text.text = ""
			hide())


func _process(delta: float) -> void:
	if _clock > 0.0:
		_clock -= delta
		if _clock <= 0.0:
			clear()
