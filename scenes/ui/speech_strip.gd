class_name SpeechStrip
extends PanelContainer
## Bottom speech note (paper strip, "StripPanel"), shared by the 3D restaurant
## and the 3D sea. "Bảo: ..." puts the name in red ink; "NEO: ..." and
## "[WARN]" / "[ERR]" lines are NEO's: VT323 with its small hologram
## (NeoAvatar), red when alarming; for NEO the paper turns into a dark navy
## machine screen (thin cyan edge, scanlines, glitch blink-in: NeoScreenFx)
## and the words type out with soft ticks. Other lines get
## `default_speaker` ("" = none). Slides in with a small turn, flashes on a
## new line, fades out.

const NEO_INK := Color("a4dddb")
const ALARM_INK := Color("e0302b")
## Seconds per typed character of NEO's lines (capped by NEO_TYPE_MAX).
const NEO_TYPE_SPEED := 0.022
const NEO_TYPE_MAX := 1.2

## Speaker for lines without "Name:" (the sea: Rin talking to himself).
@export var default_speaker: String = ""
## Width of the text column (autowrap needs one).
@export var text_width: float = 520.0
@export var font_size: int = 11

var current: String = ""
var _speaker: Label
var _text: Label
var _neo: NeoAvatar
var _screen: Control
var _clock: float = 0.0
var _fx: NeoScreenFx
var _neo_style: StyleBoxFlat
var _typed: int = 0
var _type_tween: Tween


func _ready() -> void:
	theme_type_variation = &"StripPanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	# NEO on a tiny dark screen so the hologram reads on paper.
	_screen = Control.new()
	_screen.custom_minimum_size = Vector2(18, 18)
	_screen.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.draw.connect(func() -> void:
		_screen.draw_rect(Rect2(Vector2.ZERO, _screen.size), HudChips.INK)
		_screen.draw_rect(Rect2(Vector2.ONE, _screen.size - Vector2(2, 2)), Color("172038")))
	row.add_child(_screen)
	_neo = NeoAvatar.new()
	_neo.position = Vector2(1, 1)
	_screen.add_child(_neo)
	_neo.custom_minimum_size = Vector2(16, 16)  # after its _ready (22 px default)
	_neo.size = Vector2(16, 16)
	_speaker = Label.new()
	_speaker.theme_type_variation = &"HeadingLabel"
	_speaker.add_theme_font_size_override("font_size", font_size + 1)
	_speaker.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_speaker)
	_text = Label.new()
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.custom_minimum_size.x = text_width
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Lay out the whole line before typing it out, so the strip has its final size.
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	row.add_child(_text)
	_fx = NeoScreenFx.new()
	_fx.hide()
	add_child(_fx)
	_neo_style = _machine_style()
	hide()


## Dark navy screen with a thin cyan edge, same margins as the paper strip.
func _machine_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("151d28", 0.95)
	style.border_color = Color(NeoScreenFx.CYAN, 0.55)
	style.set_border_width_all(1)
	var paper := get_theme_stylebox(&"panel")
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, paper.get_content_margin(side) if paper else 5.0)
	return style


## Shows a line; `seconds` <= 0 keeps it until `clear()`.
func say(words: String, seconds: float = 4.0) -> void:
	if not is_node_ready():
		await ready
	current = words
	var neo := words.begins_with("NEO:") or words.begins_with("[WARN]") or words.begins_with("[ERR]")
	var alarm := words.begins_with("[WARN]") or words.begins_with("[ERR]")
	var speaker := words.get_slice(":", 0)
	var named := not neo and speaker != words and speaker.length() <= 10
	var who := speaker if named else ("" if neo else default_speaker)
	var body := words
	if words.begins_with("NEO:"):
		body = words.substr(4).strip_edges()
	elif named:
		body = words.substr(speaker.length() + 1).strip_edges()
	_screen.visible = neo
	_neo.alarm = alarm
	if neo:
		_neo.speak()
	_speaker.visible = who != ""
	_speaker.text = who
	_text.text = body
	_text.theme_type_variation = &"NeoLabel" if neo else &"InkLabel"
	_text.add_theme_font_size_override("font_size", roundi(font_size * PhoneApp.NEO_FONT_SCALE) if neo else font_size)
	_text.add_theme_color_override("font_color", (ALARM_INK if alarm else NEO_INK) if neo else HudChips.INK)
	_set_machine(neo, alarm)
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


## NEO: machine screen, glitch blink-in, typed words. Others: plain paper.
func _set_machine(neo: bool, alarm: bool) -> void:
	_fx.visible = neo
	if _type_tween:
		_type_tween.kill()
	if not neo:
		remove_theme_stylebox_override(&"panel")
		_text.visible_ratio = 1.0
		return
	add_theme_stylebox_override(&"panel", _neo_style)
	_neo_style.border_color = Color(ALARM_INK if alarm else NeoScreenFx.CYAN, 0.55)
	_fx.alarm = alarm
	_fx.play()
	Sfx.play("neo", 0.0)
	_typed = 0
	_text.visible_ratio = 0.0
	_type_tween = create_tween()
	_type_tween.tween_property(_text, "visible_ratio", 1.0,
		minf(_text.text.length() * NEO_TYPE_SPEED, NEO_TYPE_MAX))


func _process(delta: float) -> void:
	if _fx.visible and current != "":
		modulate.a = _fx.flicker()
		var shown := _text.visible_characters
		if shown >= 0 and shown - _typed >= 3:  # a soft tick every few letters
			_typed = shown
			Sfx.play("tick", 0.15)
	if _clock > 0.0:
		_clock -= delta
		if _clock <= 0.0:
			clear()
