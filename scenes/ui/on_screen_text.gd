class_name OnScreenText
extends CanvasLayer
## Plain words on the screen for the first-person scenes, no box and no
## portrait: the interaction prompt under the crosshair (InteractPrompt,
## "[E] đọc") and spoken / read lines as subtitles through the screen's one
## shared SpeechStrip (Subtitles: typed in, then faded; one queue for every
## source). Its `layer` lifts the shared strip when it speaks.

var _prompt := InteractPrompt.new()


func _ready() -> void:
	layer = 20
	add_child(_prompt)


## Shows `verb` ("đọc") with `key`, or fades it out with "".
func prompt(verb: String, key: String = "E") -> void:
	_prompt.set_text(verb, key)


## The verb asked for now ("" = none).
func prompting() -> String:
	return _prompt.verb


## "Name: words" or plain words; stays at least `seconds`.
func say(text: String, seconds: float = 3.0) -> void:
	if text == "":
		strip().clear()
		return
	_lift().say(text, seconds)


## A background line (a voice far off): dropped when anything else is
## showing or waiting, cut short by a spoken line.
func ambient(text: String, seconds: float = 3.0) -> void:
	_lift().say(text, seconds, {"ambient": true})


## Scripted entry (SpeechStrip.say_as).
func say_as(speaker: String, text: String, opts: Dictionary = {}) -> void:
	_lift().say_as(speaker, text, opts)


func saying() -> String:
	return strip().current


func strip() -> SpeechStrip:
	return SpeechStrip.shared(self)


func _lift() -> SpeechStrip:
	var shared := strip()
	(shared.get_parent() as CanvasLayer).layer = layer
	return shared
