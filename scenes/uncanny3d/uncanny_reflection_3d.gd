class_name UncannyReflection3D
extends Node3D
## A figure that is only in the water (fake reflection): when Rin stands on
## the pier and looks down, the water in front of him shows someone standing
## right behind him, upside down. Nobody is behind him. Once he turns round,
## or looks away up, it is gone for good. A drowned body (GhostCast3D)
## mirrored under the water line, drawn faintly over the water.

## Camera pitch (degrees below the horizon) that counts as "looking down".
@export var look_down_deg := 22.0
@export var behind := 0.8
@export var height := 1.7
@export var alpha := 0.6

var water_y := 0.0
var _figure: Node3D
var _shown := false
var _done := false


static func spawn(parent: Node3D, water_y_: float) -> UncannyReflection3D:
	var reflection := UncannyReflection3D.new()
	reflection.name = "UncannyReflection"
	reflection.water_y = water_y_
	parent.add_child(reflection)
	return reflection


func _ready() -> void:
	top_level = true
	var rig := GhostCast3D.figure(self, "", true)
	for m in GhostCast3D.materials(rig):
		GhostLook3D.set_opacity(m, alpha)
	GhostCast3D.draw_over(rig)
	_figure = rig
	_figure.scale = Vector3(1, -1, 1) * height / 1.7  # mirrored: head down in the water
	_figure.visible = false


func _process(_delta: float) -> void:
	if _done:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var forward := -camera.global_basis.z
	var pitch := rad_to_deg(asin(clampf(forward.y, -1.0, 1.0)))
	var down := pitch < -look_down_deg
	if not _shown:
		if down:
			# Behind Rin, mirrored in the water: in front of him at the same distance.
			var flat := Vector3(forward.x, 0, forward.z).normalized()
			var spot := camera.global_position - flat * behind
			global_position = Vector3(spot.x, water_y, spot.z) + flat * (behind * 2.0 + 0.6)
			UncannyMoves3D.face_dir(self, flat)
			_figure.visible = true
			_shown = true
		return
	if not down:
		_done = true
		_figure.visible = false
		queue_free()
