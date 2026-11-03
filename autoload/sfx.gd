extends Node
## Placeholder sound effects + ambience, built in code at startup (SfxSynth,
## no audio files). Autoloaded as `Sfx`:
##   Sfx.play("catch")            one-shot
##   Sfx.hold("sizzle", true)     looping sound on / off (grill, beer pour)
##   Sfx.ambience("sea")          background loop per scene ("" = silence)
## Every Button in the game clicks. Mute lives in user://settings.cfg (pause menu).

## A one-shot was asked for (also when headless / muted): CaptionLayer
## captions story sounds from this.
signal sound_played(sound: String, at: Vector3, positional: bool)

const SETTINGS_PATH := "user://settings.cfg"

## name -> segments (see SfxSynth), kept in SfxRecipes.
const SOUNDS := SfxRecipes.SOUNDS
const LOOPS := SfxRecipes.LOOPS
const POOL_SIZE := 8
const AMBIENCE_DB := -6.0
const BED_DB := -4.0

var muted: bool = false
## Headless runs (tests, bots) build the sounds but never play them: the
## dummy audio driver never releases playbacks, which shows up as leaks.
var silent: bool = DisplayServer.get_name() == "headless"

var _streams: Dictionary = {}  # name -> AudioStreamWAV
var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0
var _holds: Dictionary = {}  # name -> AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _ambience_name: String = ""
var _bed: AudioStreamPlayer
var _bed_name: String = ""
var _beds: Dictionary = {}  # mix name -> AudioStreamWAV, built on first use
var _duck_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sound: String in SOUNDS:
		_streams[sound] = SfxSynth.build(SOUNDS[sound])
	for sound: String in LOOPS:
		_streams[sound] = SfxSynth.build(LOOPS[sound], true)
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)
	_ambience = AudioStreamPlayer.new()
	_ambience.volume_db = AMBIENCE_DB
	add_child(_ambience)
	_bed = AudioStreamPlayer.new()
	_bed.volume_db = BED_DB
	add_child(_bed)
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		set_muted(bool(config.get_value("audio", "muted", false)), false)
	get_tree().node_added.connect(_on_node_added)


func has_sound(sound: String) -> bool:
	return _streams.has(sound) or SfxEnvRecipes.SOUNDS.has(sound) or SfxEnvRecipes.LOOPS.has(sound)


## Footstep on "wood" / "sand" / "dirt" (SfxEnvRecipes.STEPS), a random variation.
func step(surface: String) -> void:
	var names: Array = SfxEnvRecipes.STEPS.get(surface, [])
	if not names.is_empty():
		play(String(names.pick_random()), 0.08)


## The stream of a sound; village-map sounds (SfxEnvRecipes) are built on
## first use so startup stays fast.
func _stream(sound: String) -> AudioStreamWAV:
	if not _streams.has(sound):
		if SfxEnvRecipes.SOUNDS.has(sound):
			_streams[sound] = SfxSynth.build(SfxEnvRecipes.SOUNDS[sound])
		else:
			_streams[sound] = SfxSynth.build(SfxEnvRecipes.LOOPS[sound], true)
	return _streams[sound]


## One-shot; a little pitch jitter so repeats don't sound robotic.
func play(sound: String, jitter: float = 0.05) -> void:
	if not has_sound(sound):
		push_warning("Unknown sound: " + sound)
		return
	sound_played.emit(sound, Vector3.ZERO, false)
	if silent:
		return
	var player := _pool[_next]
	_next = (_next + 1) % _pool.size()
	player.stream = _stream(sound)
	player.pitch_scale = 1.0 + randf_range(-jitter, jitter)
	player.play()


## One-shot at an exact pitch, `semitones` above / below the recipe (the
## fishing rhythm game plays a little tune this way).
func play_note(sound: String, semitones: float) -> void:
	if silent or not has_sound(sound):
		return
	var player := _pool[_next]
	_next = (_next + 1) % _pool.size()
	player.stream = _stream(sound)
	player.pitch_scale = pow(2.0, semitones / 12.0)
	player.play()


