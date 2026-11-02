extends Node
## Standalone test for the village-map sounds (run with F6): every
## SfxEnvRecipes sound / loop builds, loops loop, nothing clips, footstep
## variations exist, the new HorrorBed mixes build, Sfx knows the names.

const NEW_MIXES: Array[String] = ["house", "lane", "waterfront"]
const OLD_MIXES: Array[String] = ["room", "street", "sea", "sea_dark"]


func _ready() -> void:
	var failures := 0
	for sound: String in SfxEnvRecipes.SOUNDS:
		var raw := SfxSynth.render(SfxEnvRecipes.SOUNDS[sound])
		var wav := SfxSynth.build(SfxEnvRecipes.SOUNDS[sound])
		failures += _check("sound %s builds (%.2f s, peak %.2f)" % [sound, _seconds(raw), _peak(raw)],
			wav.data.size() > 400 and wav.loop_mode == AudioStreamWAV.LOOP_DISABLED and _peak(raw) > 0.01)
		failures += _check("sound %s doesn't clip" % sound, _peak(raw) <= 1.0)
	for sound: String in SfxEnvRecipes.LOOPS:
		var raw := SfxSynth.render(SfxEnvRecipes.LOOPS[sound], true)
		var wav := SfxSynth.build(SfxEnvRecipes.LOOPS[sound], true)
		failures += _check("loop %s loops (%.1f s, peak %.2f)" % [sound, _seconds(raw), _peak(raw)],
			wav.loop_mode == AudioStreamWAV.LOOP_FORWARD and wav.loop_end == wav.data.size() / 2 and _peak(raw) > 0.01)
		failures += _check("loop %s doesn't clip" % sound, _peak(raw) <= 1.0)
	for surface: String in SfxEnvRecipes.STEPS:
		var names: Array = SfxEnvRecipes.STEPS[surface]
		var known := names.size() >= 3
		for step: String in names:
			known = known and SfxEnvRecipes.SOUNDS.has(step)
		failures += _check("steps on %s: %d variations" % [surface, names.size()], known)
	for mix: String in NEW_MIXES:
		var raw := HorrorBed.render(mix)
		var wav := HorrorBed.build(mix)
		failures += _check("bed %s builds (peak %.2f)" % [mix, _peak(raw)], HorrorBed.MIXES.has(mix)
			and wav.loop_mode == AudioStreamWAV.LOOP_FORWARD and wav.data.size() > 100000)
		failures += _check("bed %s doesn't clip" % mix, _peak(raw) <= 1.0)
	for mix: String in OLD_MIXES:
		failures += _check("old bed %s has no env layer" % mix, not (HorrorBed.MIXES[mix] as Dictionary).has("env"))
	var no_clash := true
	for sound: String in SfxEnvRecipes.SOUNDS.keys() + SfxEnvRecipes.LOOPS.keys():
		no_clash = no_clash and not Sfx.SOUNDS.has(sound) and not Sfx.LOOPS.has(sound)
	failures += _check("new names don't shadow old ones", no_clash)
	failures += _check("Sfx knows the new sounds", Sfx.has_sound("door_open") and Sfx.has_sound("rain_roof")
		and not Sfx.has_sound("nope"))
	Sfx.step("wood")
	Sfx.play("dog_far")
	Sfx.ambience("insects")
	Sfx.ambience("")
	Sfx.bed("lane")
	Sfx.bed("")
	failures += _check("step / play / ambience / bed run", true)
	print("sfx_library_test: %s" % ("ALL PASS" if failures == 0 else "%d FAIL" % failures))
	get_tree().quit()


func _peak(samples: PackedFloat32Array) -> float:
	var peak := 0.0
	for s in samples:
		peak = maxf(peak, absf(s))
	return peak


func _seconds(samples: PackedFloat32Array) -> float:
	return float(samples.size()) / SfxSynth.RATE


func _check(label: String, ok: bool) -> int:
	print(("PASS " if ok else "FAIL ") + label)
	return 0 if ok else 1
