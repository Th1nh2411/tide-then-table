class_name RestaurantDebug3D
extends RefCounted
## Debug keys of the 3D restaurant (debug builds): F4 Nhịp Sóng.

var host: Node3D

func _init(owner: Node3D) -> void:
	host = owner

## True when the key was a debug key and has been used.
func handle(key: InputEventKey) -> bool:
	if not OS.is_debug_build():
		return false
	match key.physical_keycode:
		KEY_F4:
			_toggle_wave()
		_:
			return false
	return true

func _toggle_wave() -> void:
	if WaveMark.has_power():
		GameState.story_flags.erase(WaveMark.FLAG)
	else:
		GameState.set_flag(WaveMark.FLAG)
	host.wave_power.charges = WaveMark.max_charges()
	host._show_note("[debug] Nhịp Sóng: %s" % ("có (C)" if WaveMark.has_power() else "tắt"))
