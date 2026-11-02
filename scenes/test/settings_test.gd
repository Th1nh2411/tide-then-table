extends Node
## GameSettings (scratch file): defaults, save + reload, mouse speed / invert,
## clamping, keys written by others kept; SettingsPanel + PauseMenu build.

const SCRATCH := "user://settings_test.cfg"


func _ready() -> void:
	var failures := 0
	var real_before := FileAccess.get_file_as_string(GameSettings.PATH)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))
	GameSettings.path = SCRATCH
	GameSettings.clear_cache()
	failures += _check("defaults: PSX on, sensitivity 1, no invert",
		GameSettings.psx() and is_equal_approx(GameSettings.mouse_sensitivity(), 1.0) and not GameSettings.invert_y())
	failures += _check("mouse speed = base", GameSettings.mouse_speed().is_equal_approx(Vector2.ONE * GameSettings.BASE_MOUSE_SPEED))
	var other := ConfigFile.new()
	other.set_value("other", "kept", 7)
	other.save(SCRATCH)
	GameSettings.clear_cache()
	GameSettings.set_value("controls", "mouse_sensitivity", 2.0)
	GameSettings.set_value("controls", "invert_y", true)
	GameSettings.set_psx(false)
	GameSettings.set_volume(0.5)
	GameSettings.clear_cache()
	var speed := GameSettings.mouse_speed()
	failures += _check("saved values come back", not GameSettings.psx() and is_equal_approx(GameSettings.volume(), 0.5)
		and is_equal_approx(speed.x, GameSettings.BASE_MOUSE_SPEED * 2.0) and speed.y < 0.0)
	var disk := ConfigFile.new()
	disk.load(SCRATCH)
	failures += _check("other keys kept", int(disk.get_value("other", "kept", 0)) == 7)
	GameSettings.set_value("controls", "mouse_sensitivity", 99.0)
	failures += _check("sensitivity clamped", is_equal_approx(GameSettings.mouse_sensitivity(), GameSettings.SENSITIVITY_MAX))
	failures += _check("no PSX node headless", SceneRouter.get_node_or_null("PsxLook") == null)
	var panel := SettingsPanel.new()
	add_child(panel)
	panel.open()
	failures += _check("settings panel opens", panel.visible)
	panel.close()
	var pause := (load(PauseMenu.SCENE_PATH) as PackedScene).instantiate()
	add_child(pause)
	failures += _check("pause menu joins its group", get_tree().get_nodes_in_group(PauseMenu.GROUP).size() == 1)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))
	failures += _check("player's settings.cfg untouched", FileAccess.get_file_as_string(GameSettings.PATH) == real_before)
	GameSettings.path = GameSettings.PATH
	GameSettings.clear_cache()
	print("settings_test: %s" % ("ALL PASS" if failures == 0 else "%d FAIL" % failures))
	get_tree().quit()


func _check(label: String, ok: bool) -> int:
	print(("PASS " if ok else "FAIL ") + label)
	return 0 if ok else 1
