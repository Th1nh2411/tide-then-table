class_name SeaHud3D
extends RefCounted
## Text HUD, shared UI (pause, hold, phone, POI dialog, quest tracker),
## edge navigation and first-time guides of the 3D sea.
## Host (SeaScene3D) fields written: header, help, message, new_catch_card,
## hold_ui, poi_dialog, phone_app, navigation.

const PLACE_NAMES := {"shrine": "Miếu Cá Ông", "lighthouse": "Hải đăng Đá Canh Đêm",
	"hut": "Chòi ông Tám", "raft": "Bè tôm hùm anh Út"}

static func build_hud(sea: SeaScene3D) -> void:
	var layer := CanvasLayer.new()
	sea.add_child(layer)
	sea.header = Label.new()
	sea.header.position = Vector2(14, 10)
	sea.header.add_theme_font_size_override("font_size", 11)
	sea.header.add_theme_color_override("font_color", Color("e7d5b3"))
	layer.add_child(sea.header)
	sea.help = Label.new()
	sea.help.position = Vector2(14, 326)
	sea.help.text = "W/S ga · A/D lái · E tương tác · Q lưới · Tab khoang · J điện thoại · M bản đồ\nBến: R về nhà · F sửa thuyền · Esc tạm dừng"
	sea.help.add_theme_font_size_override("font_size", 9)
	sea.help.add_theme_color_override("font_color", Color("a4dddb"))
	layer.add_child(sea.help)
	sea.message = Label.new()
	sea.message.position = Vector2(14, 58)
	sea.message.add_theme_color_override("font_color", Color("f2d98a"))
	layer.add_child(sea.message)

static func build_shared_ui(sea: SeaScene3D) -> void:
	# Reuse the existing pause, inventory and phone scenes with their saved data.
	sea.new_catch_card = NewCatchCard.new()
	sea.add_child(sea.new_catch_card)
	var tracker := QuestTracker.new()
	tracker.catalog = sea.fish_catalog
	tracker.origin = Vector2(6, 82)
	sea.add_child(tracker)
	var pause := load("res://scenes/ui/pause_menu.tscn") as PackedScene
	if pause:
		sea.add_child(pause.instantiate())
	var hold_scene := load("res://scenes/ui/hold_ui.tscn") as PackedScene
	if hold_scene:
		sea.hold_ui = hold_scene.instantiate() as HoldUI
		sea.add_child(sea.hold_ui)
		sea.hold_ui.setup(sea.hold)
	sea.poi_dialog = PoiDialog.new()
	sea.add_child(sea.poi_dialog)
	var phone_scene := load("res://scenes/ui/phone_app.tscn") as PackedScene
	if phone_scene:
		sea.phone_app = phone_scene.instantiate() as PhoneApp
		sea.phone_app.repair_allowed = sea._at_dock
		sea.phone_app.repair_action = func() -> int: return BoatCondition.repair(sea.boat_data)
		sea.add_child(sea.phone_app)

static func update(sea: SeaScene3D) -> void:
	var prompt := "E dỡ cá • R về nhà" if sea._at_dock() else "E câu tại phao sáng"
	var poi := sea._nearest_poi()
	if poi != "":
		if poi.begins_with("event_"):
			var event := sea.night_events[int(poi.substr(6))]
			prompt = "E vớt chai thư" if int(event["kind"]) == NightEvents.Kind.BOTTLE else "E hỏi ghe chết máy"
		else:
			prompt = "E ghé " + str(PLACE_NAMES.get(poi, poi))
	sea.header.text = "%s · %s · %dk · Dầu %d%% · Thân thuyền %d%%\nCá %d · Lưới %d/2 · %s" % [sea.boat_data.display_name, DayClock.get_time_text(), GameState.money, roundi(sea.oil / sea.oil_capacity * 100.0), roundi(GameState.boat_hp), sea.hold.items.size(), sea.nets.size(), prompt]
	if Time.get_ticks_msec() / 1000.0 > sea.status_until:
		sea.message.text = ""

static func build_navigation(sea: SeaScene3D) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	sea.add_child(layer)
	var navigation: Control = preload("res://scenes/sea3d/sea_navigation_3d.gd").new()
	navigation.set("world", sea)
	navigation.set("camera", sea.camera)
	layer.add_child(navigation)
	sea.navigation = navigation
	var guide := Guide.new()
	guide.blocked = func() -> bool: return sea.fishing or sea.ending or sea.poi_busy or (sea.hold_ui and sea.hold_ui.visible) or (sea.phone_app and sea.phone_app.visible)
	sea.add_child(guide)
	# No pointer to shoals: the hint is the bubbles themselves.
	guide.add("sea3d_bubbles", "Tìm bọt khí trên mặt biển", func() -> bool: return not sea.fishing and sea._casts_used_total() == 0,
		func() -> Vector2: return navigation.call("screen_point", sea.boat.position + Vector3(0, 3.0, 0)),
		func() -> bool: return sea.fishing or sea._casts_used_total() > 0)
	guide.add("sea3d_dock", "Về bến dỡ cá", func() -> bool: return not sea.fishing and sea.hold.fill_fraction() >= 0.6,
		func() -> Vector2: return navigation.call("screen_point", sea.START),
		func() -> bool: return sea.hold.items.is_empty())

static func navigation_targets(sea: SeaScene3D) -> Array[Dictionary]:
	var targets: Array[Dictionary] = [{"pos": sea.START, "label": "Bến", "color": "f2d98a"}]
	for net in sea.nets:
		var full: int = roundi(clampf((sea.elapsed - float(net["time"])) / 90.0, 0.0, 1.0) * 100.0)
		targets.append({"pos": net["pos"], "label": "Lưới %d%%" % full, "color": "de9e41"})
	for i in range(GameState.map_pins.size()):
		var pin: Vector2 = GameState.map_pins[i]
		targets.append({"pos": SeaLayout3D.to_world(pin), "label": "Ghim %d" % (i + 1), "color": "d99ccc"})
	for entry: Array in [[sea.SHRINE_POS, "Miếu"], [sea.HUT_POS, "Ông Tám"], [sea.LIGHTHOUSE_POS, "Hải đăng"], [sea.RAFT_POS, "Bè tôm"]]:
		var pos: Vector3 = entry[0]
		if sea.boat.position.distance_to(pos) < 20.0:
			targets.append({"pos": pos, "label": entry[1], "color": "c6b89a"})
	if Story.is_fog_open():
		targets.append({"pos": sea.WHIRLPOOL_POS, "label": "???", "color": "5ff2e0"})
	return targets
