class_name DarkNightTaken3D
extends RefCounted
## The end of đêm âm (SeaTrip3D.taken_by_the_sea): the lamp flickers out,
## three knocks, hands come up over the rim, the boat is pulled under and
## the screen goes black. `speed` > 1 shortens it (tests).

const HAND_COUNT := 7
const RIM_RADIUS := 1.5


static func play(sea: SeaScene3D, speed: float = 1.0) -> void:
	var s := 1.0 / maxf(speed, 0.01)
	sea.boat.velocity = Vector3.ZERO
	sea.yaw_velocity = 0.0
	sea._said.clear()
	sea.status_until = 0.0
	sea._say("Đèn... đừng tắt...", 2.0 * s)
	sea._update_hud()  # the trip loop is stopped; push the line by hand
	await _flicker_out(sea, 1.4 * s)
	await sea.get_tree().create_timer(0.5 * s).timeout
	Sfx.play("knock3", 0.0)
	await sea.get_tree().create_timer(1.1 * s).timeout
	var hands := _hands(sea)
	Sfx.play("splash")
	Sfx.play("bump")
	sea.status_until = 0.0
	sea._say("Buông ra!", 2.0 * s)
	sea._update_hud()
	var rise := sea.create_tween().set_parallel()
	for hand in hands:
		rise.tween_property(hand, "position:y", 0.75, 0.45 * s).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		rise.tween_property(hand, "rotation:x", 0.5, 0.45 * s)
	await rise.finished
	await sea.get_tree().create_timer(0.6 * s).timeout
	var veil := _veil(sea)
	Sfx.play("whoosh")
	var sink := sea.create_tween().set_parallel()
	sink.tween_property(sea.boat_visual, "position:y", -2.4, 1.8 * s).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sink.tween_property(sea.boat_visual, "rotation:z", 0.35, 1.8 * s)
	sink.tween_property(veil, "color:a", 1.0, 1.6 * s).set_delay(0.3 * s)
	await sink.finished
	await sea.get_tree().create_timer(0.7 * s).timeout


## A few blinks, then dark; the night itself goes darker too.
static func _flicker_out(sea: SeaScene3D, seconds: float) -> void:
	var lamp := sea.boat_lamp
	Sfx.play("static")
	for i in 6:
		if is_instance_valid(lamp):
			lamp.visible = i % 2 == 1
		await sea.get_tree().create_timer(seconds / 6.0 * (0.5 + 0.2 * i)).timeout
	if is_instance_valid(lamp):
		lamp.visible = false
	for env_node in sea.find_children("*", "WorldEnvironment", false, false):
		var env := (env_node as WorldEnvironment).environment
		sea.create_tween().tween_property(env, "ambient_light_energy", env.ambient_light_energy * 0.35, 0.6)


## Arms with three fingers, under the water around the rim, facing inward.
static func _hands(sea: SeaScene3D) -> Array[Node3D]:
	var hands: Array[Node3D] = []
	for i in HAND_COUNT:
		var angle := TAU * float(i) / HAND_COUNT + 0.3
		var hand := Node3D.new()
		hand.name = "Hand%d" % i
		sea.boat_visual.add_child(hand)
		hand.position = Vector3(cos(angle) * RIM_RADIUS, -1.6, sin(angle) * RIM_RADIUS)
		hand.rotation.y = atan2(-cos(angle), -sin(angle))  # +Z towards the boat
		ConceptModel3D.spawn(hand, "drowned_hand", Vector3(0, -1.0, 0), 1.15)
		hands.append(hand)
	return hands


static func _veil(sea: SeaScene3D) -> ColorRect:
	var layer := CanvasLayer.new()
	layer.layer = 50
	sea.add_child(layer)
	var rect := ColorRect.new()
	rect.color = Color(0.01, 0.03, 0.02, 0.0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	return rect
