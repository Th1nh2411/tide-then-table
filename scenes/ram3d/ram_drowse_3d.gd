class_name RamDrowse3D
extends Node
## Bad ending at sea (drank anh Út's tea, PLAN §10 H7): the screen blurs and
## darkens, eyelids droop, the boat answers less and drifts; the dead knock on
## the hull and whisper, too late. Then a green lamp comes alongside: anh Út,
## speaking softly, and the eyes close. -> RamEpilogue3D (drowned).

const BLUR := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float amount = 0.0;
void fragment() {
	vec2 sway = vec2(sin(TIME * 0.7), cos(TIME * 0.53)) * 0.006 * amount;
	vec3 c = textureLod(screen_tex, SCREEN_UV + sway, amount * 3.5).rgb;
	float edge = smoothstep(0.25, 0.75, length(SCREEN_UV - 0.5));
	COLOR = vec4(c * (1.0 - amount * 0.45) * (1.0 - edge * amount), 1.0);
}
"""

## Seconds at sea before it starts, and until he is gone.
@export var onset_seconds := 5.0
@export var drowse_seconds := 34.0
@export var knocks_at: Array[float] = [0.3, 0.55, 0.8]

var ram: RamSea3D
var amount := 0.0
var taken := false
var _time := 0.0
var _knocks := 0
var _blur: ShaderMaterial
var _lids: Array[ColorRect] = []
var _lid_close := 0.0


func _ready() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 45
	add_child(canvas)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blur = ShaderMaterial.new()
	_blur.shader = Shader.new()
	_blur.shader.code = BLUR
	rect.material = _blur
	canvas.add_child(rect)
	for top: bool in [true, false]:
		var lid := ColorRect.new()
		lid.color = Color.BLACK
		lid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lid.anchor_right = 1.0
		lid.anchor_top = 0.0 if top else 1.0
		lid.anchor_bottom = 0.0 if top else 1.0
		canvas.add_child(lid)
		_lids.append(lid)


func _process(delta: float) -> void:
	var sea := ram.sea
	if taken or sea.ending or sea.fishing:
		return
	_time += delta * RamNight.speed
	amount = clampf((_time - onset_seconds) / drowse_seconds, 0.0, 1.0)
	_blur.set_shader_parameter("amount", amount)
	# Eyes droop and jerk open, longer each time.
	var droop := amount * (0.55 + 0.45 * maxf(sin(_time * (0.6 + amount)), 0.0))
	_set_lids(maxf(droop * 0.5, _lid_close))
	if _knocks < knocks_at.size() and amount >= knocks_at[_knocks]:
		_knock(_knocks)
		_knocks += 1
	if amount >= 1.0:
		take()


func _physics_process(delta: float) -> void:
	var sea := ram.sea
	if taken or sea.ending or amount <= 0.0:
		return
	# Heavy arms: the boat answers less, and turns on its own.
	sea.boat.velocity *= exp(-2.2 * amount * delta)
	sea.yaw_velocity += sin(_time * 0.4) * 0.25 * amount * delta


## 0 = eyes open, 0.5 = closed (each lid covers half the screen).
func _set_lids(cover: float) -> void:
	var size := get_viewport().get_visible_rect().size.y * cover
	_lids[0].offset_bottom = size
	_lids[1].offset_top = -size


func _knock(index: int) -> void:
	Sfx.play("knock3", 0.0)
	var lines := RamFx3D.LINES.whispers_drank
	if index < lines.size():
		ram.text.say(lines[index], 2.4)


func take() -> void:
	if taken:
		return
	taken = true
	_play_taken()


func _play_taken() -> void:
	var sea := ram.sea
	sea.ending = true
	sea.boat.velocity = Vector3.ZERO
	sea.yaw_velocity = 0.0
	var forward := Vector3.FORWARD.rotated(Vector3.UP, sea.boat.rotation.y)
	var side := forward.cross(Vector3.UP)
	var ghe := _ghe(sea.boat.position + forward * 10.0 + side * 3.0)
	# A bump jerks his eyes half open: a green lamp coming alongside.
	_set_lids(0.14)
	_blur.set_shader_parameter("amount", 0.5)
	Sfx.play("bump")
	Sfx.play("splash")
	var come := create_tween()
	come.tween_property(ghe, "position", sea.boat.position + forward * 2.6 + side * 1.4, RamNight.secs(3.0)).set_ease(Tween.EASE_OUT)
	await come.finished
	await RamFx3D.say_lines(ram.text, RamFx3D.LINES.ut_at_sea, 2.6)
	Sfx.play("knock3", 0.0)
	var close := create_tween()
	close.set_parallel()
	close.tween_method(_set_lids, 0.14, 0.5, RamNight.secs(1.6))
	close.tween_property(_blur, "shader_parameter/amount", 1.0, RamNight.secs(1.6))
	await close.finished
	Sfx.play("splash")
	Sfx.play("drag")
	await RamFx3D.wait(self, 1.6)
	RamNight.finish(RamNight.Ending.DROWNED)
	SceneRouter.go_to(RamEpilogue3D.SCENE)


## Anh Út's boat: a dark hull, a green lamp, him standing in it.
func _ghe(at: Vector3) -> Node3D:
	var ghe := Node3D.new()
	ram.add_child(ghe)
	ghe.position = Vector3(at.x, SeaWater3D.WATER_Y, at.z)
	OmenProps3D.box(ghe, Vector3(0, 0.15, 0), Vector3(1.3, 0.4, 3.4), "1d1a16")
	OmenProps3D.glow_box(ghe, Vector3(0.4, 1.3, 1.2), Vector3(0.16, 0.22, 0.16), "39ff8a", 4.0)
	OmenProps3D.light(ghe, Vector3(0.4, 1.4, 1.2), "39ff8a", 2.2, 9.0)
	var ut := PersonRig3D.build(ghe, "guest_rich")
	ut.position = Vector3(0, 0.3, 0.2)
	var to_boat := ram.sea.boat.position - at
	ghe.rotation.y = atan2(to_boat.x, to_boat.z)
	return ghe
