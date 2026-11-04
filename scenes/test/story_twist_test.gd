extends Node
## The misdirection (PLAN §10 "Ma da + chú Bảy"): the ma da legend by act,
## chú Bảy at his corner table (every calm shift, nobody serves or sits with
## him, gone early with a warning on omen days, remembers loops, the sketch
## on mùng 11 in the diary hand, outside every uncanny effect), Vy's reveal
## on mùng 14, anh Út's green cord on the thúng from mùng 10 (gone after a
## reset), and the rằm endings. Run with F6.

const RESTAURANT := "res://scenes/restaurant3d/restaurant_scene_3d.tscn"
const VILLAGE := "res://scenes/village3d/village_scene_3d.tscn"
const SEA := "res://scenes/sea3d/sea_scene_3d.tscn"

var _failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveSystem.autosave_off = true
	_acts()
	_lines()
	await _every_shift()
	await _nobody_serves_him()
	await _omen_day()
	await _sketch()
	_vy_reveal()
	await _charm()
	await _endings()
	GameState.reset()
	print("STORY TWIST TEST ", "PASS" if _failures == 0 else "FAIL")
	get_tree().quit(1 if _failures else 0)


## Ghosts (mùng 9-10), doubt (11-12), a man (13-14).
func _acts() -> void:
	var news := load("res://data/story/news.tres") as NewsData
	_check("paper mùng 9: the village blames ma da", news.page(1).contains("ma da"))
	_check("paper mùng 10: the xã held a cúng giải hạn", news.page(2).contains("cúng giải hạn"))
	_check("paper mùng 13: the lighthouse is empty since last year + the diary", news.page(5).contains("bỏ trống") and news.page(5).contains("đèn xanh ở bè"))
	var ut := load("res://data/story/anh_ut.tres") as NpcLinesData
	_check("anh Út tells the ma da story on mùng 9", ut.lines_for(1)[0].contains("ma da"))
	var hai := load("res://data/story/chu_hai.tres") as NpcLinesData
	_check("chú Hai: the rope was cut clean... 'chắc ma da nó cắn' (mùng 11)", "".join(hai.lines_for(3)).contains("cắt ngọt") and "".join(hai.lines_for(3)).contains("ma da nó cắn"))
	_check("chú Hai on mùng 13: selling fish at anh Út's raft tonight", hai.lines_for(5)[0].contains("bè anh Út"))
	var clues := NightErrand3D.CLUES
	_check("sea clue mùng 13 is the lighthouse diary", clues.line(4).begins_with("Trang nhật ký"))
	_check("no diary before mùng 13", not clues.line(0).begins_with("Trang") and not clues.line(1).begins_with("Trang") and not clues.line(2).begins_with("Trang") and not clues.line(3).begins_with("Trang"))


func _lines() -> void:
	GameState.reset()
	var all_days := true
	for day in range(1, LoopCalendar.NIGHTS + 1):
		all_days = all_days and not ChuBayTalk3D.day_list(day).is_empty()
	_check("chú Bảy has lines every day", all_days)
	_check("present tense lighthouse ('đèn của chú tối nay')", ChuBayTalk3D.day_list(2)[0].contains("Đèn của chú tối nay"))
	_check("the only one who says ma da does not cut ropes (mùng 11)", ChuBayTalk3D.day_list(3)[0].contains("Ma da hổng có cắt dây"))
	_check("omen day: only 'Tối nay ở nhà đi con.'", ChuBayTalk3D.day_list(4, "hai_dang") == [ChuBayTalk3D.LINES.named_line("warn")] and ChuBayTalk3D.LINES.named_line("warn").ends_with("Tối nay ở nhà đi con."))
	# Loop memory: mùng 9 after a reset he remembers.
	GameState.set_flag(LoopCalendar.MISSED_FLAG, "hai_dang")
	LoopCalendar.reset_loop()
	var talk := ChuBayTalk3D.new()
	_check("after a reset his first line on mùng 9: 'Lại gặp con rồi'", talk.today()[0].contains("Lại gặp con rồi") and talk.today()[0].contains("đi đêm"))
	GameState.set_flag(LoopCalendar.MISSED_FLAG, LoopCalendar.MISSED_CALM)
	_check("... a calm night missed: the knock", talk.today()[0].contains("gõ cửa"))
	GameState.day = 2
	_check("... only on mùng 9", not talk.today()[0].contains("Lại gặp"))
	GameState.reset()
	_check("a first loop's mùng 9 has no memory line", not ChuBayTalk3D.new().today()[0].contains("Lại gặp"))


