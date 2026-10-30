class_name MarketPanel3D
extends PanelContainer
## Cô Năm's grocery in the 3D restaurant: one paper tile per good (big
## picture, stock dots, a coin price button for one pack and a cheaper bulk
## button), money counting up/down in the header. Buying goes through
## host._buy_market(dish, bulk); the host refreshes us.

signal closed

const INK := Color("2a2230")

var host: Node3D
var _money: Label
var _tiles: HBoxContainer
var _shown_money: int = -1


func _init(owner: Node3D) -> void:
	host = owner
	position = Vector2(150, 70)
	custom_minimum_size = Vector2(340, 0)
	theme = RestaurantPanels3D.ui_theme()
	theme_type_variation = &"WoodPanel"  # Cô Năm's counter
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 5)
	box.add_child(header)
	header.add_child(UiIcons.make("basket", 18, UiIcons.GOLD))
	var title := Label.new()
	title.text = "CÔ NĂM"
	title.theme_type_variation = &"TitleLabel"
	title.add_theme_font_size_override("font_size", 16)
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.add_child(UiIcons.make("money", 15, UiIcons.GOLD))
	_money = Label.new()
	_money.theme_type_variation = &"TitleLabel"
	_money.add_theme_font_size_override("font_size", 16)
	header.add_child(_money)
	var close_button := UiIcons.icon_button("close", "Đóng (Esc)", 12)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(func() -> void:
		hide()
		closed.emit())
	header.add_child(close_button)
	_tiles = HBoxContainer.new()
	_tiles.alignment = BoxContainer.ALIGNMENT_CENTER
	_tiles.add_theme_constant_override("separation", 8)
	box.add_child(_tiles)
	hide()


func open() -> void:
	refresh()
	show()
	UiFx.pop_in(self)
	UiFx.stagger(_tiles, 0.07, 0.08)


func refresh() -> void:
	if _shown_money >= 0 and _shown_money != GameState.money and visible:
		UiFx.count_to(_money, _shown_money, GameState.money, "%dk", 0.35)
		UiFx.bounce(_money, 0.12)
	else:
		_money.text = "%dk" % GameState.money
	_shown_money = GameState.money
	for old in _tiles.get_children():
		_tiles.remove_child(old)
		old.queue_free()
	for dish: DishData in host.menu.dishes:
		if dish.is_market_dish() and dish.unlock_day <= GameState.day:
			_tiles.add_child(_tile(dish))


func _tile(dish: DishData) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.theme_type_variation = &"CardboardPanel"
	UiFx.tilt(tile, 1.5 if _tiles.get_child_count() % 2 == 0 else -2.0)
	tile.tooltip_text = dish.display_name
	tile.custom_minimum_size.x = 150
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	tile.add_child(box)
	var picture := TextureRect.new()
	picture.texture = Art.texture("dishes/" + dish.id)
	picture.custom_minimum_size = Vector2(60, 50)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box.add_child(picture)
	var name_label := Label.new()
	name_label.theme_type_variation = &"CardLabel"
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text = dish.display_name
	box.add_child(name_label)
	# Stock: dots (a bar past 10) + the number.
	var stock_row := HBoxContainer.new()
	stock_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stock_row.add_theme_constant_override("separation", 4)
	box.add_child(stock_row)
	var portions: int = host.market_stock.portions(dish)
	var dots := PipBar.new()
	dots.pip_color = Color("de9e41")
	dots.empty_color = Color(INK, 0.3)
	dots.max_pips = 10
	dots.set_count(portions, maxi(portions, 10))
	stock_row.add_child(dots)
	var count := Label.new()
	count.theme_type_variation = &"CardLabel"
	count.add_theme_font_size_override("font_size", 9)
	count.text = "x%d" % portions
	stock_row.add_child(count)
	var buys := HBoxContainer.new()
	buys.alignment = BoxContainer.ALIGNMENT_CENTER
	buys.add_theme_constant_override("separation", 4)
	box.add_child(buys)
	buys.add_child(_buy_button(dish, false))
	if dish.has_bulk():
		buys.add_child(_buy_button(dish, true))
	return tile


## Handwritten price tags. Single: "+1 · 10k"; bulk in red ink: "+10 · 80k".
func _buy_button(dish: DishData, bulk: bool) -> Button:
	var button := UiIcons.dress(Button.new(), "money", 11, Color("be772b"))
	button.theme_type_variation = &"PaperButton"
	var packs := dish.bulk_packs if bulk else 1
	button.text = "+%d · %dk" % [packs, dish.buy_cost(bulk)]
	button.tooltip_text = dish.buy_text(bulk)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 9)
	if bulk:
		button.add_theme_color_override("font_color", Color("a53030"))
		button.add_theme_color_override("font_hover_color", Color("a53030"))
	button.disabled = GameState.money < dish.buy_cost(bulk)
	button.pressed.connect(host._buy_market.bind(dish, bulk))
	UiFx.hover_lift(button, 0.06)
	return button