## One-shot placed in the 3D world at `at` (under `host`, freed when done),
## so the player hears where it comes from. Silent when headless.
func play_at(sound: String, at: Vector3, host: Node3D, pitch: float = 1.0, unit_size: float = 6.0) -> void:
	if has_sound(sound):
		sound_played.emit(sound, at, true)
	if silent or not has_sound(sound) or host == null or not host.is_inside_tree():
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = _stream(sound)
	player.pitch_scale = pitch
	player.unit_size = unit_size
	player.max_distance = 80.0
	host.add_child(player)
	player.global_position = at
	player.finished.connect(player.queue_free)
	player.play()


## Lowers the bed and ambience to `level` (0..1, 0 = off) for `seconds`, then
## restores them: the near silence right before a stinger.
func duck(seconds: float = 1.5, level: float = 0.08) -> void:
	if silent:
		return
	if _duck_tween:
		_duck_tween.kill()
	var down := linear_to_db(maxf(level, 0.0001))
	_duck_tween = create_tween().set_parallel()
	_duck_tween.tween_property(_ambience, "volume_db", AMBIENCE_DB + down, 0.25)
	_duck_tween.tween_property(_bed, "volume_db", BED_DB + down, 0.25)
	_duck_tween.chain().tween_interval(maxf(seconds - 0.25, 0.0))
	_duck_tween.chain().tween_property(_ambience, "volume_db", AMBIENCE_DB, 0.8)
	_duck_tween.parallel().tween_property(_bed, "volume_db", BED_DB, 0.8)


## Looping sound on / off (e.g. sizzle while grilling).
func hold(sound: String, on: bool) -> void:
	if silent:
		return
	if not _holds.has(sound):
		if not on:
			return
		var player := AudioStreamPlayer.new()
		player.stream = _stream(sound)
		add_child(player)
		_holds[sound] = player
	var looping: AudioStreamPlayer = _holds[sound]
	if on and not looping.playing:
		looping.play()
	elif not on:
		looping.stop()


## Background loop for the current scene ("" = none).
func ambience(sound: String) -> void:
	if sound == _ambience_name:
		return
	_ambience_name = sound
	if silent:
		return
	for looping: AudioStreamPlayer in _holds.values():
		looping.stop()
	if sound == "":
		_ambience.stop()
		return
	_ambience.stream = _stream(sound)
	_ambience.play()


func set_muted(on: bool, save: bool = true) -> void:
	muted = on
	AudioServer.set_bus_mute(0, on)
	if save:
		var config := ConfigFile.new()
		config.load(SETTINGS_PATH)
		config.set_value("audio", "muted", on)
		config.save(SETTINGS_PATH)


## Silence everything (before quitting: SceneRouter.quit_game).
## The horror bed under the ambience (HorrorBed: tape hiss, vinyl crackle,
## broken radio, glitches, drone): "room", "street", "sea", "sea_dark"
## (đêm âm), village map "house" / "lane" / "waterfront", or "" to stop.
func bed(mix_name: String) -> void:
	if mix_name == _bed_name:
		return
	_bed_name = mix_name
	if silent:
		return
	if mix_name == "":
		_bed.stop()
		return
	if not _beds.has(mix_name):
		_beds[mix_name] = HorrorBed.build(mix_name)
	_bed.stream = _beds[mix_name]
	_bed.play()


## Builds these bed mixes now (one hitch while a scene loads, none on the walk).
func prebuild_beds(mix_names: Array[String]) -> void:
	if silent:
		return
	for mix_name in mix_names:
		if not _beds.has(mix_name):
			_beds[mix_name] = HorrorBed.build(mix_name)


func stop_all() -> void:
	_ambience_name = ""
	_bed_name = ""
	for player in find_children("*", "AudioStreamPlayer", false, false):
		(player as AudioStreamPlayer).stop()


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button:
		button.pressed.connect(play.bind("click", 0.02))
