extends Node
## Sound captions (CaptionLayer + SoundCaptions + CaptionDirector): story
## sounds captioned through Sfx, grey italic in [brackets], direction word
## for placed sounds, positional-only / cooldown rules, the setting "Phụ đề
## âm thanh" (scratch settings file) hides them.

const SCRATCH := "user://caption_test.cfg"

var _failures: int = 0


func _ready() -> void:
	var real_before := FileAccess.get_file_as_string(GameSettings.PATH)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))
	GameSettings.path = SCRATCH
	GameSettings.clear_cache()
	_check("setting on by default", GameSettings.sound_captions())
	_direction_checks()
	_table_checks()
	var layer := CaptionLayer.ensure(get_tree())
	await get_tree().process_frame
	_check("one caption layer under the root", layer.get_parent() == get_tree().root and CaptionLayer.ensure(get_tree()) == layer)
	Sfx.play("knock3", 0.0)
	_check("knock captioned", layer.current == "[tiếng gõ cửa, ba tiếng]")
	var font := layer._label.get_theme_font("font") as FontVariation
	_check("caption style: grey italic", font != null and font.variation_transform.y.x > 0.0
		and layer._label.get_theme_color("font_color") == layer.tuning.caption_color)
	layer.current = ""
	Sfx.play("knock3", 0.0)
	_check("same sound again soon: no new caption", layer.current == "")
	Sfx.play("click")
	Sfx.step("wood")
	_check("UI clicks / Rin's own steps: none", layer.current == "")
	var camera := Camera3D.new()
	var world := Node3D.new()
	add_child(world)
	world.add_child(camera)
	camera.current = true
	await get_tree().process_frame
	Sfx.play_at("step_wood_2", Vector3(0, 0, 6), world)
	_check("placed step: direction from the camera", layer.current == "[tiếng bước chân trên ván — sau lưng]")
	Sfx.play_at("call", Vector3(-9, 0, -1), world)
	_check("call to the left", layer.current == "[tiếng ai gọi, vọng xa — bên trái]")
	var strip := SpeechStrip.new()
	add_child(strip)
	strip.caption("[tiếng nước, sau lưng]")
	_check("SpeechStrip.caption", layer.current == "[tiếng nước, sau lưng]")
	layer._process(layer.tuning.caption_seconds + 0.1)
	_check("caption times out", layer.current == "")
	GameSettings.set_sound_captions(false)
	Sfx.play("whisper", 0.0)
	strip.caption("tiếng gì đó")
	_check("setting off hides captions", layer.current == "")
	GameSettings.clear_cache()
	_check("setting saved", not GameSettings.sound_captions())
	var panel := SettingsPanel.new()
	add_child(panel)
	_check("settings panel has the toggle", panel._toggles.has("sound_captions"))
	GameSettings.path = GameSettings.PATH
	GameSettings.clear_cache()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))
	_check("real settings file untouched", FileAccess.get_file_as_string(GameSettings.PATH) == real_before)
	print("caption_test: %s" % ("ALL PASS" if _failures == 0 else "%d FAIL" % _failures))
	get_tree().quit()


func _direction_checks() -> void:
	var eye := Transform3D.IDENTITY  # looking down -z
	_check("front", CaptionDirector.direction(eye, Vector3(0, 0, -5)) == "phía trước")
	_check("behind", CaptionDirector.direction(eye, Vector3(0, 1, 5)) == "sau lưng")
	_check("right / left", CaptionDirector.direction(eye, Vector3(5, 0, 0)) == "bên phải"
		and CaptionDirector.direction(eye, Vector3(-5, 0, 0)) == "bên trái")
	var turned := Transform3D(Basis(Vector3.UP, PI), Vector3(10, 0, 0))  # at x 10 looking +z
	_check("turned camera", CaptionDirector.direction(turned, Vector3(10, 0, 4)) == "phía trước")
	_check("compose adds brackets once", CaptionDirector.compose("[a]", "bên trái") == "[a — bên trái]")


func _table_checks() -> void:
	var table := CaptionLayer.CAPTIONS
	_check("splash only when placed", table.text_for("splash", false, true) == "" and table.text_for("splash", true, true) != "")
	_check("knock: hull at sea, door ashore", table.text_for("knock3", false, true).contains("mạn thúng")
		and table.text_for("knock3", false, false).contains("cửa"))
	_check("no caption for clicks", table.text_for("click", false, false) == "")
	for sound: String in table.captions:
		_check("captioned sound exists: " + sound, Sfx.has_sound(sound))


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
