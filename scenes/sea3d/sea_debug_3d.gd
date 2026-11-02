class_name SeaDebug3D
extends RefCounted
## Debug keys of the 3D sea (debug builds): F4 toggles Nhịp Sóng, F2 opens the fog, 1-3 switch the boat
## (thúng / ghe chèo / ghe máy); F2 and 1-3 reload the scene.


## Returns true when `key` was a debug key and has been handled.
static func handle(sea: SeaScene3D, key: InputEventKey) -> bool:
	if not OS.is_debug_build() or key == null or not key.pressed or key.echo:
		return false
	match key.physical_keycode:
		KEY_F4:
			if WaveMark.has_power():
				GameState.story_flags.erase(WaveMark.FLAG)
			else:
				GameState.set_flag(WaveMark.FLAG)
			if sea.overlay:
				var power := sea.overlay.get("wave_power") as WavePower
				if power:
					power.charges = WaveMark.max_charges()
			sea._say("[debug] Nhịp Sóng: %s" % ("có (C)" if WaveMark.has_power() else "tắt"), 2.0)
			return true
		KEY_1, KEY_2, KEY_3:
			if sea.boat_upgrade == null:
				return false
			GameState.upgrade_levels[sea.boat_upgrade.id] = int(key.physical_keycode - KEY_1)
			sea.get_tree().reload_current_scene.call_deferred()
			return true
		KEY_F2:
			# Pretend the omen happened yesterday and reload to open the fog.
			GameState.set_flag(Story.OMEN_DAY_FLAG, GameState.day - 1)
			sea.get_tree().reload_current_scene.call_deferred()
			return true
	return false
