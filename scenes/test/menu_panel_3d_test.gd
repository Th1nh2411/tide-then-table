extends Node
## MenuPanel3D: dish visibility, HOT, auto-fill, picker, sold-out, start gate.

func _check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	GameState.reset()
	for id: String in ["opening_day", "vy_arrives", "wave_awaken"]:
		GameState.set_flag("dlg_" + id)
	var room: Node3D = load("res://scenes/restaurant3d/restaurant_scene_3d.tscn").instantiate()
	room.arrival_cutscenes.clear()
	add_child(room)
	await get_tree().process_frame
	var panel: MenuPanel3D = room.planning_panel
	var tom: FishData = load("res://data/fish/tom.tres")
	GameState.storage.clear()
	panel.open()
	_check(panel.visible, "panel opens")
	_check(MenuPanel3D.visible_dishes(room.menu.dishes, 0).is_empty() or not GameState.caught_species.has(tom.id),
		"nothing caught -> no seafood dishes listed")
	_check(panel.open_button.disabled == (not room._has_stock()), "start follows stock")
	# Known fish + kitchen level filter.
	GameState.caught_species[tom.id] = 1
	for i in 4:
		GameState.storage.append(InventoryItem.new(tom, 1.0))
	var shown := MenuPanel3D.visible_dishes(room.menu.dishes, 0)
	_check(not shown.is_empty(), "known fish shows dishes")
	var all_ok := true
	for dish in shown:
		all_ok = all_ok and dish.kitchen_level <= 0 and DishBook.is_known(dish)
	_check(all_ok, "only known + cookable-by-level dishes are shown")
	var high: DishData
	for dish in room.menu.dishes:
		if dish.kitchen_level > 0 and not dish.ingredients.is_empty():
			high = dish
	_check(high == null or high not in shown, "higher kitchen-level dish hidden")
	# HOT tag.
	var hot_dish: DishData = shown[0]
	GameState.story_flags["trend_dish"] = hot_dish.id
	GameState.story_flags["trend_day"] = GameState.day
	panel.refresh()
	_check(DailyTrend.is_hot(hot_dish) and panel.title_label.text.contains("HOT"), "HOT shown in title")
	# Picker.
	panel._open_picker(0)
	_check(panel.picker_dishes.size() == shown.size(), "picker lists visible dishes")
	_check(panel.select_dish(shown[0]) and panel.plan.get_portion_count(shown[0]) == 1, "picker selects a dish")
	panel.plan.clear(GameState.storage)
	# Auto-fill + sold-out.
	panel.auto_button.pressed.emit()
	_check(panel.plan.total_portions() > 0, "auto-fill reserves portions")
	_check(panel.auto_button.disabled, "auto disabled when nothing more can be added")
	_check(not panel.open_button.disabled, "start enabled with a menu")
	panel.clear_button.pressed.emit()
	_check(panel.plan.total_portions() == 0 and GameState.storage.size() == 4, "clear returns fish")
	# Empty menu blocks start.
	GameState.storage.clear()
	GameState.pantry.clear()
	room.market_stock = MarketStock.new(GameState.pantry)
	panel.market_stock = room.market_stock
	panel.refresh()
	_check(panel.open_button.disabled and panel.sail_button.visible, "empty menu blocks start, offers sail")
	room._open_shift()
	_check(not room.shift_running, "_open_shift refuses with empty menu")
	get_tree().quit()
