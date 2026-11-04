class_name OnScreenText
extends CanvasLayer
## Plain words on the screen for the first-person scenes, no box and no
## portrait: the interaction prompt under the crosshair (InteractPrompt,
## "[E] đọc") and spoken / read lines as subtitles (a SpeechStrip: typed in,
## then faded).

var _prompt := InteractPrompt.new()
var _strip := SpeechStrip.new()


func _ready() -> void:
	layer = 20
	add_child(_prompt)
	add_child(_strip)


## Shows `verb` ("đọc") with `key`, or fades it out with "".
func prompt(verb: String, key: String = "E") -> void:
	_prompt.set_text(verb, key)


## The verb asked for now ("" = none).
func prompting() -> String:
	return _prompt.verb


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
