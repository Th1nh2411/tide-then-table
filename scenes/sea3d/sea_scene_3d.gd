extends Node3D
## Night trip in 3D. Persistent fish, upgrades, oil, hull and clock use the
## existing game systems; only the presentation and boat controller are new.

const REST_SCENE := "res://scenes/rest/rest_scene.tscn"
const ENDING_SCENE := "res://scenes/ending/ending_scene.tscn"
const FISHING_OVERLAY := "res://scenes/fishing3d/fishing_overlay_3d.tscn"
const ROD_UPGRADE := preload("res://data/upgrades/rod_upgrade.tres")
const LAMP_UPGRADE := preload("res://data/upgrades/lamp_upgrade.tres")
const OIL_BURN_PER_SECOND: float = 100.0 / 240.0

@export var fish_catalog: FishCatalog
@export var boat_upgrade: UpgradeData
@export var weather_catalog: WeatherCatalog
@export var trip_end_cutscenes: Array[Cutscene] = []

@onready var boat: CharacterBody3D = $Boat
@onready var boat_visual: Node3D = $Boat/BoatVisual
@onready var camera: Camera3D = $Camera3D

var boat_data: BoatData
var weather: WeatherData
var hold: GridInventory
var oil := 100.0
var oil_capacity := 100.0
var oil_low_sent := false
var oil_critical_sent := false
# Same layout as the 2D sea (SeaLayout3D); shoals are rolled each night (SeaShoals3D).
var START: Vector3 = SeaLayout3D.to_world(SeaLayout3D.DOCK_PX)
var SHRINE_POS: Vector3 = SeaLayout3D.to_world(SeaLayout3D.SHRINE_PX)
var LIGHTHOUSE_POS: Vector3 = SeaLayout3D.to_world(SeaLayout3D.LIGHTHOUSE_PX)
var HUT_POS: Vector3 = SeaLayout3D.to_world(SeaLayout3D.HUT_PX)
var RAFT_POS: Vector3 = SeaLayout3D.to_world(SeaLayout3D.RAFT_PX)
var WHIRLPOOL_POS: Vector3 = SeaLayout3D.to_world(SeaLayout3D.WHIRLPOOL_PX)
var shoals: Array[SeaShoals3D.Shoal] = []
var new_catch_card: NewCatchCard
var _wait_controls_release := false
var _application_focused := true
var navigation: Control
var yaw_velocity := 0.0
var impact_cooldown := 0.0
var elapsed := 0.0
var fishing := false
var ending := false
var status := ""
var status_until := 0.0
var rng := RandomNumberGenerator.new()
var overlay: CanvasLayer
var debug_cutscene_index := 0
var header: Label
var help: Label
var message: Label
var wave_marks: Array[MeshInstance3D] = []
var bubble_spots: Array[BubbleSpot3D] = []
var cinematic: CastCinematic3D
## Tests and bots can turn the cast scene off (E then opens the minigame at once).
var cast_cinematic_enabled := true
var rin_figure: Array[Node3D] = []
var _cast_played := false
var wake_marks: Array[MeshInstance3D] = []
var material_cache: Dictionary = {}
var wind := Vector3.ZERO
var boat_lamp: SpotLight3D
var hold_ui: HoldUI
var phone_app: PhoneApp
var nets: Array[Dictionary] = []
var net_haul_count := 0
var net_haul: Array[Array] = []
var story_bridge: Node
var map_boat_proxy: Node2D
var poi_dialog: PoiDialog
var poi_busy := false
var shrine_blessed := false
var blessed_damage_scale := 1.0
var whirlpool_marks: Array[MeshInstance3D] = []
var night_events: Array[Dictionary] = []

func _mat(hex: String) -> StandardMaterial3D:
	if material_cache.has(hex):
		return material_cache[hex]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.roughness = 0.9
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material_cache[hex] = mat
	return mat

