class_name WrongNightScare3D
extends Node3D
## Jump scare (a): the sea takes Rin on an omen night. Right before the
## black, a drowned face fills the view for ~0.3 s with a dull thud (no
## scream), then black. Three variants by reset count so it never gets
## familiar (UncannyDirector.wrong_night_variant):
## 0 face-on, still, eyes on him; 1 hanging upside down from above;
## 2 face-on with the face torn into pixel noise.
## Also used by the morning wake when Rin docked on an omen night (the face
## leans over the bed), unless it already played at sea that night.

@export var show_seconds := 0.3
@export var distance := 0.34

## Played at sea tonight: the wake does not repeat it.
static var played_at_sea := false

var variant := 0
var _figure: PersonRig3D


## At sea (DarkNightTaken3D), right before the black: ducks, waits, shows
## the face, removes it. False when it may not play (a scare yesterday).
static func at_sea(host: Node3D) -> bool:
	if not UncannyDirector.scare_allowed():
		return false
	played_at_sea = true
	UncannyDirector.mark_scare()
	await play(host, UncannyDirector.wrong_night_variant(LoopCalendar.loops()))
	return true


## Ducks, waits `duck_before`, shows the face for show_seconds. Awaitable.
static func play(host: Node3D, variant_: int) -> void:
	Sfx.duck(1.6, 0.0)
	await host.get_tree().create_timer(1.0).timeout
	if not is_instance_valid(host) or not host.is_inside_tree():
		return
	var scare := show_face(host, variant_)
	if scare == null:
		return
	await host.get_tree().create_timer(scare.show_seconds).timeout
	if is_instance_valid(scare):
		scare.queue_free()


## The face in front of the current camera now (the caller frees it).
static func show_face(host: Node3D, variant_: int) -> WrongNightScare3D:
	var camera := host.get_viewport().get_camera_3d()
	if camera == null:
		return null
	var scare := WrongNightScare3D.new()
	scare.variant = variant_
	host.add_child(scare)
	scare.place(camera)
	Sfx.play("dead_thud", 0.0)
	return scare


## The morning after docking on an omen night (no taken scene): the face
## over the bed, unless the sea already showed it.
static func due_at_wake(result: LoopCalendar.Result) -> int:
	var due := result == LoopCalendar.Result.RESET and LoopCalendar.last_choice == "out" \
		and not LoopCalendar.last_calm_miss and not played_at_sea
	played_at_sea = false
	return UncannyDirector.wrong_night_variant(LoopCalendar.loops()) if due else -1


func _ready() -> void:
	top_level = true
	_figure = PersonRig3D.build(self, "drowned_f" if variant == 1 else "drowned_m")
	UncannyMoves3D.ghost_body(_figure)
	UncannyMoves3D.remove_shadow(_figure)
	var actor := UncannyActor3D.attach(_figure)
	actor.freeze()
	if variant == 2:
		actor.glitch_face(true)


## Puts the face right in front of the camera.
func place(camera: Camera3D) -> void:
	var eye := camera.global_transform
	var forward := -eye.basis.z.normalized()
	var actor := _figure.get_node(UncannyActor3D.NODE_NAME) as UncannyActor3D
	# Face height above the rig origin, then line it up with the eye.
	var face := actor.head_position() - _figure.global_position
	if variant == 1:
		_figure.rotation = Vector3(0, 0, PI)  # upside down, hanging into view
		face = Vector3(0, -face.y, 0)
	var at := eye.origin + forward * distance - face
	if variant == 1:
		at += eye.basis.y * 0.05
	_figure.global_position = at
	var flat := Vector3(-forward.x, 0, -forward.z)
	if variant != 1:
		UncannyMoves3D.face_dir(_figure, flat)
	else:
		_figure.rotation.y = atan2(flat.x, flat.z)
