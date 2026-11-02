class_name RestaurantPanels3D
extends RefCounted
## The restaurant's 2D overlay: note line, shift summary, action hint. Looks come from the project
## theme (assets/ui/game_theme.tres).

var host: Node3D
## Full summary text (the receipt's tooltip; kept for tests / logs).
var summary_text: Label
var receipt: ShiftReceipt3D
var _note: SpeechStrip
var _prompt: PanelContainer
var _prompt_text: Label


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
	_build_note(layer)
	receipt = ShiftReceipt3D.new()
	layer.add_child(receipt)
	summary_text = receipt.summary_text
	_prompt = PanelContainer.new()
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.theme = ui_theme()
	_prompt.theme_type_variation = &"RowPanel"
	layer.add_child(_prompt)
	_prompt_text = Label.new()
	_prompt_text.theme_type_variation = &"CardLabel"
	_prompt_text.add_theme_font_size_override("font_size", 11)
	_prompt.add_child(_prompt_text)
	_prompt.hide()


## Bottom speech strip: "Bảo: ..." puts the speaker's name in red ink.
func _build_note(layer: CanvasLayer) -> void:
	_note = SpeechStrip.new()
	_note.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_note.offset_left = 12
	_note.offset_right = -12
	_note.offset_top = -30
	_note.offset_bottom = -8
	_note.grow_vertical = Control.GROW_DIRECTION_BEGIN
	layer.add_child(_note)


func summary_visible() -> bool:
	return receipt != null and receipt.visible


func say(words: String) -> void:
	_note.say(words, 4.0)


## Kept for the scene's frame loop; the strip times itself out.
func tick(_delta: float) -> void:
	pass


## Prints the shift receipt. `figures` / `results`: see ShiftReceiptRows.
func show_summary(words: String, figures: Dictionary = {}, results: Dictionary = {}) -> void:
	var stars: int = int(figures.get("stars", GameState.last_rating))
	receipt.open(words, ShiftReceiptRows.build(figures, results), ShiftReceiptRows.chart(GameState.day_history),
		ShiftReceiptRows.chart_days(GameState.day_history), stars)


## Action hint over the thing E acts on; hidden while something else owns the screen.
func refresh_prompt(camera: Camera3D, blocked: bool) -> void:
	_prompt.hide()
	if blocked:
		return
	var hint: Dictionary = RestaurantPrompt3D.describe(host)
	# Only the key when E would act; where to go is shown by the goal pulse.
	if hint.is_empty() or not str(hint["words"]).begins_with("[E]"):
		return
	_prompt_text.text = "E"
	_prompt.tooltip_text = str(hint["words"]).trim_prefix("[E] ")
	_prompt.reset_size()
	var screen: Vector2 = camera.unproject_position(hint["at"])
	var size: Vector2 = host.get_viewport().get_visible_rect().size
	_prompt.position = Vector2(clampf(screen.x - _prompt.size.x * 0.5, 6.0, maxf(6.0, size.x - _prompt.size.x - 6.0)), clampf(screen.y, 32.0, size.y - 55.0))
	_prompt.show()

