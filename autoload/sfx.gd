extends Node
## Placeholder sound effects + ambience, built in code at startup (SfxSynth,
## no audio files). Autoloaded as `Sfx`:
##   Sfx.play("catch")            one-shot
##   Sfx.hold("sizzle", true)     looping sound on / off (grill, beer pour)
##   Sfx.ambience("sea")          background loop per scene ("" = silence)
## Every Button in the game clicks. Mute lives in user://settings.cfg (pause menu).

const SETTINGS_PATH := "user://settings.cfg"

## name -> segments (see SfxSynth). Short and quiet on purpose.
const SOUNDS := {
	"click": [{"w": "square", "f": [1200, 900], "d": 0.03, "v": 0.08}],
	"blip": [{"w": "square", "f": [660, 660], "d": 0.025, "v": 0.04}],
	"pop": [{"w": "sine", "f": [500, 1100], "d": 0.07, "v": 0.2}],
	"nibble": [{"w": "sine", "f": [520, 760], "d": 0.06, "v": 0.22}],
	"bite": [{"w": "noise", "lp": 0.35, "d": 0.2, "v": 0.22}, {"at": 0.0, "w": "sine", "f": [420, 140], "d": 0.18, "v": 0.3}],
	"catch": [{"w": "sine", "f": [523, 523], "d": 0.07, "v": 0.25}, {"w": "sine", "f": [659, 659], "d": 0.07, "v": 0.25},
		{"w": "sine", "f": [784, 784], "d": 0.07, "v": 0.25}, {"w": "sine", "f": [1047, 1047], "d": 0.22, "v": 0.25}],
	"ok": [{"w": "sine", "f": [659, 659], "d": 0.07, "v": 0.22}, {"w": "sine", "f": [880, 880], "d": 0.16, "v": 0.22}],
	"miss": [{"w": "tri", "f": [420, 180], "d": 0.3, "v": 0.3}],
	"splash": [{"w": "noise", "lp": 0.25, "d": 0.4, "v": 0.3, "a": 0.02}],
	"bump": [{"w": "noise", "lp": 0.08, "d": 0.18, "v": 0.3}, {"at": 0.0, "w": "sine", "f": [110, 50], "d": 0.2, "v": 0.4}],
	"coins": [{"w": "square", "f": [1319, 1319], "d": 0.05, "v": 0.1}, {"w": "square", "f": [1760, 1760], "d": 0.16, "v": 0.1}],
	"grumble": [{"w": "square", "f": [190, 120], "d": 0.32, "v": 0.1}],
	"clink": [{"w": "tri", "f": [2300, 2100], "d": 0.09, "v": 0.18}],
	"flip": [{"w": "noise", "lp": 0.6, "d": 0.08, "v": 0.2}, {"w": "noise", "lp": 0.85, "d": 0.25, "v": 0.08}],
	"bag": [{"w": "noise", "lp": 0.7, "d": 0.12, "v": 0.18}],
	"whoosh": [{"w": "noise", "lp": 0.12, "d": 1.6, "v": 0.6, "a": 0.7}],
	"pluck": [{"w": "tri", "f": [440, 440], "d": 0.2, "v": 0.22}],
	"neo": [{"w": "sine", "f": [1175, 1175], "d": 0.05, "v": 0.12}, {"w": "sine", "f": [1568, 1568], "d": 0.09, "v": 0.12}],
	# Shift receipt: printer tick per line, rubber stamp thump.
	"print": [{"w": "noise", "lp": 0.5, "d": 0.04, "v": 0.07}, {"w": "square", "f": [880, 880], "d": 0.015, "v": 0.03}],
	# Camera shutter: two bright clicks, then a short film wind (new catch, posts, records).
	"shutter": [{"w": "noise", "lp": 0.92, "d": 0.022, "v": 0.32}, {"at": 0.0, "w": "square", "f": [2600, 1900], "d": 0.012, "v": 0.07},
		{"at": 0.06, "w": "noise", "lp": 0.85, "d": 0.03, "v": 0.26}, {"at": 0.06, "w": "square", "f": [2200, 1600], "d": 0.012, "v": 0.06},
		{"at": 0.12, "w": "noise", "lp": 0.45, "d": 0.16, "v": 0.07, "a": 0.04}],
	# Rod fight: reel click, line snapping, wheel tick, fish slapping on the deck.
	"reel": [{"w": "noise", "lp": 0.9, "d": 0.012, "v": 0.09}, {"at": 0.0, "w": "square", "f": [1900, 1500], "d": 0.012, "v": 0.035}],
	"snap": [{"w": "noise", "lp": 0.95, "d": 0.04, "v": 0.38}, {"at": 0.02, "w": "tri", "f": [1100, 160], "d": 0.28, "v": 0.22}],
	"tick": [{"w": "square", "f": [2400, 2200], "d": 0.012, "v": 0.05}],
	"flop": [{"w": "noise", "lp": 0.35, "d": 0.05, "v": 0.26}, {"at": 0.1, "w": "noise", "lp": 0.35, "d": 0.04, "v": 0.16}],
	"stamp": [{"w": "noise", "lp": 0.1, "d": 0.1, "v": 0.35}, {"at": 0.0, "w": "sine", "f": [180, 70], "d": 0.13, "v": 0.45}],
}
const LOOPS := {
	"heartbeat": [{"w": "sine", "f": [70, 45], "d": 0.14, "v": 0.6}, {"at": 0.22, "w": "sine", "f": [60, 40], "d": 0.16, "v": 0.45},
		{"at": 0.9, "w": "sine", "f": [50, 50], "d": 0.01, "v": 0.0}],
	"rain": [{"w": "noise", "lp": 0.55, "d": 2.0, "v": 0.12, "a": 0.0, "swell": 1.0}],
	"sizzle": [{"w": "noise", "lp": 0.85, "d": 1.0, "v": 0.08}],
	# Line under high tension: a thin whine.
	"strain": [{"w": "tri", "f": [1180, 1220], "d": 0.5, "v": 0.035}],
	"pour": [{"w": "noise", "lp": 0.3, "d": 1.0, "v": 0.1}],
	"sea": [{"w": "noise", "lp": 0.015, "d": 6.0, "v": 0.35, "a": 0.0, "swell": 3.0}],
	"street": [{"w": "noise", "lp": 0.04, "d": 4.0, "v": 0.14, "a": 0.0, "swell": 2.0}],
}
const POOL_SIZE := 8

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
	_ambience.volume_db = -6.0
	add_child(_ambience)
	_bed = AudioStreamPlayer.new()
	_bed.volume_db = -4.0
	add_child(_bed)
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		set_muted(bool(config.get_value("audio", "muted", false)), false)
	get_tree().node_added.connect(_on_node_added)


