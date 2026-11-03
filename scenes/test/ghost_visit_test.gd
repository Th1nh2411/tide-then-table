extends Node
## Standalone test for the ghosts' visit (run with F6): a calm night that went
## wrong (came back short of LoopCalendar.MIN_FISH, or stayed home) wakes Rin
## on mùng 9 with three knocks in the dark and wet footprints from the door to
## the bed; a right night or an omen night gone wrong has none. No words.

const VILLAGE := "res://scenes/village3d/village_scene_3d.tscn"

var _failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveSystem.autosave_off = true
	GameState.reset()
	GameState.day = 3
	LoopCalendar.choose(true, LoopCalendar.MIN_FISH - 1)
	var room := await _open()
	var prints := room.get_node_or_null(WetFootprints3D.NODE_NAME) as WetFootprints3D
	var wake := _wake(room)
	_check("short catch: back to mùng 9", GameState.day == 1)
	_check("short catch: wet footprints on the floor", prints != null and prints.get_child_count() >= 5)
	_check("short catch: knocks in the black before waking", wake != null and wake.knocks)
	if prints:
		var first := prints.get_child(0) as Node3D
		var last := prints.get_child(prints.get_child_count() - 1) as Node3D
		_check("the steps go from the door to the bed",
			first.position.distance_to(_room(BedroomBuilder3D.DOOR)) < last.position.distance_to(_room(BedroomBuilder3D.DOOR))
			and last.position.distance_to(_room(BedroomBuilder3D.BEDSIDE)) < 0.5)
	_check("no words explain it", room.text.saying() == "")
	_check("the wake gives control back within 5 s", wake != null and wake.total_seconds() < 5.0)
	_check("a calm miss is remembered (note_ flag)", LoopCalendar.missed() == LoopCalendar.MISSED_CALM)
	_check("the mùng 9 paper carries the calm hint", room.paper_hint() == VillageSpots3D.NEWS.calm_missed_hint)
	_check_note(room)
	room.queue_free()
	await get_tree().process_frame
	GameState.day = 2
	LoopCalendar.choose(false)
	room = await _open()
	_check("stayed home on a calm night: the same visit", room.has_node(WetFootprints3D.NODE_NAME) and _wake(room).knocks)
	room.queue_free()
	await get_tree().process_frame
	GameState.day = 2
	LoopCalendar.choose(true, LoopCalendar.MIN_FISH)
	room = await _open()
	_check("three fish: next day, nobody came", GameState.day == 3 and not room.has_node(WetFootprints3D.NODE_NAME))
	room.queue_free()
	await get_tree().process_frame
	GameState.set_flag(LoopCalendar.OMEN_FLAG)
	GameState.set_flag(OmenPicker.ID_FLAG, "tien_le")
	LoopCalendar.choose(true, 5)
	room = await _open()
	_check("out on an omen night: reset, but no footprints", GameState.day == 1 and not room.has_node(WetFootprints3D.NODE_NAME))
	var missed := OmenPicker.CATALOG.find("tien_le")
	_check("the missed omen is remembered, its hint on the paper", LoopCalendar.missed() == "tien_le"
		and missed.missed_hint != "" and room.paper_hint() == missed.missed_hint)
	_check("the hint never names the rules", not missed.missed_hint.to_lower().contains("điềm"))
	room.queue_free()
	GameState.reset()
	print("GHOST VISIT TEST ", "PASS" if _failures == 0 else "FAIL")
	get_tree().quit(1 if _failures else 0)


## "Những điều kiêng" on the wall by the door: E on it while looking at it.
func _check_note(room: VillageScene3D) -> void:
	room.waking = false
	var note := _room(BedroomBuilder3D.NOTE)
	room.player.position = Vector3(note.x, 0, note.z + 0.9)
	room.demo_camera.global_position = room.player.position + Vector3(0, 1.55, 0)
	room.demo_camera.look_at(note)
	_check("looking at the note by the door targets it", room.spots.target() == "note")
	var kieng := VillageSpots3D.KIENG
	var body := kieng.body()
	_check("the note has 4-6 rules and no game words", kieng.lines.size() >= 4 and kieng.lines.size() <= 6
		and not body.to_lower().contains("điềm") and not body.to_lower().contains("anomaly"))


func _room(local: Vector3) -> Vector3:
	return VillageLayout3D.room_point(local)


func _open() -> VillageScene3D:
	var room := (load(VILLAGE) as PackedScene).instantiate() as VillageScene3D
	add_child(room)
	await get_tree().process_frame
	return room


func _wake(room: Node) -> NightmareWake3D:
	for child in room.get_children():
		if child is NightmareWake3D:
			return child
	return null


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
