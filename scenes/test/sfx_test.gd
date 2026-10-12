extends Node
## Standalone test for the code-built sounds (run with F6): every sound and
## loop builds, loops are marked looping, play / hold / ambience don't fail.


func _ready() -> void:
	var failures := 0
	for sound: String in Sfx.SOUNDS:
		var wav := SfxSynth.build(Sfx.SOUNDS[sound])
		failures += _check("sound %s builds (%d bytes)" % [sound, wav.data.size()],
			wav.data.size() > 400 and wav.loop_mode == AudioStreamWAV.LOOP_DISABLED)
	for sound: String in Sfx.LOOPS:
		var wav := SfxSynth.build(Sfx.LOOPS[sound], true)
		failures += _check("loop %s loops" % sound, wav.loop_mode == AudioStreamWAV.LOOP_FORWARD
			and wav.loop_end == wav.data.size() / 2)
	var layered := SfxSynth.build([{"w": "sine", "d": 0.2}, {"at": 0.0, "w": "noise", "d": 0.1}])
	failures += _check("'at' layers instead of chaining", absi(layered.data.size() / 2 - roundi(0.2 * SfxSynth.RATE)) <= 1)
	Sfx.play("catch")
	Sfx.hold("sizzle", true)
	Sfx.hold("sizzle", false)
	Sfx.ambience("sea")
	Sfx.ambience("")
	failures += _check("play / hold / ambience run", Sfx.has_sound("click") and not Sfx.has_sound("nope"))
	print("sfx_test: %s" % ("ALL PASS" if failures == 0 else "%d FAIL" % failures))
	get_tree().quit()


func _check(label: String, ok: bool) -> int:
	print(("PASS " if ok else "FAIL ") + label)
	return 0 if ok else 1
