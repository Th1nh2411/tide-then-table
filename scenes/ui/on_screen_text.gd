class_name OnScreenText
extends CanvasLayer
## Plain words on the screen for the first-person scenes, no box and no
## portrait: a key prompt just under the centre ("E  Ra quán") and spoken /
## read lines as subtitles (a SpeechStrip: typed in, then faded).

var _prompt := Label.new()
var _strip := SpeechStrip.new()


func _ready() -> void:
	layer = 20
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_prompt.add_theme_constant_override("outline_size", 4)
	_prompt.anchor_left = 0.15
	_prompt.anchor_right = 0.85
	_prompt.anchor_top = 0.55
	_prompt.anchor_bottom = 0.61
	_prompt.add_theme_font_size_override("font_size", 12)
	_prompt.add_theme_color_override("font_color", Color("f2d98a"))
	add_child(_prompt)
	add_child(_strip)


## Shows the prompt, or hides it with "".
func prompt(text: String) -> void:
	_prompt.text = text


## "Name: words" or plain words; stays at least `seconds`.
func say(text: String, seconds: float = 3.0) -> void:
	if text == "":
		_strip.clear()
		return
	_strip.say(text, seconds)


## Scripted entry (SpeechStrip.say_as).
func say_as(speaker: String, text: String, opts: Dictionary = {}) -> void:
	_strip.say_as(speaker, text, opts)


func saying() -> String:
	return _strip.current


func strip() -> SpeechStrip:
	return _strip
