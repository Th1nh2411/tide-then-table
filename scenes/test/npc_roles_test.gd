extends Node
## Every villager has a role (PLAN §10): ông Tám on the waterfront at dawn,
## chú Hai in the lane at dawn / night (gone from mùng 14, bike left), anh Út
## at his table during the shift (absent on omen nights, a shadowless guest
## there from mùng 12), Bảo / Cô Năm / Vy / ông Tư's altar lines by day from
## data, the same after a loop reset except ông Tám's first line; nobody
## stands on the bot's route. Run with F6.

const RESTAURANT := "res://scenes/restaurant3d/restaurant_scene_3d.tscn"
const VILLAGE := "res://scenes/village3d/village_scene_3d.tscn"
const DATA := ["bao", "co_nam", "anh_ut", "ong_tam", "chu_hai", "ong_tu", "vy_heard"]
const CLEARANCE := 0.75

var _failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveSystem.autosave_off = true
	_data()
	_loop_reset()
	await _village_day()
	await _village_gone()
	await _omen_nights()
	await _ram()
	GameState.reset()
	print("NPC ROLES TEST ", "PASS" if _failures == 0 else "FAIL")
	get_tree().quit(1 if _failures else 0)


## Lines live in data, 7 days each, named speakers, short.
func _data() -> void:
	var ok := true
	var short := true
	for id: String in DATA:
		var lines := load("res://data/story/%s.tres" % id) as NpcLinesData
		ok = ok and lines != null and lines.days.size() == LoopCalendar.NIGHTS and lines.speaker != ""
		for day in range(1, LoopCalendar.NIGHTS + 1):
			for line: String in lines.lines_for(day, "", "", false) + lines.lines_for(day, "", "", true):
				short = short and line.length() <= 130
	_check("every villager's lines are data, one entry per day", ok)
	_check("every line is short", short)
	var tam := load("res://data/story/ong_tam.tres") as NpcLinesData
	var all_ids := true
	for omen in OmenPicker.CATALOG.omens:
		all_ids = all_ids and tam.after_reset.has(omen.id)
	_check("ông Tám has an after-reset line for every omen and the calm night", all_ids and tam.after_reset.has(LoopCalendar.MISSED_CALM))
	var bao := load("res://data/story/bao.tres") as NpcLinesData
	_check("Bảo: anh Út's wet money on mùng 12-14", [4, 5, 6].all(func(d: int) -> bool: return bao.lines_for(d)[0].to_lower().contains("tiền")))
	var nam := load("res://data/story/co_nam.tres") as NpcLinesData
	_check("Cô Năm on mùng 14: thằng Út dư tiền", nam.lines_for(6)[0].contains("Út") and nam.lines_for(6)[0].contains("dư tiền"))
	var hai := load("res://data/story/chu_hai.tres") as NpcLinesData
	_check("chú Hai: the name-call omen's second tell, at night only",
		hai.lines_for(3, "goi_ten", "", true)[0].contains("kêu tên") and not hai.lines_for(3, "goi_ten", "", false)[0].contains("kêu tên"))
	_check("chú Hai has nothing on mùng 14 and rằm", not hai.has_day(6) and not hai.has_day(7, true))


## A reset brings the same lines back; only ông Tám's first line changes.
func _loop_reset() -> void:
	GameState.reset()
	var before := _all_lines()
	GameState.set_flag(LoopCalendar.MISSED_FLAG, "hai_dang")
	LoopCalendar.reset_loop()
	var after := _all_lines()
	var same := true
	for id: String in before:
		if id != "ong_tam":
			same = same and before[id] == after[id]
	_check("after a reset everyone says the same as before", same and after["vy"] == before["vy"])
	var tam: Array = after["ong_tam"]
	var tam_lines := load("res://data/story/ong_tam.tres") as NpcLinesData
	_check("ông Tám: after a reset his first line names the missed omen", tam[0] == tam_lines.format(str(tam_lines.after_reset["hai_dang"])))
	_check("... then his usual line of the day", tam.slice(1) == before["ong_tam"])
	GameState.set_flag(LoopCalendar.MISSED_FLAG, LoopCalendar.MISSED_CALM)
	_check("... a calm night missed: the wet visitor", (_all_lines()["ong_tam"] as Array)[0].contains("Ướt"))
	GameState.day = 2
	_check("... only on mùng 9", (_all_lines()["ong_tam"] as Array) == (load("res://data/story/ong_tam.tres") as NpcLinesData).lines_for(2))
	GameState.reset()


func _all_lines() -> Dictionary:
	var out := {}
	for id: String in DATA:
		var talk := NpcTalk3D.new(null, load("res://data/story/%s.tres" % id) as NpcLinesData)
		out[id] = talk.today()
	out["vy"] = VyTalk3D.day_list(GameState.day)
	return out


