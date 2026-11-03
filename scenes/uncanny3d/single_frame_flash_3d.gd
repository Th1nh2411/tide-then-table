class_name SingleFrameFlash3D
extends Node3D
## One rendered frame swapped: for a single frame the view shows what is
## right behind Rin (someone standing there, face too close), then it is
## back as if nothing happened. Skipped entirely when the player turned
## "Hiệu ứng nhấp nháy" off (GameSettings.flash_effects, photosensitivity).
## Built a frame ahead so the swapped frame is fully posed; runs after the
## first-person view (process_priority) so its camera wins that one frame.

## Frames the swapped view stays (1 = a single frame).
@export var frames := 1
@export var distance := 0.75

var kind := "drowned"
## The frames actually swapped (tests).
var shown := 0
var _camera := Camera3D.new()
var _previous: Camera3D
var _figure: PersonRig3D
var _tick := 0


## Null when flashes are off in the settings or there is no camera.
static func play(host: Node3D, kind_: String = "drowned") -> SingleFrameFlash3D:
	if not GameSettings.flash_effects():
		return null
	var camera := host.get_viewport().get_camera_3d()
	if camera == null:
		return null
	var flash := SingleFrameFlash3D.new()
	flash.name = "SingleFrameFlash"
	flash.kind = kind_
	flash._previous = camera
	host.add_child(flash)
	return flash


func _ready() -> void:
	top_level = true
	process_priority = 1000
	var eye := _previous.global_transform
	var back := eye.basis.z
	back.y = 0.0
	back = back.normalized()
	# The camera turned round; the figure stands just behind Rin, facing him.
	add_child(_camera)
	_camera.fov = _previous.fov
	_camera.near = 0.05
	_camera.global_transform = Transform3D(eye.basis.rotated(Vector3.UP, PI), eye.origin)
	_figure = PersonRig3D.build(self, kind)
	UncannyMoves3D.ghost_body(_figure)
	var ground := eye.origin.y - 1.62
	_figure.global_position = Vector3(eye.origin.x, ground, eye.origin.z) + back * distance
	UncannyMoves3D.face_dir(_figure, -back)
	var actor := UncannyActor3D.attach(_figure)
	actor.stare_at(_previous, 150.0, 0.0)
	actor.freeze()


func _process(_delta: float) -> void:
	_tick += 1
	if _tick == 2:
		_camera.make_current()
	elif _tick > 2:
		shown += 1
		if shown >= frames:
			if is_instance_valid(_previous):
				_previous.make_current()
			queue_free()
