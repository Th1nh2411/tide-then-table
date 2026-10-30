extends Node
## Every marker the cutscenes use exists in the 3D marker sets, and a staged
## cutscene (spawn, move, camera, emote, rain, slow, remove, tint) runs in 3D.

var _failed: bool = false


func _ready() -> void:
	_run.call_deferred()


func _check(label: String, ok: bool) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		_failed = true


func _run() -> void:
	GameState.reset()
	var scenes := {
		"restaurant": ["res://scenes/restaurant3d/restaurant_scene_3d.tscn", ["arrival_cutscenes", "after_shift_cutscenes"]],
		"sea": ["res://scenes/sea3d/sea_scene_3d.tscn", ["trip_end_cutscenes"]],
	}
	for kind: String in scenes:
		var info: Array = scenes[kind]
		var root: Node = load(info[0]).instantiate()
		var cutscenes: Array = []
		for property: String in info[1]:
			var value: Variant = root.get(property)
			if value is Array:
				cutscenes.append_array(value)
		var missing := PackedStringArray()
		for cutscene: Cutscene in cutscenes:
			for marker_name in CutsceneMarkers3D.used_names(cutscene):
				if not CutsceneMarkers3D.PIXELS[kind].has(marker_name):
					missing.append("%s:%s" % [cutscene.id, marker_name])
		_check("3D cutscene markers exist for %s %s" % [kind, missing], missing.is_empty() and not cutscenes.is_empty())
		root.free()
	await _stage_run()
	get_tree().quit(1 if _failed else 0)


func _stage_run() -> void:
	var camera := Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 14.0
	camera.position = Vector3(4.5, 12, 15)
	camera.look_at(Vector3(0, 0, -0.5))
	camera.current = true
	var bridge := load("res://scenes/story3d/story_bridge_3d.tscn").instantiate() as StoryBridge3D
	add_child(bridge)
	bridge.stage_kind = "restaurant"
	var cutscene := Cutscene.new()
	cutscene.id = "stage3d_test"
	cutscene.script_text = "rain on\ncamera room_view 0 1.5\nspawn Rin rin door\nmove_to Rin rin_spot 0.2\nemote Rin !\nslow 0.5 0.1\nrain off\nremove Rin"
	var before := camera.global_position
	var holder := Node3D.new()
	add_child(holder)
	var real := PersonRig3D.build(holder, "rin")
	real.position = Vector3(1.5, 0, 2.0)
	real.rotation.y = 0.7
	bridge.play(cutscene)
	await get_tree().create_timer(0.1, true).timeout
	var stage := bridge._stage as CutsceneStage3D
	_check("stage spawned actor", stage != null and stage.actor("Rin") != null)
	var actor_rig := stage.actor("Rin") as PersonRig3D
	_check("actor uses PersonRig3D", actor_rig != null)
	_check("gameplay rin hidden during", not real.visible)
	_check("no duplicate rin visible", get_tree().get_nodes_in_group("person_rin").size() == 1 and not (actor_rig != null and actor_rig.is_in_group("person_rin")))
	_check("cutscene camera current", get_viewport().get_camera_3d() != camera)
	for i in 120:
		if not bridge.playing:
			break
		await get_tree().create_timer(0.05, true).timeout
	_check("cutscene finished", not bridge.playing and not get_tree().paused)
	_check("actor removed", stage.actor("Rin") == null or stage.actor("Rin").is_queued_for_deletion())
	_check("gameplay rin restored in place", real.visible and real.position.is_equal_approx(Vector3(1.5, 0, 2.0)))
	_check("camera restored", get_viewport().get_camera_3d() == camera and camera.global_position.is_equal_approx(before))
	var tinted := Cutscene.new()
	tinted.id = "tint3d_test"
	tinted.script_text = "tint dawn\npause 0.05"
	bridge.play(tinted)
	for i in 40:
		if bridge._tint.color.is_equal_approx(StoryBridge3D.TINTS["dawn"]):
			break
		await get_tree().create_timer(0.05, true).timeout
	_check("tint dawn colours the 3D world", bridge._tint.color.is_equal_approx(StoryBridge3D.TINTS["dawn"]))
	for i in 40:
		if not bridge.playing:
			break
		await get_tree().create_timer(0.05, true).timeout
	_check("tint cleared after the cutscene", bridge._tint.color == Color.WHITE)
	var faint := Cutscene.new()
	faint.id = "faint3d_test"
	faint.script_text = "spawn Lying rin_faint rin_spot\npause 0.3"
	bridge.play(faint)
	await get_tree().create_timer(0.1, true).timeout
	var lying := bridge._stage.actor("Lying") as PersonRig3D
	_check("rin_faint is Rin's own model", lying != null and lying._pilot != null)
	_check("rin_faint plays the Faint clip", lying != null and lying._pilot.animation.current_animation == "Faint")
	for i in 40:
		if not bridge.playing:
			break
		await get_tree().create_timer(0.05, true).timeout
