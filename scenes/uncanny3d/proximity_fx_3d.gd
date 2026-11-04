class_name ProximityFx3D
extends CanvasLayer
## What Rin feels near a phenomenon (ProximityZone3D) or with a chaser close
## (Chase3D): the screen edges darken, PS1 grain rises, a heartbeat that
## quickens, the ambience ducks. One per scene host; anyone may push() a
## level 0..1 each frame, the strongest wins, it fades when nobody pushes.

const NODE_NAME := "ProximityFx"
const TUNING: ProximityTuning = preload("res://data/story/proximity_tuning.tres")
const SHADER := """
shader_type canvas_item;
uniform float amount = 0.0;
uniform float pixel = 3.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 c = UV - 0.5;
	c.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float r = length(c);
	float inner = mix(0.5, 0.1, amount);
	float vig = clamp((r - inner) / 0.38, 0.0, 1.0);
	float dark = vig * mix(0.0, 0.96, amount);
	float n = hash(floor(FRAGCOORD.xy / pixel) + floor(TIME * 24.0) * 7.13);
	float grain = amount * amount * 0.24 * n * (1.0 - dark);
	COLOR = vec4(vec3(n * 0.75) * (1.0 - vig), clamp(dark + grain, 0.0, 1.0));
}
"""

var tuning := TUNING
## Current level (0..1).
var level := 0.0
var _want := 0.0
var _rect := ColorRect.new()
var _material := ShaderMaterial.new()
var _duck_clock := 0.0
var _beating := false


static func of(host: Node) -> ProximityFx3D:
	var fx := host.get_node_or_null(NODE_NAME) as ProximityFx3D
	if fx == null:
		fx = ProximityFx3D.new()
		fx.name = NODE_NAME
		host.add_child(fx)
	return fx


## This frame's wish (the strongest push wins).
func push(amount: float) -> void:
	_want = maxf(_want, clampf(amount, 0.0, 1.0))


func _ready() -> void:
	layer = 22
	var shader := Shader.new()
	shader.code = SHADER
	_material.shader = shader
	_rect.material = _material
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.visible = false
	add_child(_rect)


func _process(delta: float) -> void:
	level = move_toward(level, _want, delta * (3.0 if _want > level else 1.2))
	_want = 0.0
	_material.set_shader_parameter("amount", level)
	_rect.visible = level > 0.002
	var beat := level > 0.05
	if beat != _beating:
		_beating = beat
		Sfx.hold("heartbeat", beat)
	if beat:
		Sfx.hold_pitch("heartbeat", lerpf(0.85, 1.6, level))
	_duck_clock -= delta
	if level > 0.15 and _duck_clock <= 0.0:
		_duck_clock = 0.4
		Sfx.duck(0.9, lerpf(0.7, tuning.duck_level, level))


func _exit_tree() -> void:
	if _beating:
		Sfx.hold("heartbeat", false)