func has_sound(sound: String) -> bool:
	return _streams.has(sound)


## One-shot; a little pitch jitter so repeats don't sound robotic.
func play(sound: String, jitter: float = 0.05) -> void:
	if not _streams.has(sound):
		push_warning("Unknown sound: " + sound)
		return
	if silent:
		return
	var player := _pool[_next]
	_next = (_next + 1) % _pool.size()
	player.stream = _streams[sound]
	player.pitch_scale = 1.0 + randf_range(-jitter, jitter)
	player.play()


## One-shot at an exact pitch, `semitones` above / below the recipe (the
## fishing rhythm game plays a little tune this way).
func play_note(sound: String, semitones: float) -> void:
	if silent or not _streams.has(sound):
		return
	var player := _pool[_next]
	_next = (_next + 1) % _pool.size()
	player.stream = _streams[sound]
	player.pitch_scale = pow(2.0, semitones / 12.0)
	player.play()


## Looping sound on / off (e.g. sizzle while grilling).
func hold(sound: String, on: bool) -> void:
	if silent:
		return
	if not _holds.has(sound):
		if not on:
			return
		var player := AudioStreamPlayer.new()
		player.stream = _streams[sound]
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
	_ambience.stream = _streams[sound]
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
## broken radio, glitches, drone): "room", "street", "sea", or "" to stop.
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


func stop_all() -> void:
	_ambience_name = ""
	_bed_name = ""
	for player in find_children("*", "AudioStreamPlayer", false, false):
		(player as AudioStreamPlayer).stop()


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button:
		button.pressed.connect(play.bind("click", 0.02))
