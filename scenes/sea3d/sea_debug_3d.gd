class_name SeaDebug3D
extends RefCounted
## Debug keys of the 3D sea (debug builds): F2 opens the fog (reloads the scene).


## Returns true when `key` was a debug key and has been handled.
static func handle(sea: SeaScene3D, key: InputEventKey) -> bool:
	if not OS.is_debug_build() or key == null or not key.pressed or key.echo:
		return false
	if key.physical_keycode == KEY_F2:
		# Pretend the omen happened yesterday and reload to open the fog.
		GameState.set_flag(Story.OMEN_DAY_FLAG, GameState.day - 1)
		sea.get_tree().reload_current_scene.call_deferred()
		return true
	return false
