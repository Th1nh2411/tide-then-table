class_name RestaurantPanels3D
extends RefCounted
## The restaurant's 2D overlay: note line, planning panel, Cô Năm's market
## (MarketPanel3D), shift summary, action hint. Looks come from the project
## theme (assets/ui/game_theme.tres).

var host: Node3D
var planning: MenuPanel3D
var market_panel: PanelContainer
var summary_text: Label
var _market: MarketPanel3D
var _summary_panel: PanelContainer
var _note_strip: PanelContainer
var _note_speaker: Label
var _note: Label
var _note_clock: float = 0.0
var _prompt: PanelContainer
var _prompt_text: Label


## Flat stand-in for the theme's dark board (square, 2 px ink outline, no
## blur) for overlays that set a panel override (renovation preview). The
## planning panel uses the "ChalkPanel" material instead.
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
	planning = MenuPanel3D.new()
	layer.add_child(planning)
	_market = MarketPanel3D.new(host)
	_market.closed.connect(func() -> void:
		if not host.shift_running and not host.shift_over:
			planning.open())
	market_panel = _market
	layer.add_child(_market)
	_summary_panel = PanelContainer.new()
	_summary_panel.theme_type_variation = &"PaperPanel"  # receipt
	_summary_panel.theme = ui_theme()
	_summary_panel.position = Vector2(135, 80)
	_summary_panel.custom_minimum_size = Vector2(370, 110)
	layer.add_child(_summary_panel)
	var summary_box := VBoxContainer.new()
	summary_box.add_theme_constant_override("separation", 6)
	_summary_panel.add_child(summary_box)
	summary_text = Label.new()
	summary_text.theme_type_variation = &"InkLabel"
	summary_box.add_child(summary_text)
	var close_summary := Button.new()
	close_summary.text = "Đóng"
	close_summary.theme_type_variation = &"AccentButton"
	close_summary.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_summary.pressed.connect(_summary_panel.hide)
	summary_box.add_child(close_summary)
	_summary_panel.hide()
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


## Bottom speech strip: "Bảo: ..." puts the speaker's name in gold.
func _build_note(layer: CanvasLayer) -> void:
	_note_strip = PanelContainer.new()
	_note_strip.theme_type_variation = &"StripPanel"
	_note_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_note_strip.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_note_strip.offset_left = 12
	_note_strip.offset_right = -12
	_note_strip.offset_top = -30
	_note_strip.offset_bottom = -8
	_note_strip.grow_vertical = Control.GROW_DIRECTION_BEGIN
	layer.add_child(_note_strip)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_note_strip.add_child(row)
	_note_speaker = Label.new()
	_note_speaker.theme_type_variation = &"HeadingLabel"
	_note_speaker.add_theme_font_size_override("font_size", 12)
	_note_speaker.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_note_speaker)
	_note = Label.new()
	_note.theme_type_variation = &"InkLabel"
	_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_note.custom_minimum_size.x = 520  # autowrap needs a width or it measures tall
	_note.add_theme_font_size_override("font_size", 11)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(_note)
	_note_strip.hide()


func summary_visible() -> bool:
	return _summary_panel != null and _summary_panel.visible


func say(words: String) -> void:
	var speaker := words.get_slice(":", 0)
	var spoken := speaker != words and speaker.length() <= 10
	_note_speaker.visible = spoken
	_note_speaker.text = speaker if spoken else ""
	_note.text = words.substr(speaker.length() + 1).strip_edges() if spoken else words
	_note_clock = 4.0
	var fresh := not _note_strip.visible or _note_strip.modulate.a < 1.0
	_note_strip.show()
	_note_strip.modulate.a = 1.0
	if fresh:
		UiFx.tilt(_note_strip, -0.4)
		UiFx.settle(_note_strip, Vector2(0, 18), 0.0, -1.5)
	else:
		UiFx.flash(_note, Color(1.4, 1.3, 1.0))


func tick(delta: float) -> void:
	if _note_clock > 0.0:
		_note_clock -= delta
		if _note_clock <= 0.0:
			var fade := _note_strip.create_tween()
			fade.tween_property(_note_strip, "modulate:a", 0.0, 0.3)
			fade.tween_callback(func() -> void:
				if _note_clock <= 0.0:
					_note.text = ""
					_note_strip.hide())


func show_summary(words: String) -> void:
	summary_text.text = words
	_summary_panel.show()
	UiFx.pop_in(_summary_panel)


## Action hint over the thing E acts on; hidden while something else owns the screen.
func refresh_prompt(camera: Camera3D, blocked: bool) -> void:
	_prompt.hide()
	if blocked:
		return
	var hint: Dictionary = RestaurantPrompt3D.describe(host)
	if hint.is_empty():
		return
	_prompt_text.text = str(hint["words"])
	_prompt.reset_size()
	var screen: Vector2 = camera.unproject_position(hint["at"])
	var size: Vector2 = host.get_viewport().get_visible_rect().size
	_prompt.position = Vector2(clampf(screen.x - _prompt.size.x * 0.5, 6.0, maxf(6.0, size.x - _prompt.size.x - 6.0)), clampf(screen.y, 32.0, size.y - 55.0))
	_prompt.show()


func open_market() -> void:
	planning.hide()
	_market.open()


func refresh_market() -> void:
	_market.refresh()
