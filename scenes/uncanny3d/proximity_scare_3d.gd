class_name ProximityScare3D
extends RefCounted
## The face when Rin got too close: the sound drops, a drowned face fills
## the view for ~0.35 s (WrongNightScare3D's faces), then it is gone. Caught
## by a chaser: the same, then black and the loop resets to mùng 9 through
## LoopCalendar (the next morning is a NightmareWake3D like any wrong night).

const TUNING: ProximityTuning = preload("res://data/story/proximity_tuning.tres")


## Ducks, then the face for scare_face_seconds. Awaitable.
static func jump(host: Node3D, t: ProximityTuning = TUNING) -> void:
	Sfx.duck(t.scare_duck_seconds + t.scare_face_seconds + 0.6, 0.0)
	await host.get_tree().create_timer(t.scare_duck_seconds).timeout
	if not is_instance_valid(host) or not host.is_inside_tree():
		return
	var face := WrongNightScare3D.show_face(host, _variant())
	if face == null:
		return
	await host.get_tree().create_timer(t.scare_face_seconds).timeout
	if is_instance_valid(face):
		face.queue_free()


## Caught: face, black, back to mùng 9. `reload` false: tests stop at the flag.
static func caught(host: Node3D, reload: bool = true, t: ProximityTuning = TUNING) -> void:
	LoopCalendar.caught()
	if host.get("leaving") != null:
		host.set("leaving", true)  # Rin stops; no more E
	Sfx.duck(t.scare_duck_seconds + t.scare_face_seconds + 1.5, 0.0)
	await host.get_tree().create_timer(t.scare_duck_seconds).timeout
	if not is_instance_valid(host) or not host.is_inside_tree():
		return
	var face := WrongNightScare3D.show_face(host, _variant())
	await host.get_tree().create_timer(t.scare_face_seconds).timeout
	if is_instance_valid(face):
		face.queue_free()
	if not is_instance_valid(host) or not host.is_inside_tree():
		return
	var black := CanvasLayer.new()
	black.layer = 90
	var rect := ColorRect.new()
	rect.color = Color.BLACK
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.add_child(rect)
	host.add_child(black)
	if reload:
		SceneRouter.go_to(VillageLayout3D.SCENE)


## A different face from tonight's wrong-night one.
static func _variant() -> int:
	return UncannyDirector.wrong_night_variant(LoopCalendar.loops() + GameState.day)