func _every_shift() -> void:
	for day in range(1, LoopCalendar.NIGHTS + 1):
		GameState.reset()
		GameState.day = day
		var room := await _restaurant()
		var bay := ChuBay3D.of(room)
		room._open_shift()
		await _frames(2)
		var ok := bay != null and bay.present() and bay.rig.visible and bay.cup.visible
		_check("calm shift day %d: chú Bảy at his corner table, the cup in front of him" % day, ok)
		if day == 1:
			_check("he is out of every uncanny effect / chase (uncanny_skip)", ChaseRules.skipped(bay.rig) and not UncannyDirector.two_faces_ok(bay.rig))
			_check("solid, model kept out of the guest pool", bay.rig.has_node("PersonBlocker") and PsxCharacterVisual.CAST.values().filter(
				func(v: String) -> bool: return v == PsxCharacterVisual.CAST["chu_bay"]).size() == 1)
			_check("damp clothes, not the ghost look", not bay.rig.visual().has_meta(StylePass3D.SKIP) and _damp(bay.rig))
			_check("E on him: a line, and Rin has met him", _talk_to(room, bay) and GameState.has_flag(ChuBayTalk3D.MET_FLAG))
			room._end_shift()
			await _frames(2)
			_check("after the shift he is gone", not bay.rig.visible)
		await _free(room)


## A whole busy shift: no guest sits at or walks through his table, Vy never goes there.
func _nobody_serves_him() -> void:
	GameState.reset()
	var room := await _restaurant()
	room._open_shift()
	var bay := ChuBay3D.of(room)
	var close := false
	var vy_near := false
	var traffic: CustomerTraffic3D
	for child in room.get_children():
		if child is CustomerTraffic3D:
			traffic = child
	# Ticked by hand (the runner allows 120 frames): ~50 s of shift.
	for i in 1000:
		room.spawn_clock = minf(room.spawn_clock, 0.5)
		room.shift.tick(0.05)
		traffic._process(0.05)
		room.vy.tick(0.05)
		bay._process(0.05)
		for rig: Node in room.find_children("*", "PersonRig3D", true, false):
			var person := rig as PersonRig3D
			if person == bay.rig or not person.is_visible_in_tree() or person.get_variant() == "rin":
				continue
			var d := Vector2(person.global_position.x - ChuBay3D.SEAT.x, person.global_position.z - ChuBay3D.SEAT.z).length()
			if d < 1.0:
				close = true
				print("  near his seat: ", person.get_variant(), " ", person.global_position)
		vy_near = vy_near or (room.vy.present() and room.vy.rig.global_position.distance_to(ChuBay3D.TABLE) < 1.0)
	_check("guests came during the test shift", room.orders.size() > 0 or room.guests.size() > 0)
	_check("nobody sits with him or brushes his table", not close)
	_check("Vy works around his table, never at it", not vy_near)
	_check("his table is not a service table and the floor grid blocks it", RestaurantLayout3D.TABLES.slice(0, RestaurantLayout3D.table_count()).all(
		func(t: Vector3) -> bool: return t.distance_to(ChuBay3D.TABLE) > 3.0) and FloorGrid3D.get_shared(RestaurantLayout3D.TABLES).blocked_at(ChuBay3D.TABLE))
	_check("his tea is still full (never drunk)", bay.cup.visible and bay.cup.get_child_count() == 2)
	await _free(room)


