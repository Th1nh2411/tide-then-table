class_name DarkNightFigure3D
extends Node3D
## Something at the edge of the lamp on đêm âm (DarkNight3D). STAND: a dark
## person standing on the water, pale eyes. SWIM: only a head and eyes
## gliding sideways, half under. Either one is gone the moment Rin looks
## straight at it (or when its time is up, sinking quietly).

signal vanished(seen: bool)

enum Kind { STAND, SWIM }

@export var look_angle_deg := 13.0
@export var fade_seconds := 0.18
@export var lifetime := 9.0
@export var swim_speed := 1.4
@export var body_color := Color("0b0d0c")
@export var eye_color := Color("dfe9e2")

var kind := Kind.STAND
var swim_dir := Vector3.RIGHT
var _age := 0.0
var _leaving := false
var _materials: Array[StandardMaterial3D] = []


func _ready() -> void:
	var head_y := 1.62 if kind == Kind.STAND else 0.08
	if kind == Kind.STAND:
		var body := CapsuleMesh.new()
		body.radius = 0.2
		body.height = 1.5
		_part(body, Vector3(0, 0.75, 0), body_color, false)
	var head := SphereMesh.new()
	head.radius = 0.15
	head.height = 0.32
	_part(head, Vector3(0, head_y, 0), body_color, false)
	var eye := SphereMesh.new()
	eye.radius = 0.025
	eye.height = 0.05
	for side: float in [-0.055, 0.055]:
		_part(eye, Vector3(side, head_y + 0.02, 0.13), eye_color, true)


func _process(delta: float) -> void:
	if _leaving:
		return
	_age += delta
	if kind == Kind.SWIM:
		position += swim_dir * swim_speed * delta
	var camera := get_viewport().get_camera_3d()
	if camera:
		var to_me := global_position + Vector3.UP * 1.0 - camera.global_position
		var facing := Vector3(to_me.x, 0.0, to_me.z)
		if facing.length() > 0.1:
			rotation.y = atan2(-facing.x, -facing.z)
		if (-camera.global_basis.z).angle_to(to_me) < deg_to_rad(look_angle_deg):
			vanish(true)
			return
	if _age > lifetime:
		vanish(false)


## Seen: gone in a blink. Not seen: slips under the water.
func vanish(seen: bool) -> void:
	if _leaving:
		return
	_leaving = true
	var tween := create_tween().set_parallel()
	for material in _materials:
		tween.tween_property(material, "albedo_color:a", 0.0, fade_seconds if seen else 1.2)
	if not seen:
		tween.tween_property(self, "position:y", position.y - 1.6, 1.2)
	await tween.finished
	vanished.emit(seen)
	queue_free()


func _part(mesh: PrimitiveMesh, at: Vector3, color: Color, glows: bool) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.disable_fog = glows
	_materials.append(material)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	node.position = at
