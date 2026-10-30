class_name MenuPantryStrip3D
extends HBoxContainer
## Market goods in stock on the menu board's button row: a tiny picture +
## "x3" per goods sold today (red when out), right-aligned.


func _init() -> void:
	add_theme_constant_override("separation", 4)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alignment = BoxContainer.ALIGNMENT_END


func fill(menu: DishCatalog, stock: MarketStock) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for dish in menu.dishes:
		if dish.is_market_dish() and dish.unlock_day <= GameState.day:
			add_child(_entry(dish, stock.portions(dish)))


func _entry(dish: DishData, portions: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 1)
	row.tooltip_text = dish.display_name
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var picture := TextureRect.new()
	picture.texture = Art.texture("dishes/" + dish.id)
	picture.custom_minimum_size = Vector2(18, 18)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(picture)
	var count := Label.new()
	count.text = "x%d" % portions
	count.theme_type_variation = &"ChalkLabel"
	count.add_theme_font_size_override("font_size", 10)
	if portions == 0:
		count.add_theme_color_override("font_color", Color("f0a08a"))
	row.add_child(count)
	return row
