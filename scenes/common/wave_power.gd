class_name WavePower
extends CanvasLayer
## Rin's "Nhịp Sóng" (WaveMark): `wave_power` (C) slows the world for a few
## seconds — at sea only during the fishing minigame, in the restaurant the
## whole street (customers' patience, Bảo, traffic, the grill / beer games)
## while Rin keeps his speed (`rin_unslowed`, RinChef divides it back out).
## Charges per scene (night / shift) from WaveMark.max_charges(). Shows the
## mark + charges bottom-left, and while active a teal tint, rippling rings
## and a heartbeat (sounds play lower). Hidden until Rin has the power.

signal activated
signal ended

## Game speed while active.
@export var slow_scale: float = 0.35
## Real seconds it lasts.
@export var seconds: float = 3.0
@export var tint: Color = Color(0.2, 0.85, 0.95, 0.2)

## True while slowed and Rin should move at full speed (restaurant).
static var rin_unslowed: bool = false
static var active: bool = false

## () -> bool: allowed right now (sea: the minigame is running).
var can_use: Callable
## () -> Vector2: screen point the ripples start from (Rin).
var ripple_origin: Callable
## Whether Rin keeps full speed (restaurant).
var keep_rin_speed: bool = false
var charges: int = 0

var _left: float = 0.0
var _time: float = 0.0
var _canvas: Control


func _ready() -> void:
	layer = 15
	add_to_group("wave_power")  # CutsceneDebug (F4) refills it
	charges = WaveMark.max_charges()
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_canvas)
	_canvas.visible = WaveMark.has_power()  # a cutscene may pause us right away
	add_child(_canvas)


func _exit_tree() -> void:
	if active:
		_stop()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("wave_power"):
		get_viewport().set_input_as_handled()
		use()


## Starts the slow-down if possible. Returns true if it started.
func use() -> bool:
	if active or charges <= 0 or not WaveMark.has_power() or (can_use.is_valid() and not can_use.call()):
		if WaveMark.has_power() and not active:
			Sfx.play("miss", 0.0)
		return false
	charges -= 1
	active = true
	rin_unslowed = keep_rin_speed
	_left = seconds
	Engine.time_scale = slow_scale
	AudioServer.playback_speed_scale = 0.7
	Sfx.play("whoosh", 0.0)
	Sfx.hold("heartbeat", true)
	activated.emit()
	return true


func _process(delta: float) -> void:
	_time += delta
	_canvas.visible = WaveMark.has_power()
	if active:
		_left -= delta / maxf(Engine.time_scale, 0.001)  # real seconds
		if _left <= 0.0 or (can_use.is_valid() and not can_use.call()):
			_stop()
	_canvas.queue_redraw()


func _stop() -> void:
	active = false
	rin_unslowed = false
	Engine.time_scale = 1.0
	AudioServer.playback_speed_scale = 1.0
	Sfx.hold("heartbeat", false)
	ended.emit()


func _draw_canvas() -> void:
	var view := _canvas.size
	if active:
		var strength := clampf(_left / 0.4, 0.0, 1.0) * clampf((seconds - _left) / 0.25, 0.0, 1.0)
		_canvas.draw_rect(Rect2(Vector2.ZERO, view), Color(tint, tint.a * strength))
		var origin: Vector2 = ripple_origin.call() if ripple_origin.is_valid() else view * 0.5
		for k in 3:
			var t := fmod(_time * 0.6 + k / 3.0, 1.0)
			_canvas.draw_arc(origin, 10.0 + t * view.x * 0.45, 0.0, TAU, 48,
				Color(0.5, 1.0, 1.0, 0.35 * (1.0 - t) * strength), 2.0)
		for edge in 4:  # soft vignette
			var w := 24.0 - edge * 6.0
			_canvas.draw_rect(Rect2(Vector2.ZERO, view).grow(-edge * 6.0), Color(0.0, 0.25, 0.3, 0.08 * strength), false, w)
	_draw_badge(Vector2(8, view.y - 46))


## The glowing mark + one pip per charge left, and the key.
func _draw_badge(at: Vector2) -> void:
	var glow := 0.6 + 0.4 * sin(_time * (8.0 if active else 2.0))
	_canvas.draw_circle(at + Vector2(8, 8), 8.0, Color(0.05, 0.1, 0.12, 0.8))
	_canvas.draw_arc(at + Vector2(8, 8), 5.0, 0.0, TAU * 0.8, 12, Color(0.4, 1.0, 0.9, glow), 2.0)
	_canvas.draw_circle(at + Vector2(8, 8), 1.6, Color(0.6, 1.0, 0.95, glow))
	var font := ThemeDB.fallback_font
	_canvas.draw_string(font, at + Vector2(19, 7), "C", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.8))
	for i in WaveMark.max_charges():
		var filled := i < charges
		_canvas.draw_circle(at + Vector2(21 + i * 6, 12), 2.0,
			Color(0.4, 1.0, 0.9, 0.95) if filled else Color(1, 1, 1, 0.2))
