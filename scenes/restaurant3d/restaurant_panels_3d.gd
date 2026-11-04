class_name RestaurantPanels3D
extends RefCounted
## The restaurant's 2D overlay: spoken lines as subtitles and the E prompt
## under the crosshair (InteractPrompt, the one prompt style of the game).

var host: Node3D
var _note: SpeechStrip
var _prompt: InteractPrompt


## Flat stand-in for the theme's dark board (square, 2 px ink outline, no
## blur) for overlays that set a panel override.
static func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("151d28")
	style.border_color = Color("090a14")
	style.set_border_width_all(2)
	style.set_content_margin_all(8)
	style.anti_aliasing = false
	return style


## Only the text size for the 3D overlays; fonts and colours come from the
## project theme.
static func ui_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 12
	return theme


func _init(owner: Node3D) -> void:
	host = owner


func build() -> void:
	var layer := CanvasLayer.new()
	host.add_child(layer)
	_note = SpeechStrip.shared(host)
	_prompt = InteractPrompt.new()
	layer.add_child(_prompt)


## Subtitle line at the bottom (the screen's shared strip): "Bảo: ..." shows
## "Bảo:" above it in his colour.
func say(words: String) -> void:
	_note.say(words, 4.0)


## Kept for the scene's frame loop; the subtitle times itself out.
func tick(_delta: float) -> void:
	pass


## The verb E would do now ("" = nothing): "[E] rót bia" -> "rót bia".
static func verb_of(hint: Dictionary) -> String:
	if hint.is_empty() or not str(hint["words"]).begins_with("[E]"):
		return ""
	return str(hint["words"]).trim_prefix("[E]").strip_edges()


## The prompt under the crosshair; hidden while something else owns the screen.
func refresh_prompt(verb: String, blocked: bool) -> void:
	_prompt.set_text("" if blocked else verb)


## The verb on screen now (tests).
func prompting() -> String:
	return _prompt.verb
