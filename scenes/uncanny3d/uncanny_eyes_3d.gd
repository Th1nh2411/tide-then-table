class_name UncannyEyes3D
extends Node3D
## Two pale eyes far off in the dark (in the bushes, under a house). They
## are gone the moment the light near them comes up (`lamp` brighter than
## `bright_energy`), or when Rin looks straight at them for a while.
## Optional `lamp_up_near`: Rin within this distance makes the lamp flicker
## up by itself (an old bulb catching), which takes the eyes away.

signal vanished

@export var eye_color := Color(2.4, 2.6, 2.2)
@export var spacing := 0.11
@export var bright_energy := 0.9
@export var stare_seconds := 1.6
@export var stare_angle_deg := 5.0
@export var lamp_up_near := 9.0
@export var lamp_up_energy := 1.6

var lamp: Light3D
var _stared := 0.0
var _gone := false
var _lamp_rising := false


static func spawn(parent: Node3D, at: Vector3, face: Vector3, lamp_: Light3D = null) -> UncannyEyes3D:
	var eyes := UncannyEyes3D.new()
	eyes.name = "UncannyEyes"
	eyes.lamp = lamp_
	parent.add_child(eyes)
	eyes.global_position = at
	UncannyMoves3D.face_dir(eyes, face - at)
	return eyes


func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = eye_color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.disable_fog = true
	var dot := SphereMesh.new()
	dot.radius = 0.022
	dot.height = 0.03
	for side: float in [-spacing * 0.5, spacing * 0.5]:
		var eye := MeshInstance3D.new()
		eye.mesh = dot
		eye.material_override = material
		eye.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		eye.position = Vector3(side, 0, 0)
		add_child(eye)


func _process(delta: float) -> void:
	if _gone:
		return
	if is_instance_valid(lamp):
		if lamp.visible and lamp.light_energy >= bright_energy:
			vanish()
			return
		var camera := get_viewport().get_camera_3d()
		if camera and not _lamp_rising and camera.global_position.distance_to(global_position) < lamp_up_near:
			_lamp_rising = true
			_flicker_up()
	var camera := get_viewport().get_camera_3d()
	if camera and UnseenCheck.look_angle(camera, global_position) < stare_angle_deg:
		_stared += delta
		if _stared >= stare_seconds:
			vanish()
	else:
		_stared = 0.0


func vanish() -> void:
	if _gone:
		return
	_gone = true
	visible = false
	vanished.emit()
	queue_free()


## The bulb stutters, then catches.
func _flicker_up() -> void:
	var base := lamp.light_energy
	var tween := create_tween()
	for energy: float in [base * 2.0, base * 0.3, base * 3.0, base, lamp_up_energy]:
		tween.tween_property(lamp, "light_energy", energy, 0.06)
		tween.tween_interval(0.05)
