class_name SeaHudView3D
extends Control
## The 3D sea's screen layer: no plank, clock or meters (the lamp stays lit,
## the basket shows its fish). Only the dock prompt (InteractPrompt "[R] lên
## bờ", under the crosshair like every other prompt) and Rin's lines on the
## screen's shared SpeechStrip (unnamed ones are Rin's). No key card: the
## horror build shows no control hints (the pause menu's settings list the keys).
## SeaHud3D.update calls `refresh` every frame.

const SCREEN := Vector2(640, 360)

var speech: SpeechStrip
var _said: String = ""  # the sea message this HUD last put on the strip
var _prompt: InteractPrompt


func _ready() -> void:
	size = SCREEN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt = InteractPrompt.new()
	add_child(_prompt)
	speech = SpeechStrip.shared(self)


func refresh(sea: SeaScene3D) -> void:
	_prompt.set_text(dock_prompt(sea), "R")
	if sea.message.text != _said:
		speech.retract(_said)  # only this HUD's own line, never another source's
		_said = sea.message.text
		if _said != "":
			speech.say(_said, 0.0, {"fallback": "Rin"})


## "lên bờ" at the dock, unless the fish-in-hand prompt has the crosshair.
static func dock_prompt(sea: SeaScene3D) -> String:
	if sea.ending or sea.fishing or not sea._at_dock():
		return ""
	if sea.rod and sea.rod.basket_prompt():
		return ""
	return "lên bờ"
