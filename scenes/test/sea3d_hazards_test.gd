extends Node
## 3D sea parity with the 2D hazards and fog: submerged rocks seen only in
## the lamp's reach, lines queued, the glowing fish line, fog clouds.

const SEA := "res://scenes/sea3d/sea_scene_3d.tscn"

var failures: int = 0

func check(value: bool, label: String) -> void:
	print("PASS " + label if value else "FAIL " + label)
	if not value:
		failures += 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.reset()
	var sea := await _open_sea()
	check(SeaLayout3D.submerged_rocks().size() == 12, "12 submerged rocks like the 2D sea")
	check(sea.submerged.size() == 12, "sea builds every submerged rock")
	var rock: SubmergedRock3D = sea.submerged[0]
	sea.boat.position = rock.position + Vector3(40, 0, 0)
	rock.update_view(0.0)
	check(is_zero_approx(rock.reveal), "submerged rock is hidden in the dark")
	sea.boat.position = rock.position + Vector3(rock.view_range * 0.5, 0, 0)
	rock.update_view(0.0)
	check(is_equal_approx(rock.reveal, 1.0), "submerged rock shows inside the lamp's reach")
	var bodies := rock.find_children("*", "StaticBody3D", false, false)
	check(bodies.size() == 1, "submerged rock always has a collider")
	var clear := true
	for shoal in sea.shoals:
		for r in SeaLayout3D.submerged_rocks():
			if shoal.pos.distance_to(r["pos"]) < float(r["radius"]):
				clear = false
	check(clear, "no shoal spawns on a submerged rock")
	sea._say("Một.", 2.0)
	sea._say("Hai.", 2.0)
	check(sea.message.text == "Một." and not sea._said.is_empty(), "a second line waits in the queue")
	sea.status_until = 0.0
	sea._next_line()
	check(sea.message.text == "Hai.", "next queued line shows after the first ends")
	check(sea.find_children("*", "SeaFog3D", false, false).is_empty(), "no fog before the omen")
	var omen_fish := load("res://data/fish/ca_thu_phat_sang.tres") as FishData
	sea._said.clear()
	sea.status_until = 0.0
	sea._next_line()
	# Landed on the rod (Fishing3D), as the fight's end does it.
	sea.rod.fish = omen_fish
	sea.rod.size = 1.0
	BiteReel3D.land(sea.rod)
	var warned := sea.message.text.contains("phát sáng")
	for line: Array in sea._said:
		warned = warned or str(line[0]).contains("phát sáng")
	check(warned, "glowing mackerel makes Rin wonder")
	sea.queue_free()
	await get_tree().process_frame
	# Omen yesterday -> fog open today.
	GameState.set_flag(Story.OMEN_DAY_FLAG, GameState.day - 1)
	sea = await _open_sea()
	check(sea.find_children("*", "SeaFog3D", false, false).size() == 1, "fog clouds once the fog is open")
	var lines := sea.message.text
	for line: Array in sea._said:
		lines += "\n" + str(line[0])
	check(lines.contains("Sương phủ kín góc đông bắc"), "fog-open night line is said")
	sea.queue_free()
	get_tree().quit(1 if failures > 0 else 0)

func _open_sea() -> SeaScene3D:
	var sea := (load(SEA) as PackedScene).instantiate() as SeaScene3D
	add_child(sea)
	sea.set_physics_process(false)
	await get_tree().process_frame
	return sea