## Mùng 9 on the village map: dawn, the shift, night.
func _village_day() -> void:
	GameState.reset()
	var village := await _load_village()
	var npcs := village.npcs
	var roles := RestaurantRoles3D.of(village)
	_check("dawn: ông Tám sits on the waterfront", npcs.tam.visible and VillageLayout3D.area(npcs.tam.global_position) == "waterfront")
	_check("dawn: chú Hai is in the lane with his bike", npcs.hai.rig.visible and npcs.hai.bike.visible and VillageLayout3D.area(npcs.hai.rig.global_position) == "lane")
	_check("dawn: anh Út is not at the restaurant yet", roles.ut != null and not roles.ut.seated())
	_check("nobody is in Rin's room", not VillageLayout3D.in_room(npcs.tam.global_position) and not VillageLayout3D.in_room(npcs.hai.rig.global_position))
	_check("they are solid", npcs.tam.has_node("PersonBlocker") and npcs.hai.rig.has_node("PersonBlocker"))
	_check("dawn: the route is clear", _route_clear(village))
	# Talk to ông Tám.
	_look(village, npcs.tam.global_position + Vector3(-0.6, 0, 1.2), npcs.tam.global_position + Vector3(0, 1.1, 0))
	_check("E on ông Tám: his line of the day", npcs.interact() and npcs.tam_talk.talks == 1 and village.text != null)
	_check("E prompt near him: one lowercase verb, no key words", npcs.prompt() == "hỏi" and village.prompt_verb() == "hỏi")
	var tam_first: String = npcs.tam_talk.today()[0]
	_check("mùng 9: ông Tám tells where the fish are", tam_first.contains("sủi bọt") and not tam_first.contains("E "))
	# Rin walks into the lane: chú Hai pushes the bike a few steps, still off the route.
	village.player.position = Vector3(VillageLayout3D.EXIT_X + 8.0, 0, VillageLayout3D.LANE_Z)
	for i in 400:
		npcs.hai._process(0.05)
	_check("dawn: chú Hai pushes his bike towards the street", npcs.hai.bike.position.x < ChuHai3D.BIKE_HOME.x - 2.5)
	_check("... and the lane stays clear", _route_clear(village))
	_look(village, npcs.hai.rig.global_position + Vector3(0, 0, 1.3), npcs.hai.rig.global_position + Vector3(0, 1.4, 0))
	_check("E on chú Hai at dawn", npcs.interact() and npcs.hai.talk.talks == 1)
	# The shift.
	village.player.position = Vector3(10, 0, 4)
	await _frames(3)
	_check("shift: the shift is open", village.shift_running)
	_check("shift: ông Tám and chú Hai are away", not npcs.tam.visible and not npcs.hai.rig.visible and not npcs.hai.bike.visible)
	_check("shift: anh Út sits at his table on the street", roles.ut.seated() and VillageLayout3D.area(roles.ut.ut.global_position) == "street")
	_check("shift: his table is not one of the service tables", RestaurantLayout3D.TABLES.slice(0, RestaurantLayout3D.table_count()).all(
		func(t: Vector3) -> bool: return t.distance_to(AnhUtRegular3D.TABLE) > 3.0))
	_look(village, AnhUtRegular3D.SEAT + Vector3(-1.2, 0, 1.3), AnhUtRegular3D.SEAT + Vector3(0, 1.1, 0))
	var said := roles.ut.talk.talks
	village._interact()
	_check("E on anh Út: his line of the day", roles.ut.talk.talks == said + 1)
	_look(village, Vector3(1.5, 0, -3.3), village.bao_model.global_position + Vector3(0, 1.5, 0))
	_check("E on Bảo (looked at, hands free)", roles.talk(village.player.position) and roles.bao.talks == 1)
	village.player.position = RestaurantLayout3D.COUNTER_POSITION + Vector3(0, 0, 1.2)
	village._interact()
	_check("E at Cô Năm's counter: her line of the day", roles.co_nam.talks == 1)
	# Night.
	village._end_shift()
	await _frames(3)
	_check("night: anh Út went home", not roles.ut.seated())
	_check("night: chú Hai smokes by his door", npcs.hai.rig.visible and npcs.hai.talk.night and npcs.hai.bike.position == ChuHai3D.BIKE_HOME)
	_check("night: ông Tám is not out", not npcs.tam.visible)
	_check("night: the route is clear", _route_clear(village))
	# Ông Tư's altar.
	_look(village, VillageLayout3D.room_point(AltarTu3D.AIM + Vector3(0.2, -1.6, -0.75)), VillageLayout3D.room_point(AltarTu3D.AIM))
	_check("E on the altar", village.spots.target() == "altar" and village.prompt_verb() == "thắp nhang")
	village.spots.act("altar")
	_check("... incense and ông Tư's whisper", village.spots.altar.incense != null and village.spots.altar.talk.talks == 1)
	await _free(village)


