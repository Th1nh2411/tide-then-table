class_name OnScreenText
extends CanvasLayer
## Plain words on the screen for the first-person scenes, no box and no
## portrait: a key prompt just under the centre ("E  Ra quán") and one line
## of speech / reading lower down that fades after a while.

var _prompt := Label.new()
var _line := Label.new()
var _line_until := 0.0


func _ready() -> void:
	layer = 20
	for label: Label in [_line, _prompt]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		label.add_theme_constant_override("outline_size", 4)
		label.anchor_left = 0.15
		label.anchor_right = 0.85
		add_child(label)
	_line.anchor_top = 0.64
	_line.anchor_bottom = 0.84
	_line.add_theme_font_size_override("font_size", 14)
	_line.add_theme_color_override("font_color", Color("efe6d2"))
	_prompt.anchor_top = 0.55
	_prompt.anchor_bottom = 0.61
	_prompt.add_theme_font_size_override("font_size", 12)
	_prompt.add_theme_color_override("font_color", Color("f2d98a"))


func _process(_delta: float) -> void:
	if _line.text != "" and Time.get_ticks_msec() / 1000.0 > _line_until:
		_line.text = ""


## Shows the prompt, or hides it with "".
func prompt(text: String) -> void:
	_prompt.text = text


func say(text: String, seconds: float = 3.0) -> void:
	_line.text = text
	_line_until = Time.get_ticks_msec() / 1000.0 + seconds


func saying() -> String:
	return _line.text
