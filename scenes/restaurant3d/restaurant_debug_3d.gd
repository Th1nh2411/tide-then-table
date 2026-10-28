class_name RestaurantDebug3D
extends RefCounted
## Debug keys of the 3D restaurant (debug builds): F1 fish, F2 drinks, F3 cutscenes, F4 Nhịp Sóng.

var host: Node3D
var _cutscene_index: int = 0

func _init(owner: Node3D) -> void:
	host = owner

## True when the key was a debug key and has been used.
func handle(key: InputEventKey) -> bool:
	if not OS.is_debug_build():
		return false
	match key.physical_keycode:
		KEY_F1:
			if host.shift_running or host.shift_over:
				return false
			_fill_fish()
		KEY_F2:
			_fill_drinks()
		KEY_F3:
			if host.story_bridge.playing:
				return false
			_next_cutscene()
		KEY_F4:
			_toggle_wave()
		_:
			return false
	return true

func _fill_fish() -> void:
	if host.fish_catalog == null:
		return
	for fish in host.fish_catalog.fish:
		GameState.storage.append(InventoryItem.new(fish, 1.0))
	host.planning_panel.refresh()
	host._show_note("[debug] Đã thêm mỗi loại cá vào kho.")

func _fill_drinks() -> void:
	if host.menu == null:
		return
	for dish in host.menu.dishes:
		if dish.instant_serve:
			var units: int = dish.buy_units(dish.has_bulk())
			host.market_stock.add(dish, units)
			host._show_note("[debug] +%d %s %s vào tủ lạnh" % [units, dish.unit_name, dish.display_name])
	if not host.shift_running and not host.shift_over:
		host.planning_panel.refresh()

func _next_cutscene() -> void:
	var cutscenes: Array[Cutscene] = []
	cutscenes.append_array(host.arrival_cutscenes)
	cutscenes.append_array(host.after_shift_cutscenes)
	if cutscenes.is_empty():
		return
	var cutscene: Cutscene = cutscenes[_cutscene_index % cutscenes.size()]
	_cutscene_index += 1
	host._show_note("[debug] cutscene: " + cutscene.id)
	host.story_bridge.play(cutscene)

func _toggle_wave() -> void:
	if WaveMark.has_power():
		GameState.story_flags.erase(WaveMark.FLAG)
	else:
		GameState.set_flag(WaveMark.FLAG)
	host.wave_power.charges = WaveMark.max_charges()
	host._show_note("[debug] Nhịp Sóng: %s" % ("có (C)" if WaveMark.has_power() else "tắt"))
