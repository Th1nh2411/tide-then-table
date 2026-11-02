extends Node
## Standalone test for NightErrand3D (run with F6): a calm night puts one thing
## to pick up inside the thúng's reach, picking it up writes a notebook page that
## survives a loop reset; an omen night has none.

const SEA := "res://scenes/sea3d/sea_scene_3d.tscn"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	SaveSystem.autosave_off = true
	var failures := 0
	GameState.reset()
	GameState.day = 2
	var sea := (load(SEA) as PackedScene).instantiate() as SeaScene3D
	add_child(sea)
	await get_tree().process_frame
	var errand := sea.get_node_or_null("NightErrand") as NightErrand3D
	failures += _check("calm night has an errand", errand != null)
	if errand:
		var reach := SeaLayout3D.reach_z(sea.boat_data.max_depth)
		failures += _check("errand is inside the boat's reach", errand.global_position.z > reach)
		sea.boat.global_position = errand.global_position + Vector3(0.5, 0, 0)
		failures += _check("near it, Rin can pick it up", errand._near())
		errand.pick_up()
		failures += _check("picking up writes notebook page 2", GameState.has_flag("note_clue_2") and NightErrand3D.clue_count() == 1)
	LoopCalendar.reset_loop()
	failures += _check("the notebook survives a loop reset", GameState.has_flag("note_clue_2"))
	sea.queue_free()
	await get_tree().process_frame
	GameState.set_flag(LoopCalendar.OMEN_FLAG)
	sea = (load(SEA) as PackedScene).instantiate() as SeaScene3D
	add_child(sea)
	await get_tree().process_frame
	failures += _check("omen night has no errand", sea.get_node_or_null("NightErrand") == null)
	sea.queue_free()
	GameState.reset()
	print("NIGHT ERRAND TEST ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(1 if failures else 0)


func _check(label: String, ok: bool) -> int:
	print(("PASS " if ok else "FAIL ") + label)
	return 0 if ok else 1
