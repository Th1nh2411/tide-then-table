class_name CutsceneEffects
extends CanvasLayer
## Screen effects for CutscenePlayer: rain (`rain on|off`) and the Nhịp Sóng
## slow-down (`slow <factor> <seconds>`): raindrops and actors slow to
## `factor` (0.02 = frozen in the air), a teal tint, sounds pitched down and
## a heartbeat. Everything resets when the cutscene ends (`reset`).

@export var tint: Color = Color(0.2, 0.85, 0.95, 0.22)

var _rain: RainOverlay
var _tint: ColorRect
var _gloom: ColorRect
var _speed: float = 1.0


func _ready() -> void:
	layer = 22  # under the fade (23) and the dialogue box (24)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rain = RainOverlay.new()
	_rain.drop_count = 220
	_rain.fall_speed = 330.0
	_rain.drop_length = 11.0
	_rain.width = 1.5
	_rain.color = Color(0.82, 0.9, 1.0, 0.6)
	_rain.hide()
	_gloom = ColorRect.new()  # grey rainy light under the drops
	_gloom.color = Color(0.1, 0.13, 0.2, 0.3)
	_gloom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gloom.set_anchors_preset(Control.PRESET_FULL_RECT)
	_gloom.hide()
	add_child(_gloom)
	add_child(_rain)
	_tint = ColorRect.new()
	_tint.color = Color(tint, 0.0)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_tint)


func set_rain(on: bool) -> void:
	_rain.visible = on
	_gloom.visible = on


## Eases the scene's speed to `factor` over `seconds` (await it).
func slow(factor: float, seconds: float) -> void:
	var slowing := factor < 1.0
	Sfx.hold("heartbeat", slowing)
	var tween := create_tween().set_parallel()
	tween.tween_method(_set_speed, _speed, factor, maxf(seconds, 0.01))
	tween.tween_property(_tint, "color:a", tint.a if slowing else 0.0, maxf(seconds, 0.01))
	await tween.finished


func reset() -> void:
	_set_speed(1.0)
	_tint.color.a = 0.0
	_rain.hide()
	_gloom.hide()
	Sfx.hold("heartbeat", false)


func _set_speed(value: float) -> void:
	_speed = value
	_rain.speed_scale = value
	CutsceneActor.speed = value
	AudioServer.playback_speed_scale = lerpf(0.6, 1.0, clampf(value, 0.0, 1.0))