func _omen_day() -> void:
	GameState.reset()
	GameState.day = 4
	GameState.set_flag(LoopCalendar.OMEN_FLAG)
	GameState.set_flag(OmenPicker.ID_FLAG, "hai_dang")
	var room := await _restaurant()
	room._open_shift()
	await _frames(2)
	var bay := ChuBay3D.of(room)
	_check("omen day: he is there as the shift opens", bay.present())
	_check("... and only says 'Tối nay ở nhà đi con.'", bay.talk.today() == [ChuBayTalk3D.LINES.named_line("warn")])
	room.seconds_left = RestaurantShift3D.SHIFT_SECONDS * 0.4
	await _frames(2)
	_check("... then he is gone like anh Út, his full cup left", not bay.present() and not bay.rig.visible and bay.cup.visible)
	await _free(room)


func _sketch() -> void:
	GameState.reset()
	GameState.day = 3
	var room := await _restaurant()
	room._open_shift()
	await _frames(2)
	var bay := ChuBay3D.of(room)
	var said: Array[String] = []
	for i in bay.talk.today().size():
		said.append(bay.say())
	await _frames(2)
	var reader: PaperReader
	for node in room.get_children():
		if node is PaperReader:
			reader = node
	_check("mùng 11: his last line hands Rin a folded sketch", ChuBayTalk3D.is_sketch_line(said.back()) and GameState.has_flag(ChuBay3D.SKETCH_FLAG) and reader != null)
	var diary_tex := str(PaperLayout.spec("diary")["texture"])
	var paper_tex := ""
	if reader:
		for child in reader.get_children():
			if child is TextureRect:
				paper_tex = (child as TextureRect).texture.resource_path.get_file().get_basename()
	_check("... on the lighthouse diary's paper, in its hand (PaperReader 'diary')", paper_tex == diary_tex and reader.strokes.size() >= 8)
	_check("... and the diary page is read the same way", NightErrand3D.CLUES.line(4).begins_with("Trang"))
	if reader:
		get_tree().paused = false
		reader.queue_free()
	await _free(room)


func _vy_reveal() -> void:
	GameState.reset()
	GameState.day = 6
	_check("mùng 14 without talking to him: no reveal", not VyTalk3D.reveal_due())
	GameState.set_flag(ChuBayTalk3D.MET_FLAG)
	_check("mùng 14 after talking to him: 'Bàn góc đó trống mà anh'", VyTalk3D.reveal_due())
	GameState.day = 5
	_check("... only on mùng 14", not VyTalk3D.reveal_due())
	LoopCalendar.reset_loop()
	GameState.day = 6
	_check("... and Rin remembers him through a reset", VyTalk3D.reveal_due())
	var line: String = (load("res://data/story/vy_heard.tres") as NpcLinesData).named["bay_table"]
	_check("... the line names the lighthouse keeper's seat", line.contains("Bàn góc đó trống") and line.contains("gác đèn"))


func _charm() -> void:
	GameState.reset()
	GameState.day = 1
	var room := await _restaurant()
	room._open_shift()
	await _frames(2)
	var ut := RestaurantRoles3D.of(room).ut
	_check("mùng 9: anh Út has no charm to give", not ut.say().contains("bùa"))
	await _free(room)
	GameState.day = 2
	room = await _restaurant()
	room._open_shift()
	await _frames(2)
	ut = RestaurantRoles3D.of(room).ut
	var first := ut.say()
	_check("mùng 10: anh Út gives the green cord 'bùa trừ ma da'", first.contains("bùa trừ ma da") and first.contains("Buộc vô thúng") and ThungCharm3D.given())
	_check("... once", not ut.say().contains("bùa"))
	await _free(room)
	var village := (load(VILLAGE) as PackedScene).instantiate() as VillageScene3D
	add_child(village)
	await _frames(3)
	_check("the cord is on the pier thúng", _charm_visible(village))
	await _free(village)
	var sea := (load(SEA) as PackedScene).instantiate()
	add_child(sea)
	await _frames(3)
	_check("... and on the thúng at sea", _charm_visible(sea))
	await _free(sea)
	LoopCalendar.reset_loop()
	_check("a reset to mùng 9 takes it away", not ThungCharm3D.given())
	village = (load(VILLAGE) as PackedScene).instantiate() as VillageScene3D
	add_child(village)
	await _frames(3)
	_check("... the pier thúng is bare again", not _charm_visible(village) and village.find_children("ThungCharm", "", true, false).size() > 0)
	await _free(village)


