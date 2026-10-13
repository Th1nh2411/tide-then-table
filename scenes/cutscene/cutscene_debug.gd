class_name CutsceneDebug
extends Node
## Debug-build keys for the story (sea and restaurant): F3 plays this scene's
## cutscenes one after another, ignoring their day / flag / once conditions;
## F4 gives / takes Nhịp Sóng (WaveMark) and refills its uses.

signal message_requested(text: String)

var player: CutscenePlayer
var cutscenes: Array[Cutscene] = []

var _next: int = 0


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not OS.is_debug_build() or key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_F3 and not cutscenes.is_empty() and not player.playing:
		get_viewport().set_input_as_handled()
		var cutscene := cutscenes[_next % cutscenes.size()]
		var text := "[debug] cutscene %d/%d: %s" % [_next % cutscenes.size() + 1, cutscenes.size(), cutscene.id]
		print(text)  # the HUD hides while it plays
		message_requested.emit(text)
		_next += 1
		player.play(cutscene)
	elif key.physical_keycode == KEY_F4:
		get_viewport().set_input_as_handled()
		if WaveMark.has_power():
			GameState.story_flags.erase(WaveMark.FLAG)
		else:
			GameState.set_flag(WaveMark.FLAG)
		for node in get_tree().get_nodes_in_group("wave_power"):
			(node as WavePower).charges = WaveMark.max_charges()
		message_requested.emit("[debug] Nhịp Sóng: %s" % ("có (C)" if WaveMark.has_power() else "tắt"))