func _box(parent: Node3D, pos: Vector3, size: Vector3, hex: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _mat(hex)
	parent.add_child(node)
	node.position = pos
	return node

func _cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, hex: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	node.mesh = mesh
	node.material_override = _mat(hex)
	parent.add_child(node)
	node.position = pos
	return node

func _solid_box(pos: Vector3, size: Vector3, hex: String) -> void:
	_box(self, pos, size, hex)
	var body := StaticBody3D.new()
	add_child(body)
	body.position = pos
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

func _label(text: String, pos: Vector3, size: int, hex: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.008
	label.modulate = Color(hex)
	label.outline_size = 0
	add_child(label)
	label.position = pos

func _ready() -> void:
	rng.randomize()
	boat_data = GameState.get_upgrade_value(boat_upgrade) as BoatData if boat_upgrade else null
	if boat_data == null:
		boat_data = load("res://data/boats/thuyen_thung.tres") as BoatData
	weather = weather_catalog.find(GameState.weather_id) if weather_catalog else null
	if weather and weather.wind_speed > 0.0:
		wind = Vector3.RIGHT.rotated(Vector3.UP, rng.randf() * TAU) * weather.wind_speed / 10.0
	oil_capacity = float(GameState.get_upgrade_value(LAMP_UPGRADE))
	oil = oil_capacity
	hold = GridInventory.new(boat_data.hold_size)
	boat.position = START
	shoals = SeaShoals3D.spawn(fish_catalog, rng, Story.is_fog_open(), weather.extra_spots if weather else 0,
		weather.rarity_bonus if weather else 0.0, weather.species_bonus if weather else {})
	_build_environment()
	_build_world()
	_build_pois()
	_build_night_events()
	_build_map_adapter()
	_build_boat()
	if weather:
		boat_lamp.spot_range *= weather.lamp_scale
	_build_hud()
	_build_shared_ui()
	var story_scene := load("res://scenes/story3d/story_bridge_3d.tscn") as PackedScene
	if story_scene:
		story_bridge = story_scene.instantiate()
		add_child(story_bridge)
		story_bridge.set("stage_kind", "sea")
	var packed := load(FISHING_OVERLAY) as PackedScene
	if packed:
		overlay = packed.instantiate() as CanvasLayer
		add_child(overlay)
		overlay.connect("catch_detailed", _on_catch_detailed)
		overlay.connect("catch_finished", _on_catch_finished)
		overlay.connect("rin_fainted", _on_rin_fainted)
		overlay.call("bind_hold", hold_ui)
	else:
		push_error("SeaScene3D: fishing overlay unavailable")
	cinematic = CastCinematic3D.new()
	cinematic.sea = self
	cinematic.camera = camera
	cinematic.boat_visual = boat_visual
	cinematic.hidden_figure = rin_figure
	add_child(cinematic)
	camera.position = boat.position + Vector3(0, 7.3, 10.0)
	camera.look_at(boat.position + Vector3(0, 0.7, -2.0))
	_build_navigation()
	DayClock.start_night()
	DailyTrend.ensure()
	Story.check_day()
	GameState.resume_at = "sea"
	SaveSystem.autosave("sea")
	Sfx.ambience("sea")
	_say("Tìm bọt khí trên mặt biển. Bến ở phía sau.", 4.0)
	if weather and weather.start_message != "":
		_say(weather.start_message, 4.0)
	_update_hud()

func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("090a14")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("819796")
	env.ambient_light_energy = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color("172038")
	env.fog_density = 0.018
	if weather:
		env.ambient_light_energy *= weather.night_brightness
		if weather.rain:
			env.fog_density = 0.028
	world_env.environment = env
	add_child(world_env)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-48, -28, 0)
	moon.light_color = Color("bacac7")
	moon.light_energy = 0.6
	add_child(moon)

func _build_world() -> void:
	var size := SeaLayout3D.size_world()
	_box(self, Vector3.ZERO, Vector3(size.x, 0.12, size.y), "172038")
	for z_rect: Array in [[SeaLayout3D.NEAR_RECT, "253a5e", 0.07], [SeaLayout3D.REEF_RECT, "202e37", 0.075]]:
		var r := SeaLayout3D.rect_world(z_rect[0])
		_box(self, Vector3(r.get_center().x, float(z_rect[2]), r.get_center().y), Vector3(r.size.x, 0.02, r.size.y), str(z_rect[1]))
	if Story.is_fog_open():
		var fog := SeaLayout3D.rect_world(SeaLayout3D.FOG_RECT)
		_box(self, Vector3(fog.get_center().x, 0.085, fog.get_center().y), Vector3(fog.size.x, 0.02, fog.size.y), "2d4b52")
	# Land strip behind the dock (the 2D shore).
	var shore_z: float = SeaLayout3D.to_world(Vector2(0, SeaLayout3D.SHORE_PX)).z
	_solid_box(Vector3(0, 0.2, (shore_z + size.y * 0.5) * 0.5 + 1.5), Vector3(size.x, 0.42, size.y * 0.5 - shore_z - 3.0), "394a50")
	for i in range(170):
		var x := float((i * 37) % 150) - 75.0
		var z := float((i * 53) % 100) - 50.0
		wave_marks.append(_box(self, Vector3(x, 0.11, z), Vector3(0.3 + 0.2 * (i % 4), 0.015, 0.07), "577277" if i % 3 else "3c5e8b"))
	# Pier just behind the dock point (built around the old 5 -> START.z offset).
	var off := Vector3(START.x, 0.0, START.z - 5.0)
	_solid_box(off + Vector3(0, 0.20, 11), Vector3(18, 0.42, 5), "394a50")
	for z in range(9, 16, 2):
		_solid_box(off + Vector3(0, 0.45, float(z)), Vector3(3.5, 0.35, 1.7), "7a4841")
		for x in [-1.45, 1.45]:
			_box(self, off + Vector3(x, 0.14, float(z)), Vector3(0.16, 0.42, 0.18), "402751")
	_box(self, off + Vector3(-6.8, 1.5, 10), Vector3(1.0, 2.6, 1.0), "e7d5b3")
	_box(self, off + Vector3(-6.8, 2.9, 10), Vector3(1.2, 0.26, 1.2), "a53030")
	_box(self, off + Vector3(-6.8, 3.18, 10), Vector3(0.48, 0.25, 0.48), "f2d98a")
	_label("BẾN XÓM ĐÈN", off + Vector3(0, 1.45, 13.6), 30, "e7d5b3")
	for rock in SeaLayout3D.rocks():
		var pos: Vector3 = rock["pos"]
		var radius: float = rock["radius"]
		_solid_box(pos + Vector3(0, 0.32, 0), Vector3(radius * 2.2, 0.62, radius * 1.6), "394a50")
		_box(self, pos + Vector3(-radius * 0.2, 0.73, 0), Vector3(radius * 0.9, 0.45, radius * 0.7), "577277")
		for i in range(5):
			var angle := float(i) * TAU / 5.0
			_box(self, pos + Vector3(cos(angle) * radius * 1.7, 0.11, sin(angle) * radius * 1.3), Vector3(0.52, 0.02, 0.08), "819796")
	_solid_box(RAFT_POS + Vector3(0, 0.32, 0), Vector3(5.0, 0.55, 3.0), "7a4841")
	for x in [-2.0, 0.0, 2.0]:
		_box(self, RAFT_POS + Vector3(x, 0.65, 0), Vector3(1.65, 0.15, 2.3), "ad7757")
	_box(self, RAFT_POS + Vector3(2.0, 1.5, -1), Vector3(0.15, 1.8, 0.15), "e7d5b3")
	_box(self, RAFT_POS + Vector3(2.0, 2.5, -1), Vector3(0.45, 0.2, 0.45), "f2d98a")
	# Shoals are only hinted by bubbles on the water (BubbleSpot3D).
	var bubble_mat := StandardMaterial3D.new()
	bubble_mat.albedo_color = Color("c9f1f0")
	bubble_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for shoal in shoals:
		var spot := BubbleSpot3D.new()
		add_child(spot)
		spot.setup(shoal, boat, bubble_mat)
		bubble_spots.append(spot)
	for i in range(6):
		var mark := _box(self, Vector3.ZERO, Vector3(0.22 + i * 0.13, 0.02, 0.10), "73bed3" if i % 2 else "a4dddb")
		mark.visible = false
		wake_marks.append(mark)

func _build_pois() -> void:
	# Reach points sit in open water. Buildings behind them carry the silhouette.
	_box(self, SHRINE_POS + Vector3(-1.4, 0.25, -0.6), Vector3(2.0, 0.50, 1.5), "819796")
	_box(self, SHRINE_POS + Vector3(-1.4, 0.75, -0.6), Vector3(1.1, 0.50, 0.9), "a53030")
	_box(self, SHRINE_POS + Vector3(-1.4, 1.12, -0.6), Vector3(1.4, 0.18, 1.15), "7a4841")
	_label("MIẾU CÁ ÔNG", SHRINE_POS + Vector3(-1.4, 1.7, -0.6), 21, "f2d98a")
	_box(self, LIGHTHOUSE_POS + Vector3(-1.8, 0.26, -0.6), Vector3(2.9, 0.52, 2.4), "394a50")
	_box(self, LIGHTHOUSE_POS + Vector3(-1.8, 1.55, -0.6), Vector3(0.75, 2.35, 0.75), "e7d5b3")
	_box(self, LIGHTHOUSE_POS + Vector3(-1.8, 2.45, -0.6), Vector3(0.83, 0.32, 0.83), "a53030")
	_box(self, LIGHTHOUSE_POS + Vector3(-1.8, 2.76, -0.6), Vector3(0.35, 0.27, 0.35), "f2d98a")
	_label("ĐÁ CANH ĐÊM", LIGHTHOUSE_POS + Vector3(-1.8, 3.2, -0.6), 20, "e7d5b3")
	_box(self, HUT_POS + Vector3(-1.4, 0.2, -0.5), Vector3(2.4, 0.40, 2.0), "577277")
	_box(self, HUT_POS + Vector3(-1.4, 0.95, -0.5), Vector3(1.4, 1.1, 1.1), "884b2b")
	_box(self, HUT_POS + Vector3(-1.4, 1.58, -0.5), Vector3(1.8, 0.18, 1.5), "be772b")
	_label("GÒ VỎ ỐC", HUT_POS + Vector3(-1.4, 2.0, -0.5), 20, "f2d98a")
	_label("BÈ TÔM HÙM ANH ÚT", RAFT_POS + Vector3(0, 1.9, 0), 20, "f2d98a")
	if Story.is_fog_open():
		for i in range(18):
			var a := TAU * float(i) / 18.0
			var ring := _box(self, WHIRLPOOL_POS + Vector3(cos(a) * 2.3, 0.16, sin(a) * 2.3),
				Vector3(0.8, 0.025, 0.11), "5ff2e0" if i % 3 == 0 else "73bed3")
			ring.rotation.y = -a
			whirlpool_marks.append(ring)
		_box(self, WHIRLPOOL_POS + Vector3(0, 0.22, 0), Vector3(0.5, 0.08, 0.5), "e6f6ff")
		_label("???", WHIRLPOOL_POS + Vector3(0, 1.2, 0), 28, "5ff2e0")

func _build_night_events() -> void:
	if GameState.day <= 1:
		return
	var positions: Array[Vector3] = []
	for px: Vector2 in [Vector2(700, 950), Vector2(1250, 870), Vector2(450, 880), Vector2(1100, 820)]:
		positions.append(SeaLayout3D.to_world(px))
	var kinds := NightEvents.pick_kinds(rng, rng.randi_range(1, 2), [1.0, 1.2, 1.0, 1.0])
	for i in range(kinds.size()):
		var kind: int = kinds[i]
		var pos: Vector3 = positions[kind]
		var node := Node3D.new()
		add_child(node)
		node.position = pos
		match kind:
			NightEvents.Kind.STRANDED:
				_box(node, Vector3(0, 0.32, 0), Vector3(1.0, 0.32, 1.6), "819796")
				_box(node, Vector3(0.4, 0.75, 0), Vector3(0.2, 0.20, 0.2), "cf573c")
			NightEvents.Kind.BOTTLE:
				_box(node, Vector3(0, 0.17, 0), Vector3(0.46, 0.14, 0.22), "a8ca58")
			NightEvents.Kind.JELLYFISH:
				for n in range(7):
					_box(node, Vector3(float(n % 3) * 0.65 - 0.65, 0.17, float(n / 3) * 0.58 - 0.5),
						Vector3(0.25, 0.14, 0.25), "5ff2e0")
			NightEvents.Kind.DOLPHINS:
				for n in range(3):
					_box(node, Vector3(float(n) * 0.7 - 0.7, 0.18, 0), Vector3(0.50, 0.13, 0.18), "a4dddb")
		night_events.append({"kind": kind, "pos": pos, "node": node, "done": false,
			"time": 0.0, "towing": false, "owner": "Chú Sáu"})

func _map_pos(pos: Vector3) -> Vector2:
	return SeaLayout3D.to_map(pos)

func _build_map_adapter() -> void:
	# PhoneMap expects 2D map coordinates and a Node2D boat. Small proxies
	# preserve its existing pin/legend UI while the sea world itself is 3D.
	var rocks: Array = []
	for rock in SeaLayout3D.rocks():
		rocks.append({"pos": _map_pos(rock["pos"]), "radius": float(rock["radius"]) * SeaLayout3D.PX_PER_UNIT, "color": Color("577277")})
	var places: Array = [
		{"pos": _map_pos(RAFT_POS), "label": "Bè tôm hùm anh Út"},
		{"pos": _map_pos(SHRINE_POS), "label": "Miếu Cá Ông"},
		{"pos": _map_pos(LIGHTHOUSE_POS), "label": "Hải đăng Đá Canh Đêm"},
		{"pos": _map_pos(HUT_POS), "label": "Gò Vỏ Ốc"},
		{"pos": _map_pos(START), "label": "Bến Xóm Đèn"},
	]
	PhoneMap._snap = {
		"size": SeaLayout3D.MAP_PX,
		"zones": [
			{"rect": SeaLayout3D.OPEN_RECT, "color": Color(0.1, 0.28, 0.48), "fog": false, "name": "Khơi xa"},
			{"rect": SeaLayout3D.REEF_RECT, "color": Color(0.16, 0.45, 0.6), "fog": false, "name": "Rạn đá"},
			{"rect": SeaLayout3D.NEAR_RECT, "color": Color(0.35, 0.68, 0.78), "fog": false, "name": "Gần bờ"},
		] + ([{"rect": SeaLayout3D.FOG_RECT, "color": Color(0.2, 0.32, 0.38), "fog": true, "name": "Sương"}] if Story.is_fog_open() else []),
		"land": [Rect2(0, SeaLayout3D.SHORE_PX, SeaLayout3D.MAP_PX.x, SeaLayout3D.MAP_PX.y - SeaLayout3D.SHORE_PX)],
		"rocks": rocks,
		"dock": _map_pos(START),
		"whirlpool": _map_pos(WHIRLPOOL_POS),
		"places": places,
		"range_y": lerpf(SeaLayout3D.SHORE_PX, SeaLayout3D.DEEP_PX, boat_data.max_depth) if boat_data.max_depth < 1.0 else -INF,
	}
	map_boat_proxy = Node2D.new()
	map_boat_proxy.add_to_group("boat")
	add_child(map_boat_proxy)
	map_boat_proxy.position = _map_pos(boat.position)

func _build_boat() -> void:
	if boat_data.id == "thuyen_thung":
		_cylinder(boat_visual, Vector3(0, 0.25, 0), 1.15, 0.45, "685448")
		_cylinder(boat_visual, Vector3(0, 0.5, 0), 1.2, 0.12, "a27d4c")
		_cylinder(boat_visual, Vector3(0, 0.57, 0), 0.97, 0.04, "8e795d")
		_box(boat_visual, Vector3(0, 0.66, 0.3), Vector3(1.7, 0.12, 0.28), "c09473")
	else:
		_box(boat_visual, Vector3(0, 0.23, 0), Vector3(1.55, 0.28, 3.05), "402751")
		_box(boat_visual, Vector3(0, 0.44, 0.15), Vector3(1.72, 0.27, 2.35), "7a4841")
		_box(boat_visual, Vector3(0, 0.62, -1.08), Vector3(1.22, 0.17, 0.85), "ad7757")
		_box(boat_visual, Vector3(0, 0.56, 0.15), Vector3(1.22, 0.10, 1.68), "c09473")
		for x in [-0.73, 0.73]:
			_box(boat_visual, Vector3(x, 0.72, 0.08), Vector3(0.11, 0.35, 2.45), "be772b")
		for z in [-0.63, 0.18, 0.95]:
			_box(boat_visual, Vector3(0, 0.66, z), Vector3(1.31, 0.06, 0.13), "884b2b")
	rin_figure = [_box(boat_visual, Vector3(0, 1.12, 0.30), Vector3(0.36, 0.77, 0.30), "e7d5b3"),
		_box(boat_visual, Vector3(0, 1.63, 0.30), Vector3(0.34, 0.34, 0.34), "ad7757"),
		_box(boat_visual, Vector3(0, 1.83, 0.30), Vector3(0.65, 0.10, 0.65), "e8c170")]
	_box(boat_visual, Vector3(0.58, 1.02, -0.85), Vector3(0.08, 0.82, 0.08), "e7d5b3")
	_box(boat_visual, Vector3(0.58, 1.48, -0.85), Vector3(0.33, 0.22, 0.33), "f2d98a")
	boat_lamp = SpotLight3D.new()
	boat_visual.add_child(boat_lamp)
	boat_lamp.position = Vector3(0.58, 1.45, -0.85)
	boat_lamp.rotation_degrees.x = -70
	boat_lamp.light_color = Color("f2d98a")
	boat_lamp.light_energy = 2.5
	boat_lamp.spot_range = 14.0
	boat_lamp.spot_angle = 36.0

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	header = Label.new()
	header.position = Vector2(14, 10)
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", Color("e7d5b3"))
	layer.add_child(header)
	help = Label.new()
	help.position = Vector2(14, 326)
	help.text = "W/S ga · A/D lái · E tương tác · Q lưới · Tab khoang · J điện thoại · M bản đồ\nBến: R về nhà · F sửa thuyền · Esc tạm dừng"
	help.add_theme_font_size_override("font_size", 9)
	help.add_theme_color_override("font_color", Color("a4dddb"))
	layer.add_child(help)
	message = Label.new()
	message.position = Vector2(14, 58)
	message.add_theme_color_override("font_color", Color("f2d98a"))
	layer.add_child(message)

func _build_shared_ui() -> void:
	# Reuse the existing pause, inventory and phone scenes with their saved data.
	new_catch_card = NewCatchCard.new()
	add_child(new_catch_card)
	var tracker := QuestTracker.new()
	tracker.catalog = fish_catalog
	tracker.origin = Vector2(6, 82)
	add_child(tracker)
	var pause := load("res://scenes/ui/pause_menu.tscn") as PackedScene
	if pause:
		add_child(pause.instantiate())
	var hold_scene := load("res://scenes/ui/hold_ui.tscn") as PackedScene
	if hold_scene:
		hold_ui = hold_scene.instantiate() as HoldUI
		add_child(hold_ui)
		hold_ui.setup(hold)
	poi_dialog = PoiDialog.new()
	add_child(poi_dialog)
	var phone_scene := load("res://scenes/ui/phone_app.tscn") as PackedScene
	if phone_scene:
		phone_app = phone_scene.instantiate() as PhoneApp
		phone_app.repair_allowed = _at_dock
		phone_app.repair_action = func() -> int: return BoatCondition.repair(boat_data)
		add_child(phone_app)

func _physics_process(delta: float) -> void:
	if ending or fishing or poi_busy or (hold_ui and hold_ui.visible) or (phone_app and phone_app.visible):
		return
	elapsed += delta
	impact_cooldown = maxf(impact_cooldown - delta, 0.0)
	var forward := Vector3.FORWARD.rotated(Vector3.UP, boat.rotation.y)
	var throttle := Input.get_axis("throttle_back", "throttle_forward")
	var steer := Input.get_axis("turn_left", "turn_right")
	if not _application_focused or _wait_controls_release:
		if _application_focused and not _movement_controls_held():
			_wait_controls_release = false
		throttle = 0.0
		steer = 0.0
	var acceleration := boat_data.acceleration / 10.0
	boat.velocity += forward * throttle * acceleration * delta
	if not _at_dock():
		boat.velocity += wind * delta
	boat.velocity *= exp(-1.15 * delta)
	boat.velocity = boat.velocity.limit_length(boat_data.max_speed / 10.0 * lerpf(0.6, 1.0, clampf(GameState.boat_hp / 50.0, 0.0, 1.0)) * (0.65 if _is_towing() else 1.0))
	var forward_speed := boat.velocity.dot(forward)
	var turn_target := steer * deg_to_rad(boat_data.turn_speed) * (0.35 + minf(absf(forward_speed) / 8.0, 0.65))
	yaw_velocity = move_toward(yaw_velocity, turn_target, delta * (3.0 - boat_data.spin_drift))
	boat.rotation.y += yaw_velocity * delta
	boat.velocity.y = 0.0
	var before := boat.position
	var impact_speed := boat.velocity.length()
	boat.move_and_slide()
	boat.position.y = 0.0
	if boat.get_slide_collision_count() > 0:
		if before.distance_to(boat.position) < 0.3 and impact_speed > 2.0 and impact_cooldown <= 0.0:
			BoatCondition.damage(minf(14.0, impact_speed * 1.6) * blessed_damage_scale)
			impact_cooldown = 0.85
			_say("Mạn thuyền va vào vật cản!", 1.8)
		boat.velocity *= 0.45
		if GameState.boat_hp <= 0.0:
			_say("Thuyền hỏng rồi. Có người kéo Rin về bến.", 3.0)
			_end_trip(true)
			return
	# Boat range is inherited from the selected upgrade.
	var min_z := SeaLayout3D.reach_z(boat_data.max_depth)
	if boat.position.z < min_z:
		boat.position.z = min_z
		boat.velocity.z = maxf(boat.velocity.z, 0.0)
		_say("Sóng ngoài khơi đẩy thuyền trở lại.", 1.5)
	var half := SeaLayout3D.size_world() * 0.5 - Vector2.ONE * 2.0
	boat.position.x = clampf(boat.position.x, -half.x, half.x)
	boat.position.z = clampf(boat.position.z, -half.y, SeaLayout3D.to_world(Vector2(0, SeaLayout3D.SHORE_PX)).z + 1.0)
	map_boat_proxy.position = _map_pos(boat.position)
	map_boat_proxy.rotation = -PI / 2.0 - boat.rotation.y
	boat_visual.position.y = sin(elapsed * 2.5) * 0.06
	boat_visual.rotation.z = sin(elapsed * 1.8) * 0.025 - yaw_velocity * 0.025
	boat_visual.rotation.x = sin(elapsed * 2.1) * 0.018 + forward_speed * 0.004
	for i in range(wave_marks.size()):
		wave_marks[i].position.y = 0.11 + sin(elapsed * 2.1 + float(i) * 0.7) * 0.012
	var bubble_range := _bubble_range()
	for spot in bubble_spots:
		spot.view_range = bubble_range
	for i in range(whirlpool_marks.size()):
		var a := TAU * float(i) / float(whirlpool_marks.size()) + elapsed * 0.65
		whirlpool_marks[i].position = WHIRLPOOL_POS + Vector3(cos(a) * 2.3, 0.16, sin(a) * 2.3)
		whirlpool_marks[i].rotation.y = -a
	for i in range(nets.size()):
		var net_node: Node3D = nets[i]["node"]
		net_node.position.y = sin(elapsed * 2.0 + float(i)) * 0.06
	_update_night_events(delta)
	var behind := Vector3.BACK.rotated(Vector3.UP, boat.rotation.y)
	for i in range(wake_marks.size()):
		wake_marks[i].visible = boat.velocity.length() > 0.8
		wake_marks[i].position = boat.position + behind * (1.65 + float(i) * 0.6) + Vector3(0, 0.13, 0)
		wake_marks[i].rotation.y = boat.rotation.y
	var camera_target := boat.position + Vector3(0, 7.3, 10.0).rotated(Vector3.UP, boat.rotation.y)
	camera.position = camera.position.lerp(camera_target, minf(delta * 3.2, 1.0))
	camera.look_at(boat.position + forward * 2.0 + Vector3.UP * 0.6)
	var oil_scale := weather.oil_burn_scale if weather else 1.0
	if not _at_dock():
		_spend_oil(delta * OIL_BURN_PER_SECOND * oil_scale)
	if GameState.boat_hp <= 0.0:
		_end_trip(true)
		return
	if Story.is_fog_open() and boat.position.distance_to(WHIRLPOOL_POS) < 2.0:
		_enter_whirlpool()
		return
	if oil <= 0.0:
		_say("Đèn hết dầu. Rin phải gọi cứu hộ.", 3.0)
		_end_trip(true)
		return
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	var debug_key := event as InputEventKey
	if OS.is_debug_build() and debug_key and debug_key.pressed and not debug_key.echo:
		if debug_key.physical_keycode == KEY_F4:
			if WaveMark.has_power():
				GameState.story_flags.erase(WaveMark.FLAG)
			else:
				GameState.set_flag(WaveMark.FLAG)
			if overlay:
				var power := overlay.get("wave_power") as WavePower
				if power:
					power.charges = WaveMark.max_charges()
			_say("[debug] Nhịp Sóng: %s" % ("có (C)" if WaveMark.has_power() else "tắt"), 2.0)
			get_viewport().set_input_as_handled()
			return
		if debug_key.physical_keycode == KEY_F3 and story_bridge and not story_bridge.playing and not trip_end_cutscenes.is_empty():
			var cutscene: Cutscene = trip_end_cutscenes[debug_cutscene_index % trip_end_cutscenes.size()]
			debug_cutscene_index += 1
			story_bridge.play(cutscene)
			get_viewport().set_input_as_handled()
			return
	if ending or fishing or poi_busy or (hold_ui and hold_ui.visible) or get_tree().paused:
		return
	if event.is_action_pressed("open_hold") and hold_ui:
		hold_ui.open_browse()
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_E:
		if _at_dock():
			_unload()
		elif _try_visit_poi():
			pass
		elif not _try_haul_net():
			_try_fish()
	elif key.physical_keycode == KEY_Q:
		_drop_net()
	elif key.physical_keycode == KEY_R and _at_dock():
		_end_trip(false)
	elif key.physical_keycode == KEY_F and _at_dock():
		var paid := BoatCondition.repair(boat_data)
		_say("Đã sửa thuyền, tốn %dk." % paid if paid > 0 else "Chưa cần sửa hoặc không đủ tiền.", 2.5)
	elif key.physical_keycode == KEY_H and hold_ui:
		hold_ui.open_browse()
	else:
		return
	get_viewport().set_input_as_handled()

func _at_dock() -> bool:
	return boat.position.distance_to(START) < 4.0 and boat.velocity.length() < 2.0

func _nearest_poi() -> String:
	if boat.velocity.length() > 2.0 or poi_busy:
		return ""
	for entry in [
		["shrine", SHRINE_POS, 4.0], ["lighthouse", LIGHTHOUSE_POS, 4.0],
		["hut", HUT_POS, 4.0], ["raft", RAFT_POS, 5.3],
	]:
		if boat.position.distance_to(entry[1]) < float(entry[2]):
			return entry[0]
	for i in range(night_events.size()):
		var event := night_events[i]
		if not event["done"] and int(event["kind"]) in [NightEvents.Kind.STRANDED, NightEvents.Kind.BOTTLE] \
				and boat.position.distance_to(event["pos"]) < 3.4:
			return "event_%d" % i
	return ""

func _is_towing() -> bool:
	for event in night_events:
		if event["towing"]:
			return true
	return false

func _update_night_events(delta: float) -> void:
	for event in night_events:
		var kind: int = event["kind"]
		if not is_instance_valid(event["node"]):
			continue
		var node: Node3D = event["node"]
		if event["towing"]:
			var behind := boat.position + Vector3.BACK.rotated(Vector3.UP, boat.rotation.y) * 4.0
			node.position = node.position.lerp(behind, minf(delta * 2.0, 1.0))
		elif kind == NightEvents.Kind.JELLYFISH:
			node.position += Vector3(0.12, 0, -0.06) * delta
			if boat.position.distance_to(node.position) < 2.5:
				event["time"] = float(event["time"]) - delta
				if float(event["time"]) <= 0.0:
					event["time"] = 1.5
					BoatCondition.damage(3.0 * blessed_damage_scale)
					_say("Sứa quấn chân vịt rồi! Phải thoát khỏi đàn sứa.", 1.5)
		elif kind == NightEvents.Kind.DOLPHINS:
			if not event["done"] and boat.position.distance_to(node.position) < 8.0:
				event["done"] = true
				_say("Cá heo kìa! Đi theo tụi nó thử coi.", 2.5)
			if event["done"]:
				node.position = node.position.move_toward(_dolphin_target(), delta * 3.0)

func _try_visit_poi() -> bool:
	var id := _nearest_poi()
	if id.is_empty():
		return false
	poi_busy = true
	boat.velocity = Vector3.ZERO
	_visit_poi(id)
	return true

func _visit_poi(id: String) -> void:
	if id.begins_with("event_"):
		await _visit_night_event(int(id.substr(6)))
		poi_busy = false
		_update_hud()
		return
	match id:
		"shrine":
			var shrine := WhaleShrine.new()
			var line := shrine.keeper_lines[clampi(Story.stage(), 0, shrine.keeper_lines.size() - 1)]
			shrine.free()
			if shrine_blessed:
				await poi_dialog.ask("Miếu Cá Ông", line + "\n\nNhang còn cháy. Đêm nay Ông phù hộ.", PackedStringArray(["Đi tiếp"]))
			else:
				var choice := await poi_dialog.ask("Miếu Cá Ông", line, PackedStringArray([
					"Thắp nhang (10k): đêm nay thuyền đỡ hư hại khi va đá", "Đi tiếp"]))
				if choice == 0:
					if GameState.spend_money(10):
						shrine_blessed = true
						blessed_damage_scale = 0.5
						_say("Thắp nhang xong. Đêm nay va đá chắc cũng đỡ.", 2.0)
					else:
						_say("Không đủ tiền mua nhang...", 2.0)
		"lighthouse":
			var tower := Lighthouse.new()
			var read := Lighthouse.pages_read()
			var available := mini(tower.pages_by_stage[clampi(Story.stage(), 0, tower.pages_by_stage.size() - 1)], tower.pages.size())
			var body := "Trang cuối dừng giữa câu. Người gác đèn chưa bao giờ quay về."
			if read < available:
				body = "Nhật ký người gác đèn, trang %d:\n\n%s" % [read + 1, tower.pages[read]]
				GameState.set_flag(Lighthouse.PAGE_FLAG, read + 1)
			elif available < tower.pages.size():
				body = "Đã đọc hết các trang còn đọc được. Mấy trang sau bị nước biển làm nhòe, để hôm khác thử lại."
			tower.free()
			await poi_dialog.ask("Hải đăng Đá Canh Đêm", body, PackedStringArray(["Đi tiếp"]))
		"hut":
			var patch_label := "Nhờ vá thuyền (+25 bền, 40k)" if BoatCondition.is_damaged() else "Nhờ vá thuyền (thuyền còn lành)"
			var choice := await poi_dialog.ask("Chòi ông Tám — Gò Vỏ Ốc", "Ông Tám ngồi vá lưới dưới ngọn đèn dầu.\n\"Ra trễ vậy con?\"",
				PackedStringArray([patch_label, "Hỏi chuyện", "Đi tiếp"]), "ong_tam")
			if choice == 0:
				if not BoatCondition.is_damaged():
					_say("Thuyền còn lành mà, khỏi vá.", 2.0)
				elif GameState.spend_money(40):
					GameState.boat_hp = minf(100.0, GameState.boat_hp + 25.0)
					_say("Ông Tám: Xong rồi đó con. (+25 bền, -40k)", 2.0)
				else:
					_say("Không đủ tiền nhờ ông Tám vá...", 2.0)
			elif choice == 1:
				var hut := OldManHut.new()
				var rumor := hut.pick_rumor(Story.stage(), rng)
				hut.free()
				await poi_dialog.ask("Chòi ông Tám — Gò Vỏ Ốc", "Ông Tám: " + rumor, PackedStringArray(["Đi tiếp"]), "ong_tam")
		"raft":
			var items := hold.items.duplicate()
			if items.is_empty():
				await poi_dialog.ask("Bè tôm hùm anh Út", "Anh Út: \"Khoang trống trơn mà ghé chi? Đi câu đi em.\"", PackedStringArray(["Đi tiếp"]))
			else:
				var value := LobsterRaft.sale_value(items, 0.5)
				var choice := await poi_dialog.ask("Bè tôm hùm anh Út", "Anh Út: \"Khoang đầy hả? Để anh mua đỡ, giá chợ đêm thôi nghen.\"\n(%d con trong khoang)" % items.size(),
					PackedStringArray(["Chọn con để bán", "Bán hết khoang: %dk" % value, "Thôi, để đem về quán"]))
				if choice == 0 and hold_ui:
					hold_ui.open_sell("bè tôm hùm anh Út (giá chợ đêm)", func(item: InventoryItem) -> int:
						return LobsterRaft.sale_value([item], 0.5))
					await hold_ui.closed
				elif choice == 1:
					for item in items:
						hold.remove(item)
					GameState.add_money(value)
					_say("Bán cho anh Út %d con, được %dk." % [items.size(), value], 2.0)
	poi_busy = false
	_update_hud()

func _visit_night_event(index: int) -> void:
	if index < 0 or index >= night_events.size():
		return
	var event := night_events[index]
	match int(event["kind"]):
		NightEvents.Kind.STRANDED:
			var owner: String = event["owner"]
			var choice := await poi_dialog.ask("Ghe %s chết máy" % owner,
				"%s: \"Máy chết rồi con ơi. Kéo giùm chú về bến, chú gửi 80k.\"" % owner,
				PackedStringArray(["Kéo về bến (thuyền chạy chậm lại)", "Thôi, con đang bận"]))
			if choice == 0:
				event["towing"] = true
				event["done"] = true
				_say("Kéo ghe %s về bến là có 80k." % owner, 2.5)
		NightEvents.Kind.BOTTLE:
			var bottle := MessageBottle.new()
			var read := MessageBottle.pages_read()
			if read < bottle.pages.size():
				GameState.set_flag(MessageBottle.READ_FLAG, read + 1)
				await poi_dialog.ask("Chai thư", "Mẩu giấy ướt nhòe, nét chữ run run (%d/%d):\n\n%s" % [read + 1, bottle.pages.size(), bottle.pages[read]],
					PackedStringArray(["Cất vào túi"]))
			else:
				GameState.add_money(5)
				await poi_dialog.ask("Chai thư", "Chai rỗng. Đem bán ve chai được 5k.", PackedStringArray(["Ừ"]))
			bottle.free()
			event["done"] = true
			(event["node"] as Node3D).queue_free()

func _enter_whirlpool() -> void:
	if ending:
		return
	ending = true
	DayClock.stop()
	GameState.set_flag(Story.ENDING_SEEN_FLAG)
	Sfx.play("whoosh")
	boat.velocity = Vector3.ZERO
	var tween := create_tween().set_parallel()
	tween.tween_property(boat, "position", WHIRLPOOL_POS, 2.0)
	tween.tween_property(boat, "rotation:y", boat.rotation.y + TAU * 3.0, 2.0)
	tween.tween_property(boat_visual, "scale", Vector3.ONE * 0.3, 2.0)
	await tween.finished
	SceneRouter.go_to(ENDING_SCENE, Color.WHITE)

## Lamp reach for bubbles: shrinks as the oil runs low.
func _bubble_range() -> float:
	var fraction := oil / maxf(oil_capacity, 1.0)
	var base: float = boat_lamp.spot_range if is_instance_valid(boat_lamp) else 14.0
	return base * 0.6 * lerpf(0.55, 1.0, clampf(fraction * 2.0, 0.0, 1.0))


func _try_fish() -> void:
	if overlay == null:
		_say("Màn câu cá chưa được nạp.", 2.5)
		return
	for i in range(shoals.size()):
		var shoal := shoals[i]
		if shoal.fish_left > 0 and boat.position.distance_to(shoal.pos) < 4.8 and boat.velocity.length() < 2.4:
			var rarity := weather.rarity_bonus if weather else 0.0
			var species_bonus := weather.species_bonus if weather else {}
			var fish := shoal.roll_fish(fish_catalog, rng, rarity, species_bonus)
			if fish == null:
				_say("Chỗ này không còn cá.", 2.0)
				return
			var used := shoal.max_fish - shoal.fish_left
			var school := shoal.school_count()
			fishing = true
			boat.velocity = Vector3.ZERO
			yaw_velocity = 0.0
			_spend_oil(2.0)
			var size := CatchRoll.snap_size(CatchRoll.roll_size(rng, shoal.depth, shoal.big_shadow), fish.typical_kg)
			size = CatchRoll.snap_size(minf(size + used * 0.08, CatchRoll.MAX_SIZE), fish.typical_kg)
			var difficulty := float(GameState.get_upgrade_value(ROD_UPGRADE)) * CatchRoll.size_zone_scale(size) * WaveMark.fight_scale(fish, CatchRoll.is_big(size)) * maxf(1.0 - used * 0.08, 0.75)
			# One fish leaves the shoal per cast, caught or not.
			shoal.fish_left -= 1
			if cast_cinematic_enabled and cinematic:
				_cast_then_fish(shoal.pos, fish, difficulty, size, school)
			else:
				overlay.call("start_catch", fish, difficulty, size, 1, school)
			return
	_say("Tìm bọt khí trên mặt biển, đến gần rồi giảm ga để câu.", 2.5)


func _cast_then_fish(target: Vector3, fish: FishData, difficulty: float, size: float, school: int) -> void:
	_cast_played = true
	await cinematic.play(target)
	if ending or not is_inside_tree():
		return
	overlay.call("start_catch", fish, difficulty, size, 1, school)
	cinematic.reveal()

func _zone_at(pos: Vector3) -> FishData.Zone:
	return SeaLayout3D.zone_at(pos, Story.is_fog_open())

func _drop_net() -> void:
	if nets.size() >= 2:
		_say("Đã thả hết 2 lưới. Hãy kéo lưới cũ lên.", 2.5)
		return
	if boat.velocity.length() > 1.5:
		_say("Giảm ga trước khi thả lưới.", 2.0)
		return
	var zone := _zone_at(boat.position)
	if fish_catalog.get_fish_for_zone(zone, FishData.CatchMethod.NET).is_empty():
		_say("Vùng này không hợp để thả lưới.", 2.0)
		return
	var pos := boat.position + Vector3.BACK.rotated(Vector3.UP, boat.rotation.y) * 2.8
	for net in nets:
		if pos.distance_to(net["pos"]) < 7.0:
			_say("Hai lưới quá gần nhau.", 2.0)
			return
	var buoy := Node3D.new()
	add_child(buoy)
	buoy.position = pos
	_cylinder(buoy, Vector3(0, 0.25, 0), 0.20, 0.42, "e7d5b3")
	_box(buoy, Vector3(0, 0.52, 0), Vector3(0.35, 0.17, 0.35), "de9e41")
	nets.append({"pos": pos, "zone": zone, "time": elapsed, "node": buoy})
	var map_net := Node2D.new()
	map_net.add_to_group("net_buoys")
	add_child(map_net)
	map_net.position = _map_pos(pos)
	nets[nets.size() - 1]["map_node"] = map_net
	_spend_oil(1.0)
	_say("Đã thả lưới. Quay lại sau một lúc để kéo lên.", 2.5)

func _try_haul_net() -> bool:
	for i in range(nets.size()):
		var net := nets[i]
		if boat.position.distance_to(net["pos"]) >= 3.4:
			continue
		if boat.velocity.length() > 1.5:
			_say("Giảm ga trước khi kéo lưới.", 2.0)
			return true
		var soak := elapsed - float(net["time"])
		var count := clampi(roundi(8.0 * soak / 90.0), 0, 8)
		var zone: FishData.Zone = net["zone"]
		var haul: Array[Array] = []
		var depth: float = [0.1, 0.5, 0.8, 1.0][clampi(int(zone), 0, 3)]
		for animal in range(count):
			var species := fish_catalog.pick_random(zone, rng, FishData.CatchMethod.NET)
			if species:
				var size := CatchRoll.snap_size(CatchRoll.roll_size(rng, depth, false), species.typical_kg)
				haul.append([species, size])
		(net["node"] as Node3D).queue_free()
		(net["map_node"] as Node2D).queue_free()
		nets.remove_at(i)
		if haul.is_empty():
			_say("Lưới còn trống. Đợi lâu hơn trước khi kéo.", 2.5)
			return true
		if overlay == null:
			_say("Không nạp được màn kéo lưới.", 2.5)
			return true
		net_haul = haul
		net_haul_count = haul.size()
		var species_counts: Dictionary = {}
		var main_species: FishData = haul[0][0]
		for entry: Array in haul:
			var species: FishData = entry[0]
			species_counts[species] = int(species_counts.get(species, 0)) + 1
			if int(species_counts[species]) > int(species_counts.get(main_species, 0)):
				main_species = species
		fishing = true
		boat.velocity = Vector3.ZERO
		yaw_velocity = 0.0
		_spend_oil(2.0)
		var bonus := 1.0 + GameState.get_upgrade_level("net") * 0.15
		overlay.call("start_catch", main_species, bonus, 1.0, net_haul_count)
		return true
	return false

func _on_catch_detailed(fish: FishData, caught: bool, quality: float, count: int, size: float) -> void:
	if not net_haul.is_empty():
		var haul := net_haul.duplicate()
		net_haul.clear()
		net_haul_count = 0
		if not caught:
			_say("Lưới tuột mất mẻ hải sản.", 2.0)
			return
		var species_counts: Dictionary = {}
		for entry: Array in haul:
			var species: FishData = entry[0]
			_store_catch(species, quality, 1, float(entry[1]))
			species_counts[species.display_name] = int(species_counts.get(species.display_name, 0)) + 1
		var parts := PackedStringArray()
		for name: String in species_counts:
			parts.append("%d %s" % [species_counts[name], name])
		_say("Kéo lưới được %s!" % ", ".join(parts), 3.0)
		_update_hud()
		return
	if not caught:
		_say("Cá tuột mất rồi.", 2.0)
		return
	_store_catch(fish, quality, count, size)
	_update_hud()

func _store_catch(fish: FishData, quality: float, count: int, size: float) -> void:
	if fish == null or count <= 0:
		return
	var is_new := int(GameState.caught_species.get(fish.id, 0)) == 0
	var previous_best := GameState.best_size(fish)
	# A landed catch belongs in the Dex even when the hold needs sorting.
	GameState.record_catch(fish, count, size)
	Story.on_fish_caught(fish)
	var rewards := CollectionRewards.claim(fish, size, is_new, previous_best)
	var overflow: Array[InventoryItem] = []
	for i in range(count):
		var item := InventoryItem.new(fish, quality, size)
		item.is_new = is_new
		if not hold.auto_place(item):
			overflow.append(item)
	_say("Bắt được %s %s. Khoang đầy %d%%.%s" % [fish.display_name, fish.weight_text(size), roundi(hold.fill_fraction() * 100.0), "\n" + "\n".join(rewards) if not rewards.is_empty() else ""], 4.0)
	if not overflow.is_empty() and hold_ui:
		hold_ui.open_overflow(overflow)
	if is_new and new_catch_card:
		# Batch hauls finish opening overflow before the reveal claims pause.
		new_catch_card.show_fish.call_deferred(fish, size)

func _on_catch_finished(_success: bool, _fish_data: FishData) -> void:
	if _cast_played and cinematic:
		_cast_played = false
		await cinematic.play_return()
		if not is_inside_tree():
			return
	fishing = false
	_wait_controls_release = true
	boat.velocity = Vector3.ZERO
	yaw_velocity = 0.0
	_update_hud()

func _unload() -> void:
	if hold.items.is_empty():
		_say("Khoang trống. Nhấn R để về nhà.", 2.0)
		return
	var items := hold.items.duplicate()
	for item in items:
		hold.remove(item)
	GameState.unload_catch(items)
	_say("Đã dỡ %d con cá. Có thể ra biển tiếp hoặc nhấn R về nhà." % items.size(), 3.0)
	_update_hud()

func _end_trip(towed: bool, rescue_fee: int = -1) -> void:
	if ending:
		return
	ending = true
	for event in night_events:
		if event["towing"]:
			if towed:
				GameState.trip_notes.append("%s được cứu hộ kéo về luôn, không gửi tiền." % event["owner"])
			else:
				GameState.add_money(80)
				GameState.trip_notes.append("Kéo ghe %s về bến: +80k" % event["owner"])
	if towed:
		var fee := rescue_fee if rescue_fee >= 0 else (150 if BoatCondition.is_broken() else 80)
		GameState.spend_money(mini(fee, GameState.money))
		BoatCondition.tow_patch(20.0)
		GameState.trip_notes.append("Rin được kéo thuyền về bến trong đêm.")
	DayClock.stop()
	GameState.finish_sea_day(DayClock.current_minutes, towed, hold.items.duplicate())
	if story_bridge and not trip_end_cutscenes.is_empty():
		await story_bridge.call("play_eligible", trip_end_cutscenes)
	SceneRouter.go_to(REST_SCENE)

func _say(text: String, seconds: float) -> void:
	status = text
	status_until = Time.get_ticks_msec() / 1000.0 + seconds
	message.text = status

func _update_hud() -> void:
	var at_dock := _at_dock()
	var prompt := "E dỡ cá • R về nhà" if at_dock else "E câu tại phao sáng"
	var poi := _nearest_poi()
	if poi != "":
		var names := {"shrine": "Miếu Cá Ông", "lighthouse": "Hải đăng Đá Canh Đêm",
			"hut": "Chòi ông Tám", "raft": "Bè tôm hùm anh Út"}
		if poi.begins_with("event_"):
			var event := night_events[int(poi.substr(6))]
			prompt = "E vớt chai thư" if int(event["kind"]) == NightEvents.Kind.BOTTLE else "E hỏi ghe chết máy"
		else:
			prompt = "E ghé " + str(names.get(poi, poi))
	header.text = "%s · %s · %dk · Dầu %d%% · Thân thuyền %d%%\nCá %d · Lưới %d/2 · %s" % [boat_data.display_name, DayClock.get_time_text(), GameState.money, roundi(oil / oil_capacity * 100.0), roundi(GameState.boat_hp), hold.items.size(), nets.size(), prompt]
	if Time.get_ticks_msec() / 1000.0 > status_until:
		message.text = ""


func _movement_controls_held() -> bool:
	return Input.is_action_pressed("throttle_forward") or Input.is_action_pressed("throttle_back") or Input.is_action_pressed("turn_left") or Input.is_action_pressed("turn_right")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_application_focused = false
		_wait_controls_release = true
		if is_instance_valid(boat):
			boat.velocity = Vector3.ZERO
			yaw_velocity = 0.0
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_application_focused = true


func _spend_oil(units: float) -> void:
	oil = maxf(oil - units, 0.0)
	var fraction := oil / maxf(oil_capacity, 1.0)
	DayClock.set_progress(1.0 - fraction, DayClock.night_start_hour, DayClock.dawn_hour)
	if not oil_critical_sent and fraction <= 0.1 and oil > 0.0:
		oil_critical_sent = true
		_say("NEO: Dầu còn 10%. Anh Rin nên về bến ngay.", 3.0)
	elif not oil_low_sent and fraction <= 0.25 and fraction > 0.1:
		oil_low_sent = true
		_say("NEO: Dầu đèn còn 25%. Anh Rin quay về bến nhé.", 3.0)
	if is_instance_valid(boat_lamp):
		boat_lamp.light_energy = 2.5 * lerpf(0.3, 1.0, clampf(fraction * 2.0, 0.0, 1.0))


func _on_rin_fainted() -> void:
	GameState.trip_notes.append("Rin bất tỉnh khi vật lộn với cá ngoài khơi.")
	_say("Choáng quá... may có người kéo thuyền về bến.", 3.0)
	if hold_ui and hold_ui.visible:
		await hold_ui.closed
	_end_trip(true, 0)


func _dolphin_target() -> Vector3:
	var i := _nearest_school_index()
	return shoals[i].pos if i >= 0 else START


func _build_navigation() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	navigation = preload("res://scenes/sea3d/sea_navigation_3d.gd").new()
	navigation.set("world", self)
	navigation.set("camera", camera)
	layer.add_child(navigation)
	var guide := Guide.new()
	guide.blocked = func() -> bool: return fishing or ending or poi_busy or (hold_ui and hold_ui.visible) or (phone_app and phone_app.visible)
	add_child(guide)
	# No pointer to shoals: the hint is the bubbles themselves.
	guide.add("sea3d_bubbles", "Tìm bọt khí trên mặt biển", func() -> bool: return not fishing and _casts_used_total() == 0,
		func() -> Vector2: return navigation.call("screen_point", boat.position + Vector3(0, 3.0, 0)),
		func() -> bool: return fishing or _casts_used_total() > 0)
	guide.add("sea3d_dock", "Về bến dỡ cá", func() -> bool: return not fishing and hold.fill_fraction() >= 0.6,
		func() -> Vector2: return navigation.call("screen_point", START),
		func() -> bool: return hold.items.is_empty())


func _casts_used_total() -> int:
	var used := 0
	for shoal in shoals:
		used += shoal.max_fish - shoal.fish_left
	return used


func _nearest_school_index() -> int:
	var nearest := -1
	var distance := INF
	var min_z := SeaLayout3D.reach_z(boat_data.max_depth)
	for i in range(shoals.size()):
		var spot: Vector3 = shoals[i].pos
		if spot.z < min_z or shoals[i].fish_left <= 0:
			continue
		var d := boat.position.distance_to(spot)
		if d < distance:
			distance = d
			nearest = i
	return nearest


func navigation_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = [{"pos": START, "label": "Bến", "color": "f2d98a"}]
	for net in nets:
		var full: int = roundi(clampf((elapsed - float(net["time"])) / 90.0, 0.0, 1.0) * 100.0)
		targets.append({"pos": net["pos"], "label": "Lưới %d%%" % full, "color": "de9e41"})
	for i in range(GameState.map_pins.size()):
		var pin: Vector2 = GameState.map_pins[i]
		targets.append({"pos": SeaLayout3D.to_world(pin), "label": "Ghim %d" % (i + 1), "color": "d99ccc"})
	for entry: Array in [[SHRINE_POS, "Miếu"], [HUT_POS, "Ông Tám"], [LIGHTHOUSE_POS, "Hải đăng"], [RAFT_POS, "Bè tôm"]]:
		var pos: Vector3 = entry[0]
		if boat.position.distance_to(pos) < 20.0:
			targets.append({"pos": pos, "label": entry[1], "color": "c6b89a"})
	if Story.is_fog_open():
		targets.append({"pos": WHIRLPOOL_POS, "label": "???", "color": "5ff2e0"})
	return targets
