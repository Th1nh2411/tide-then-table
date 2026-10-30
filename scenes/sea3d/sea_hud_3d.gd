class_name SeaHud3D
extends RefCounted
## HUD (SeaHudView3D: icon chips, key caps, speech strip), shared UI (pause,
## hold, phone, POI dialog, quest note), edge navigation and first-time
## guides of the 3D sea.
## Host (SeaScene3D) fields written: hud_view, message, new_catch_card,
## hold_ui, poi_dialog, phone_app, navigation.

const PLACE_NAMES := {"shrine": "Miếu Cá Ông", "lighthouse": "Hải đăng Đá Canh Đêm",
	"hut": "Chòi ông Tám", "raft": "Bè tôm hùm anh Út"}

static func build_hud(sea: SeaScene3D) -> void:
	var layer := CanvasLayer.new()
	sea.add_child(layer)
	sea.hud_view = SeaHudView3D.new()
	layer.add_child(sea.hud_view)
	# The current Rin / NEO line (SeaScene3D._say queue); the view shows it on
	# its speech strip.
	sea.message = Label.new()
	sea.message.visible = false
	layer.add_child(sea.message)

static func build_shared_ui(sea: SeaScene3D) -> void:
	# Reuse the existing pause, inventory and phone scenes with their saved data.
	sea.new_catch_card = NewCatchCard.new()
	sea.add_child(sea.new_catch_card)
	var tracker := QuestTracker.new()
	tracker.catalog = sea.fish_catalog
	tracker.origin = Vector2(8, 62)
	tracker.hidden_when = func() -> bool: return sea.fishing or (sea.hold_ui != null and sea.hold_ui.visible)
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
	sea._next_line()
	sea.hud_view.refresh(sea)

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
