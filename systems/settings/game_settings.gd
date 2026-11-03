class_name GameSettings
extends RefCounted
## Player settings in user://settings.cfg (the same file Sfx keeps "muted" in).
## Static store, no autoload: values load on first use; setters save and apply.
## Read by FirstPersonView3D (mouse), SceneRouter (PSX, fullscreen) and Sfx
## (mute). The UI is SettingsPanel (main menu + pause menu).

const PATH := "user://settings.cfg"
## Mouse look radians per pixel at sensitivity 1.0.
const BASE_MOUSE_SPEED := 0.0025
const SENSITIVITY_MIN := 0.25
const SENSITIVITY_MAX := 3.0

## Section, key, default.
const DEFAULTS: Array[Array] = [
	["controls", "mouse_sensitivity", 1.0],
	["controls", "invert_y", false],
	["audio", "volume", 0.8],
	["audio", "muted", false],
	["video", "psx", true],
	["video", "fullscreen", false],
	["video", "flash", true],
]

## Tests point this at a scratch file.
static var path: String = PATH
static var _config: ConfigFile


static func _cfg() -> ConfigFile:
	if _config == null:
		_config = ConfigFile.new()
		_config.load(path)  # a missing file just means defaults
	return _config


## Drop the cached values (after `path` changed, or in tests).
static func clear_cache() -> void:
	_config = null


static func _default(section: String, key: String) -> Variant:
	for entry: Array in DEFAULTS:
		if entry[0] == section and entry[1] == key:
			return entry[2]
	return null


static func get_value(section: String, key: String) -> Variant:
	return _cfg().get_value(section, key, _default(section, key))


## Saves at once: other keys in the file (and other writers) are kept.
static func set_value(section: String, key: String, value: Variant) -> void:
	_cfg().set_value(section, key, value)
	var on_disk := ConfigFile.new()
	on_disk.load(path)
	on_disk.set_value(section, key, value)
	on_disk.save(path)


static func mouse_sensitivity() -> float:
	var value: Variant = get_value("controls", "mouse_sensitivity")
	var number: float = float(value) if (value is float or value is int) else 1.0
	return clampf(number, SENSITIVITY_MIN, SENSITIVITY_MAX)


static func invert_y() -> bool:
	return bool(get_value("controls", "invert_y"))


## Radians per pixel for mouse look (x, y); y is negative when inverted.
static func mouse_speed() -> Vector2:
	var speed := BASE_MOUSE_SPEED * mouse_sensitivity()
	return Vector2(speed, -speed if invert_y() else speed)


static func volume() -> float:
	var value: Variant = get_value("audio", "volume")
	return clampf(float(value) if (value is float or value is int) else 0.8, 0.0, 1.0)


static func muted() -> bool:
	return bool(get_value("audio", "muted"))


static func psx() -> bool:
	return bool(get_value("video", "psx"))


static func fullscreen() -> bool:
	return bool(get_value("video", "fullscreen"))


## One-frame flashes / strobing scares (SingleFrameFlash3D); off for
## photosensitive players ("Hiệu ứng nhấp nháy").
static func flash_effects() -> bool:
	return bool(get_value("video", "flash"))


static func set_flash_effects(on: bool) -> void:
	set_value("video", "flash", on)



static func set_volume(value: float) -> void:
	set_value("audio", "volume", clampf(value, 0.0, 1.0))
	apply_volume()


## Master bus volume; 0 = silent.
static func apply_volume() -> void:
	var v := volume()
	AudioServer.set_bus_volume_db(0, linear_to_db(v) if v > 0.001 else -80.0)


static func set_fullscreen(on: bool) -> void:
	set_value("video", "fullscreen", on)
	apply_fullscreen()


static func apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.window_get_mode()
	var is_full := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if fullscreen() != is_full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen() else DisplayServer.WINDOW_MODE_WINDOWED)


static func set_muted(on: bool) -> void:
	set_value("audio", "muted", on)
	Sfx.set_muted(on, false)


## PS1 look on / off for every 3D scene (SceneRouter owns the PsxLook3D node).
static func set_psx(on: bool) -> void:
	set_value("video", "psx", on)
	SceneRouter.set_psx_look(on)


## Startup (SceneRouter._ready): volume, window, PS1 look.
static func apply_all() -> void:
	apply_volume()
	apply_fullscreen()
	SceneRouter.set_psx_look(psx())
