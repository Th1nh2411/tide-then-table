class_name RestaurantPanels3D
extends RefCounted
## The restaurant's 2D overlay: note line, planning panel, Cô Năm's market, shift summary, action hint.

var host: Node3D
var planning: MenuPanel3D
var market_panel: PanelContainer
var summary_text: Label
var _market_list: VBoxContainer
var _summary_panel: PanelContainer
var _note: Label
var _note_clock: float = 0.0
var _prompt: PanelContainer
var _prompt_text: Label

static func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("202c38")
	style.border_color = Color("697575")
	style.set_border_width_all(1)
	style.set_content_margin_all(5)
	style.set_corner_radius_all(3)
	return style

static func ui_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 12
	theme.set_color("font_color", "Label", Color("e9dfc5"))
	theme.set_color("font_color", "Button", Color("e9dfc5"))
	return theme

func _init(owner: Node3D) -> void:
	host = owner

func build() -> void:
	var layer := CanvasLayer.new()
	host.add_child(layer)
	_note = Label.new()
	_note.position = Vector2(12, 326)
	_note.add_theme_font_size_override("font_size", 11)
	_note.add_theme_stylebox_override("normal", panel_style())
	_note.custom_minimum_size.x = 610
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.add_theme_color_override("font_color", Color("e7d5b3"))
	layer.add_child(_note)
	planning = MenuPanel3D.new()
	layer.add_child(planning)
	market_panel = PanelContainer.new()
	market_panel.position = Vector2(170, 72)
	market_panel.custom_minimum_size = Vector2(300, 0)
	layer.add_child(market_panel)
	_market_list = VBoxContainer.new()
	market_panel.add_child(_market_list)
	market_panel.hide()
	_summary_panel = PanelContainer.new()
	_summary_panel.position = Vector2(135, 80)
	_summary_panel.custom_minimum_size = Vector2(370, 110)
	layer.add_child(_summary_panel)
	var summary_box := VBoxContainer.new()
	_summary_panel.add_child(summary_box)
	summary_text = Label.new()
	summary_box.add_child(summary_text)
	var close_summary := Button.new()
	close_summary.text = "Đóng"
	close_summary.pressed.connect(_summary_panel.hide)
	summary_box.add_child(close_summary)
	_summary_panel.hide()
	for panel: PanelContainer in [market_panel, _summary_panel]:
		panel.theme = ui_theme()
		panel.add_theme_stylebox_override("panel", panel_style())
	_prompt = PanelContainer.new()
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.theme = ui_theme()
	_prompt.add_theme_stylebox_override("panel", panel_style())
	layer.add_child(_prompt)
	_prompt_text = Label.new()
	_prompt_text.add_theme_color_override("font_color", Color("f0d39b"))
	_prompt.add_child(_prompt_text)
	_prompt.hide()

func summary_visible() -> bool:
	return _summary_panel != null and _summary_panel.visible

func say(words: String) -> void:
	_note.text = words
	_note_clock = 4.0

func tick(delta: float) -> void:
	if _note_clock > 0.0:
		_note_clock -= delta
		if _note_clock <= 0.0:
			_note.text = ""

func show_summary(words: String) -> void:
	summary_text.text = words
	_summary_panel.show()

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
	refresh_market()
	market_panel.show()

func refresh_market() -> void:
	for old in _market_list.get_children():
		old.queue_free()
	var title := Label.new()
	title.text = "CÔ NĂM • TẠP HOÁ  |  Tiền: %dk" % GameState.money
	_market_list.add_child(title)
	for dish in host.menu.dishes:
		if not dish.is_market_dish() or dish.unlock_day > GameState.day:
			continue
		var row := HBoxContainer.new()
		_market_list.add_child(row)
		var buy := Button.new()
		buy.text = "%s  •  %dk  (còn %d)" % [dish.display_name, dish.market_cost, host.market_stock.portions(dish)]
		buy.disabled = GameState.money < dish.market_cost
		buy.pressed.connect(host._buy_market.bind(dish, false))
		row.add_child(buy)
		if dish.has_bulk():
			var bulk := Button.new()
			bulk.text = "Lô %dk" % dish.bulk_cost
			bulk.disabled = GameState.money < dish.bulk_cost
			bulk.pressed.connect(host._buy_market.bind(dish, true))
			row.add_child(bulk)
	var close := Button.new()
	close.text = "Đóng"
	close.pressed.connect(func() -> void:
		market_panel.hide()
		if not host.shift_running and not host.shift_over:
			planning.open())
	_market_list.add_child(close)