## Mùng 14: chú Hai is gone, his bike stays by the door; ông Tám says so.
func _village_gone() -> void:
	GameState.reset()
	GameState.day = 6
	var village := await _load_village()
	var hai := village.npcs.hai
	_check("mùng 14: chú Hai is gone", hai.rig == null)
	_check("... his bike is still by his door", hai.bike.visible and hai.bike.position == ChuHai3D.BIKE_HOME)
	_check("... ông Tám tells it", (village.npcs.tam_talk.today()[-1] as String).contains("Hai"))
	village._open_shift()
	await _frames(2)
	_check("... the bike stays there all day", hai.bike.visible)
	await _free(village)


## Omen nights: anh Út's stool is empty; from mùng 12 a guest without a shadow sits there.
func _omen_nights() -> void:
	for day: int in [2, 4]:
		GameState.reset()
		GameState.day = day
		GameState.set_flag(LoopCalendar.OMEN_FLAG)
		GameState.set_flag(OmenPicker.ID_FLAG, "hai_dang")
		var room := (load(RESTAURANT) as PackedScene).instantiate() as RestaurantScene3D
		room.auto_open = false
		add_child(room)
		await _frames(2)
		room._open_shift()
		await _frames(2)
		var ut := RestaurantRoles3D.of(room).ut
		_check("omen night (day %d): anh Út does not come" % day, ut.absent and ut.ut == null and not ut.seated())
		if day < ut.ghost_from_day:
			_check("... his stool is empty", ut.ghost == null)
		else:
			var shadowless := ut.ghost != null and ut.ghost.visible
			for mesh: GeometryInstance3D in ut.ghost.find_children("*", "GeometryInstance3D", true, false):
				shadowless = shadowless and mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_check("... a guest without a shadow sits in his place", shadowless)
			_check("... E there: a dead whisper", ut.ghost_near(AnhUtRegular3D.SEAT + Vector3(-1.4, 0, 0)) and ut.ghost_line().begins_with("..."))
		var nam := RestaurantRoles3D.of(room).co_nam
		_check("... Cô Năm's first line is the omen's tell", nam.today()[0].contains("Đá Canh Đêm"))
		room.queue_free()
		await _frames(2)


## Rằm: no regular seat, RamGuest3D has him.
func _ram() -> void:
	GameState.reset()
	GameState.day = LoopCalendar.NIGHTS
	var room := (load(RESTAURANT) as PackedScene).instantiate() as RestaurantScene3D
	room.auto_open = false
	add_child(room)
	await _frames(2)
	_check("rằm: anh Út comes for the tea only (RamGuest3D)", room.get_node_or_null(AnhUtRegular3D.NODE_NAME) == null and room.get_node_or_null("AnhUt") != null)
	room.queue_free()
	await _frames(2)


## The bot's way: room door -> waterfront -> lane -> street, and the pier.
func _route_clear(village: VillageScene3D) -> bool:
	var w := func(p: Vector3) -> Vector3: return VillageLayout3D.waterfront_point(p)
	var legs: Array = [
		[w.call(WaterfrontBuilder3D.DOOR), w.call(WaterfrontBuilder3D.LANE) + Vector3(2, 0, 0)],
		[Vector3(VillageLayout3D.LANE_END_X, 0, VillageLayout3D.LANE_Z), Vector3(VillageLayout3D.EXIT_X, 0, VillageLayout3D.LANE_Z)],
		[Vector3(VillageLayout3D.EXIT_X, 0, VillageLayout3D.LANE_Z), Vector3(2.0, 0, VillageLayout3D.LANE_Z)],
		[w.call(WaterfrontBuilder3D.DOOR), VillageLayout3D.pier_start()],
	]
	var solid: Array[Vector3] = []
	var npcs := village.npcs
	if npcs.tam.visible:
		solid.append(npcs.tam.global_position)
	if npcs.hai.rig and npcs.hai.rig.visible:
		solid.append(npcs.hai.rig.global_position)
	var ut := RestaurantRoles3D.of(village).ut
	if ut and ut.seated():
		solid.append(ut.ut.global_position)
	if npcs.hai.bike.visible:
		for dx: float in [-0.8, 0.0, 0.8]:
			solid.append(npcs.hai.bike.global_position + Vector3(dx, 0, 0))
	for leg: Array in legs:
		for i in 41:
			var p: Vector3 = (leg[0] as Vector3).lerp(leg[1], i / 40.0)
			for s: Vector3 in solid:
				if Vector2(p.x - s.x, p.z - s.z).length() < CLEARANCE:
					print("  blocked near ", s, " at ", p)
					return false
	return true


func _load_village() -> VillageScene3D:
	var village := (load(VILLAGE) as PackedScene).instantiate() as VillageScene3D
	add_child(village)
	await _frames(2)
	village.waking = false
	return village


func _look(village: VillageScene3D, at: Vector3, target: Vector3) -> void:
	village.player.position = at
	village.demo_camera.global_position = at + Vector3(0, 1.55, 0)
	village.demo_camera.look_at(target)


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
