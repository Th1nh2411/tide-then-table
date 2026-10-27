extends Node
## F6: exercise real menu-slot buttons and atomic ingredient replacement.
## --capture-menu saves the empty / picker / filled layouts from a real viewport.

var _failures: int = 0


func _ready() -> void:
	SaveSystem.autosave_off = true
	GameState.reset()
	GameState.day = 4
	var fish: FishCatalog = load("res://data/fish/fish_catalog.tres")
	for species in fish.fish:
		for index in 5:
			GameState.storage.append(InventoryItem.new(species))
	var restaurant := preload("res://scenes/restaurant/restaurant_scene.tscn").instantiate()
	restaurant.arrival_cutscenes.clear()
	add_child(restaurant)
	var panel: MenuSetupPanel = restaurant.get("_menu_panel")
	var plan: MenuPlan = restaurant.get("_plan")
	plan.slots = 5
	plan.kitchen_level = 2
	panel.show()
	panel._refresh()
	_check("five empty selectable slots", panel._cards.size() == 5 and plan.used_slots() == 0)
	await _capture("menu_empty")
	panel._cards[4].choose_button.pressed.emit()
	_check("empty slot opens complete catalog", panel._picker.visible
		and panel._picker._grid.get_child_count() == panel._menu.dishes.size())
	await _capture("menu_picker")
	var dish: DishData = load("res://data/dishes/ca_thu_nuong.tres")
	var before := GameState.storage.size()
	_choose(panel, dish)
	_check("chosen dish stays in clicked slot and reserves one portion", panel._slot_dishes[4] == dish
		and panel._slot_dishes[0] == null and plan.get_portion_count(dish) == 1
		and GameState.storage.size() == before - 1 and not panel._picker.visible)
	_check("selected card shows large image and name", panel._cards[4].picture.texture != null
		and panel._cards[4].picture.custom_minimum_size.y == 64
		and panel._cards[4].dish_name.text == dish.display_name)
	panel._cards[4].plus.pressed.emit()
	_check("plus reserves another portion", plan.get_portion_count(dish) == 2)
	panel._cards[4].minus.pressed.emit()
	panel._cards[4].minus.pressed.emit()
	_check("last minus empties slot and refunds ingredients", panel._slot_dishes[4] == null
		and GameState.storage.size() == before)
	panel._cards[1].choose_button.pressed.emit()
	_choose(panel, dish)
	panel._cards[4].choose_button.pressed.emit()
	var index := panel._menu.dishes.find(dish)
	_check("duplicate dish disabled in another slot", (panel._picker._grid.get_child(index) as Button).disabled)
	panel._picker.cancelled.emit()
	_check("cancel leaves menu intact", plan.used_slots() == 1 and panel._slot_dishes[1] == dish)
	panel.hide()
	panel.show()
	_check("closing and reopening preserves slots", panel._slot_dishes[1] == dish and not panel._picker.visible)
	panel._auto_button.pressed.emit()
	_check("auto fill respects slot capacity", plan.used_slots() <= 5 and plan.used_slots() > 1)
	await _capture("menu_selected")
	_test_replacement(fish, dish)
	print("Menu setup: %s" % ("ALL PASS" if _failures == 0 else "%d FAIL" % _failures))
	SceneRouter.quit_game()


func _choose(panel: MenuSetupPanel, dish: DishData) -> void:
	var index := panel._menu.dishes.find(dish)
	(panel._picker._grid.get_child(index) as Button).pressed.emit()


func _test_replacement(fish: FishCatalog, previous: DishData) -> void:
	var species: FishData
	for entry in fish.fish:
		if entry.id == "ca_thu":
			species = entry
	var storage: Array[InventoryItem] = [InventoryItem.new(species)]
	var original := storage[0]
	var plan := MenuPlan.new(1)
	plan.add_portion(previous, storage)
	var replacement: DishData = load("res://data/dishes/ca_thu_sot_ca.tres")
	_check("full slot can replace using its own reserved fish", storage.is_empty()
		and plan.replace_dish(previous, replacement, storage) and storage.is_empty()
		and plan.get_dishes() == [replacement])
	var unavailable: DishData = load("res://data/dishes/cua_luoc.tres")
	_check("failed replacement keeps original portion", not plan.replace_dish(replacement, unavailable, storage)
		and plan.get_portion_count(replacement) == 1 and storage.is_empty())
	plan.clear(storage)
	_check("replacement preserves ingredient identity", storage.size() == 1 and storage[0] == original)


func _capture(name: String) -> void:
	if "--capture-menu" not in OS.get_cmdline_user_args():
		return
	await get_tree().create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://build/shots")
	var error := get_viewport().get_texture().get_image().save_png("res://build/shots/%s.png" % name)
	_check("capture " + name, error == OK)


func _check(label: String, ok: bool) -> void:
	_failures += 0 if ok else 1
	print(("PASS " if ok else "FAIL ") + label)