func _endings() -> void:
	_check("true ending: chú Bảy stands just before ông Tư on the pier", RamEpilogue3D._ghost_variant(RamEpilogue3D.BAY) == "chu_bay"
		and RamEpilogue3D._ghost_variant(RamEpilogue3D.GHOSTS - 1) == "ong_tu" and RamEpilogue3D.BAY == RamEpilogue3D.GHOSTS - 2)
	var lines := RamFx3D.LINES
	_check("... the bodies under the raft wear the green cord", "".join(lines.dawn).contains("sợi chỉ xanh") and "".join(lines.card_true).contains("chỉ xanh"))
	_check("... the card lists chú Bảy among them", "".join(lines.card_true).contains("chú Bảy"))
	_check("bad ending card: the cord on the drifting thúng", "".join(lines.card_drowned).contains("chỉ xanh"))
	var stage := Node3D.new()
	add_child(stage)
	var shop := RamEpilogueShop3D.build(stage)
	await _frames(2)
	_check("bad ending: Rin's ghost on chú Bảy's corner stool, a young fisherman, anh Út", shop["ut"] is PersonRig3D and shop["young"] is PersonRig3D)
	_check("... the drifting thúng shows the cord", _charm_visible(stage))
	await _free(stage)
	var holder := Node3D.new()
	add_child(holder)
	var ghost := RamFx3D.ghost(holder, Vector3.ZERO, "chu_bay")
	_check("chú Bảy as a ghost on rằm (GhostLook)", GhostLook3D.is_ghost(ghost))
	holder.queue_free()
	var scare := TuGhostScare3D.new()
	var to_raft := SeaLayout3D.raft_bearing()
	_check("ông Tư's ghost points towards the lobster raft", Vector2(scare.raft_direction.x, scare.raft_direction.z).normalized().dot(Vector2(to_raft.x, to_raft.z)) > 0.99)
	scare.free()


func _charm_visible(root: Node) -> bool:
	for node in root.find_children("ThungCharm", "", true, false):
		if (node as Node3D).is_visible_in_tree():
			return true
	return false


func _damp(rig: PersonRig3D) -> bool:
	for mesh: MeshInstance3D in rig.visual().model.find_children("*", "MeshInstance3D", true, false):
		var m := mesh.get_surface_override_material(0)
		if m is BaseMaterial3D:
			return (m as BaseMaterial3D).albedo_color.b < 0.95
		if m is ShaderMaterial:
			var c: Variant = (m as ShaderMaterial).get_shader_parameter("albedo_color")
			return c is Color and (c as Color).r < 0.95
	return false


func _talk_to(room: RestaurantScene3D, bay: ChuBay3D) -> bool:
	room.player.position = ChuBay3D.SEAT + Vector3(1.3, 0, 1.2)
	room.demo_camera.global_position = room.player.position + Vector3(0, 1.55, 0)
	room.demo_camera.look_at(ChuBay3D.SEAT + Vector3(0, 1.1, 0))
	return RestaurantRoles3D.of(room).talk(room.player.position) and bay.talk.talks == 1


func _restaurant() -> RestaurantScene3D:
	var room := (load(RESTAURANT) as PackedScene).instantiate() as RestaurantScene3D
	room.auto_open = false
	add_child(room)
	await _frames(2)
	return room


func _free(node: Node) -> void:
	node.queue_free()
	await _frames(2)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
