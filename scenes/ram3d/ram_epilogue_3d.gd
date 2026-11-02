class_name RamEpilogue3D
extends Node3D
## The last images of đêm rằm (PLAN §10 H7) on the waterfront, a fixed camera,
## words on screen only, then the ending card (RamNight.ending_id()):
## - "true": grey dawn. The village found the bodies under the raft; hoa đăng
##   are released; the dead stand along the pier and fade one by one, ông Tư
##   last (with enough notebook clues he speaks to Rin first).
## - "drowned": a year later, through Rin's ghost standing in the water by the
##   pier: a young fisherman walks up the lane, anh Út waiting at its sign.

const SCENE := "res://scenes/ram3d/ram_epilogue_3d.tscn"
const ENDING := "res://scenes/ending/ending_scene.tscn"
const PIER_X := 6.0
const GHOSTS := 7

var text: OnScreenText
var black: ColorRect
var camera: Camera3D


func _ready() -> void:
	var true_end := RamNight.ending_id() != "drowned"
	WaterfrontBuilder3D.build(self, not true_end)
	camera = Camera3D.new()
	add_child(camera)
	camera.far = 300.0
	camera.current = true
	text = OnScreenText.new()
	add_child(text)
	black = RamFx3D.veil(self, "000000", 1.0, 19)
	Sfx.ambience("sea")
	Sfx.bed("sea")
	if true_end:
		_play_true.call_deferred()
	else:
		_play_drowned.call_deferred()


func _play_true() -> void:
	camera.position = Vector3(10.0, 1.7, 4.8)
	camera.look_at(Vector3(PIER_X - 1.0, 0.6, -4.5))
	var shore := RamShore3D.new()
	shore.talk = false
	shore.release_seconds = 1.4
	add_child(shore)
	# The dead along the pier, ông Tư at its end by his thúng.
	var ghosts: Array[StandardMaterial3D] = []
	for i in GHOSTS:
		var z := 0.6 - float(i) * 1.55
		var side := -0.45 if i % 2 == 0 else 0.45
		var ghost := RamFx3D.ghost(self, Vector3(PIER_X + side, 0.12, z), "ong_tu" if i == GHOSTS - 1 else "drowned")
		RamFx3D.ghost_holder(ghost).rotation.y = atan2(camera.position.x - PIER_X, camera.position.z - z)
		ghost.albedo_color.a = 0.0
		ghosts.append(ghost)
	var lines := RamFx3D.LINES.dawn.duplicate()
	if not lines.is_empty():
		await RamFx3D.say_lines(text, [lines.pop_front()], 2.4)
	_fade(black, 0.0, 2.0)
	await RamFx3D.say_lines(text, lines, 3.4)
	Sfx.play("bell", 0.0)
	for ghost in ghosts:
		_fade_ghost(ghost, 0.45, 1.6)
	await RamFx3D.wait(self, 3.0)
	# They go one by one from the shore end; ông Tư stays last.
	for i in GHOSTS - 1:
		_fade_ghost(ghosts[i], 0.0, 1.4)
		await RamFx3D.wait(self, 0.8)
	await RamFx3D.wait(self, 1.6)
	if RamNight.grandpa_speaks(NightErrand3D.clue_count()):
		await RamFx3D.say_lines(text, [RamFx3D.LINES.grandpa], 3.6)
	Sfx.play("bell", 0.0)
	_fade_ghost(ghosts[GHOSTS - 1], 0.0, 3.0)
	await RamFx3D.wait(self, 3.4)
	await _to_card()


func _play_drowned() -> void:
	# Rin's ghost, waist-deep beside the pier, looking back at the village.
	camera.position = Vector3(0.0, 0.9, 1.2)
	camera.look_at(Vector3(-10.0, 1.0, 8.0))
	RamFx3D.veil(self, "1d4a44", 0.22, 18)
	# The other dead, waist-deep beside him.
	for at: Vector3 in [Vector3(-3.6, -0.5, 1.2), Vector3(-1.8, -0.5, -0.6)]:
		var ghost := RamFx3D.ghost(self, at)
		RamFx3D.ghost_holder(ghost).rotation.y = PI * 0.75
	var ut := PersonRig3D.build(self, "guest_rich")
	ut.position = WaterfrontBuilder3D.LANE + Vector3(1.4, 0, -0.8)
	ut.rotation.y = PI * 0.5
	var young := PersonRig3D.build(self, "guest_3")
	var from := Vector3(3.5, 0, 3.2)
	var to := WaterfrontBuilder3D.LANE + Vector3(2.6, 0, -0.4)
	young.position = from
	young.rotation.y = atan2(to.x - from.x, to.z - from.z)
	var lines := RamFx3D.LINES.drowned.duplicate()
	if not lines.is_empty():
		await RamFx3D.say_lines(text, [lines.pop_front()], 2.6)
	_fade(black, 0.0, 2.0)
	young.set_walking(1.0, 0.0)
	var walk := create_tween()
	walk.tween_property(young, "position", to, RamNight.secs(6.0))
	await walk.finished
	young.set_walking(0.0, 0.0)
	await RamFx3D.say_lines(text, lines, 3.2)
	# Anh Út looks past the boy, down to the water, at Rin.
	var look := camera.global_position - ut.position
	var turn := create_tween()
	turn.tween_property(ut, "rotation:y", atan2(look.x, look.z), RamNight.secs(1.4))
	Sfx.play("knock3", 0.0)
	await RamFx3D.wait(self, 2.2)
	await _to_card()


func _to_card() -> void:
	var tween := _fade(black, 1.0, 1.6)
	await tween.finished
	SceneRouter.go_to(ENDING)


func _fade(rect: ColorRect, alpha: float, seconds: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(rect, "color:a", alpha, RamNight.secs(seconds))
	return tween


func _fade_ghost(ghost: StandardMaterial3D, alpha: float, seconds: float) -> void:
	create_tween().tween_property(ghost, "albedo_color:a", alpha, RamNight.secs(seconds))
