class_name RestaurantScene3D
extends Node3D
## Xóm Đèn restaurant in 3D. Uses the saved inventory, real dishes and shift ledger.

const SEA_SCENE := "res://scenes/sea3d/sea_scene_3d.tscn"
const SHIFT_SECONDS := 180.0
const TUNINGS := [
	preload("res://data/restaurant/service_day1.tres"),
	preload("res://data/restaurant/service_day2.tres"),
	preload("res://data/restaurant/service_day3.tres"),
	preload("res://data/restaurant/service_day5.tres"),
]
const CAT_DIALOGUES := [
	preload("res://data/dialogues/cat_first.tres"),
	preload("res://data/dialogues/cat_warm.tres"),
	preload("res://data/dialogues/cat_omen.tres"),
	preload("res://data/dialogues/cat_mark.tres"),
]
const TABLES := [
	# First 4 = 2x2 nearest the stove (as in the 2D map); upgrades add rows above and below.
	Vector3(-5.5, 0, -2.0), Vector3(-9.5, 0, -2.0),
	Vector3(-5.5, 0, 1.4), Vector3(-9.5, 0, 1.4),
	Vector3(-5.5, 0, -5.4), Vector3(-9.5, 0, -5.4),
	Vector3(-5.5, 0, 4.8), Vector3(-9.5, 0, 4.8),
]

@export var menu: DishCatalog
@export var kitchen_upgrade: UpgradeData
@export var fridge_upgrade: UpgradeData
@export var seats_upgrade: UpgradeData
@export var decor_upgrade: UpgradeData
@export var arrival_cutscenes: Array[Cutscene] = []
@export var after_shift_cutscenes: Array[Cutscene] = []
@export var fish_catalog: FishCatalog
@export var staff_catalog: StaffCatalog

var plan: MenuPlan
var market_stock: MarketStock
var bag := MarketBag3D.new()
var renovation: RenovationPreview3D
var staff_roster: StaffRoster
var regular_visits: Array[Dictionary] = []
var regular_queue: Array[Dictionary] = []
var player: CharacterBody3D
var body: PersonRig3D
var guests: Array[Node3D] = []
var order_labels: Array[Label3D] = []
var orders: Array[Dictionary] = []
var hud: RestaurantHud3D
var note: Label
var planning_panel: MenuPanel3D
var market_panel: PanelContainer
var market_list: VBoxContainer
var summary_panel: PanelContainer
var summary_text: Label
var story_bridge
var cooking_overlay: CookingOverlay
var staff_workers: Array[Dictionary] = []
var shift_running := false
var shift_over := false
var seconds_left := SHIFT_SECONDS
var spawn_clock := 2.0
var cooking_table := -1
var carrying_table := -1
var served := 0
var lost := 0
var earned := 0
var market_spent := 0
var step_clock := 0.0
var note_clock := 0.0
var sailing := false
var wages_paid := 0
var wave_power: WavePower
var debug_cutscene_index := 0
var rng := RandomNumberGenerator.new()
var tuning: ServiceTuning
var cat_node: PersonRig3D
var cat_dialogue: DialogueBox
var opening_variety: int = 0
var demo_camera: Camera3D
var action_prompt: PanelContainer
var action_text: Label
var _focus_lost: bool = false
var _dash_left: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_direction := Vector3.ZERO
var bao_table: int = -1
var bao_seconds: float = 0.0
var dirty_tables: Array[bool] = []
var table_plates: Array[Node3D] = []
var ready_plates: Array[Node3D] = []
var bao_model: PersonRig3D
var bao_label: Label3D
## Room bounds (x and z edges); the camera sees all of it.
const ROOM_X := 20.0
const BACK_Z := -7.8
const WALL_H := 7.0
const FRONT_Z := 8.3
const ROAD_DEPTH := 8.0
const COUNTER_POSITION := Vector3(10.0, 0, -4.3)
const DECOR_LANTERNS: Array[float] = [-16.0, -12.0, -8.0, -4.0, 0.0, 4.0, 8.0, 12.0, 16.0]
const DECOR_PLANTERS: Array[float] = [-18.5, 18.5]
const PLANTER_Z := 7.3
const BOARD_POSITION := Vector3(1.5, 0, 6.9)
const PASS_POSITION := Vector3(-0.8, 0, -4.3)
const GRILL_POSITION := Vector3(3.0, 0, -4.3)
const BEER_POSITION := Vector3(5.2, 0, -3.7)
const MEAL_SECONDS := 5.0

func _pick_tuning() -> ServiceTuning:
	var current: ServiceTuning = TUNINGS[0]
	for stage: ServiceTuning in TUNINGS:
		if stage.from_day <= GameState.day:
			current = stage
	return current

func _next_spawn_interval() -> float:
	var decor_level := GameState.get_upgrade_level("decor")
	var decor_scale: float = tuning.decor_interval_scale[clampi(decor_level, 0, tuning.decor_interval_scale.size() - 1)]
	var rating_scale: float = tuning.interval_scale_by_rating[clampi(GameState.last_rating, 0, tuning.interval_scale_by_rating.size() - 1)]
	return rng.randf_range(tuning.min_spawn_interval, tuning.max_spawn_interval) * decor_scale * rating_scale

func _mat(hex: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 0.85
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return m

func _box(parent: Node3D, pos: Vector3, size: Vector3, hex: String, solid := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = _mat(hex)
	parent.add_child(mesh)
	mesh.position = pos
	if solid:
		var obstacle := StaticBody3D.new()
		parent.add_child(obstacle)
		obstacle.position = pos
		var collision := CollisionShape3D.new()
		var collision_shape := BoxShape3D.new()
		collision_shape.size = size
		collision.shape = collision_shape
		obstacle.add_child(collision)
	return mesh

## Invisible collider only.
func _solid_block(pos: Vector3, size: Vector3) -> void:
	var obstacle := StaticBody3D.new()
	add_child(obstacle)
	obstacle.position = pos
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	obstacle.add_child(collision)

func _label(parent: Node3D, words: String, pos: Vector3, size: int, hex: String) -> Label3D:
	var label := Label3D.new()
	label.text = words
	label.font_size = size
	label.pixel_size = 0.005
	label.modulate = Color(hex)
	label.outline_size = 0
	parent.add_child(label)
	label.position = pos
	return label

func _ready() -> void:
	rng.randomize()
	tuning = _pick_tuning()
	market_stock = MarketStock.new(GameState.pantry)
	staff_roster = StaffRoster.new(staff_catalog, GameState.staff)
	if GameState.day >= staff_catalog.unlock_day:
		staff_roster.arrivals(GameState.day)
	GameState.staff_changed.connect(_sync_staff)
	staff_roster.changed.connect(_sync_staff)
	regular_visits = FishOrders.reserve_for_shift(menu)
	regular_queue = regular_visits.duplicate()
	_build_room()
	_add_traffic()
	if PetCat.is_present():
		_build_cat()
	_sync_staff()
	_build_ui()
	cat_dialogue = DialogueBox.new()
	add_child(cat_dialogue)
	var tracker := QuestTracker.new()
	tracker.catalog = fish_catalog
	tracker.origin = Vector2(6, 46)
	add_child(tracker)
	wave_power = WavePower.new()
	wave_power.seconds = 4.0
	wave_power.keep_rin_speed = true
	wave_power.can_use = func() -> bool: return shift_running and not shift_over
	add_child(wave_power)
	cooking_overlay = load("res://scenes/restaurant/cooking/cooking_overlay.tscn").instantiate()
	cooking_overlay.kitchen_upgrade = kitchen_upgrade
	cooking_overlay.finished.connect(_on_cooking_finished)
	cooking_overlay.spilled.connect(_on_cooking_spilled)
	add_child(cooking_overlay)
	plan = MenuPlan.new(3 + mini(DishBook.kitchen_level(), 2))
	plan.kitchen_level = DishBook.kitchen_level()
	DayClock.set_progress(0.0, DayClock.shop_open_hour, DayClock.shop_close_hour)
	DailyTrend.ensure(null, menu)
	planning_panel.setup(plan, menu, market_stock, _has_stock, _ui_theme(), _panel_style())
	planning_panel.shop_requested.connect(_open_market)
	planning_panel.open_requested.connect(_open_shift)
	planning_panel.renovate_requested.connect(_open_renovation)
	planning_panel.sail_requested.connect(_sail_without_shift)
	planning_panel.open()
	story_bridge = load("res://scenes/story3d/story_bridge_3d.tscn").instantiate()
	add_child(story_bridge)
	story_bridge.stage_kind = "restaurant"
	_play_arrival.call_deferred()
	Sfx.ambience("street")

func _play_arrival() -> void:
	planning_panel.hide()
	await story_bridge.play_eligible(arrival_cutscenes)
	_apply_arrival_choice()
	if Guide.once("menu3d"):
		_show_note("Rin: E ở bảng thực đơn để lên món.")

func _build_room() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("202c38")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("9aa8b4")
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	add_child(environment)
	var sunlight := DirectionalLight3D.new()
	add_child(sunlight)
	sunlight.rotation_degrees = Vector3(-52, -30, 0)
	sunlight.light_color = Color("ffd39b")
	sunlight.light_energy = 1.1
	sunlight.shadow_enabled = true
	var lamp := OmniLight3D.new()
	add_child(lamp)
	lamp.position = Vector3(3, 2.8, -3.2)
	lamp.light_color = Color("ffc27a")
	lamp.light_energy = 1.0
	lamp.omni_range = 5.0
	var camera := Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 14.0
	camera.position = Vector3(4.5, 12, 15)
	camera.look_at(Vector3(0, 0, -0.5))
	camera.current = true
	demo_camera = camera
	var depth := FRONT_Z - BACK_Z
	var mid_z := (FRONT_Z + BACK_Z) * 0.5
	var width := ROOM_X * 2.0
	_box(self, Vector3(0, -0.24, mid_z), Vector3(width, 0.4, depth), "394a50")
	for x in range(int(width)):
		for z in range(int(depth)):
			_box(self, Vector3(x - ROOM_X + 0.5, -0.02, z + BACK_Z + 0.5), Vector3(0.96, 0.05, 0.96), "8e8c79" if (x + z) % 3 == 0 else "797e73")
	_box(self, Vector3(0, WALL_H * 0.5, BACK_Z - 0.2), Vector3(width, WALL_H, 0.3), "b6a183", true)
	_box(self, Vector3(0, 0.4, BACK_Z - 0.02), Vector3(width, 0.8, 0.1), "577277")
	_box(self, Vector3(0, 3.7, BACK_Z), Vector3(9, 0.65, 0.14), "7a4841")
	_label(self, "HẢI SẢN XÓM ĐÈN", Vector3(0, 3.7, BACK_Z + 0.1), 52, "f2d98a")
	for n in range(int(width)):
		var color := "456c65" if n % 2 else "c6b89a"
		_box(self, Vector3(n - ROOM_X + 0.5, 2.55, BACK_Z + 0.9), Vector3(0.98, 0.09, 1.1), color)
		_box(self, Vector3(n - ROOM_X + 0.5, 2.4, BACK_Z + 1.46), Vector3(0.98, 0.24, 0.08), color)
	var decor_level := GameState.get_upgrade_level("decor")
	if decor_level > 0:
		for x in DECOR_LANTERNS:
			_box(self, Vector3(x, 2.25, BACK_Z + 1.2), Vector3(0.04, 0.40, 0.04), "402751")
			_box(self, Vector3(x, 2.02, BACK_Z + 1.2), Vector3(0.33, 0.28, 0.33), "de9e41")
	if decor_level > 1:
		for x in DECOR_PLANTERS:
			_box(self, Vector3(x, 0.36, PLANTER_Z), Vector3(0.6, 0.72, 0.6), "7a4841")
			_box(self, Vector3(x, 0.87, PLANTER_Z), Vector3(0.85, 0.45, 0.85), "468232")
	_box(self, BOARD_POSITION + Vector3(0, 0.9, 0), Vector3(1.5, 1.1, 0.12), "1c2a33", true)
	_label(self, "THỰC ĐƠN", BOARD_POSITION + Vector3(0, 1.1, 0.1), 28, "f2d98a")
	_box(self, Vector3(0, -0.05, FRONT_Z + 0.1), Vector3(width, 0.2, 0.3), "e7d5b3", true)
	_box(self, Vector3(0, -0.2, FRONT_Z + 0.2 + ROAD_DEPTH * 0.5), Vector3(width, 0.2, ROAD_DEPTH), "202e37")
	for x in range(-18, 19, 6):
		_box(self, Vector3(x, -0.08, FRONT_Z + 0.2 + ROAD_DEPTH * 0.5), Vector3(2.0, 0.02, 0.15), "8e8c79")
	var table_count := clampi(int(GameState.get_upgrade_value(seats_upgrade)), 1, TABLES.size()) if seats_upgrade else 4
	for i in range(table_count):
		var p: Vector3 = TABLES[i]
		_box(self, p + Vector3(0, 0.8, 0), Vector3(1.5, 0.12, 1.2), "c7cfcc", true)
		for x in [-0.57, 0.57]:
			for z in [-0.4, 0.4]:
				_box(self, p + Vector3(x, 0.4, z), Vector3(0.07, 0.8, 0.07), "577277")
		for side in [-1.0, 1.0]:
			var stool_pos := p + Vector3(side * 1.02, 0, 0)
			_box(self, stool_pos + Vector3(0, 0.46, 0), Vector3(0.55, 0.12, 0.55), "3c5e8b" if side < 0 else "a53030")
			_box(self, stool_pos + Vector3(0, 0.2, 0), Vector3(0.12, 0.4, 0.12), "577277")
			_solid_block(stool_pos + Vector3(0, 0.26, 0), Vector3(0.55, 0.52, 0.55))
		var guest := PersonRig3D.build(self, "guest", "7a4841" if i == 0 else "468232")
		guest.position = p + Vector3(0, 0, 1.15)
		guests.append(guest)
		guest.visible = false
		order_labels.append(_label(self, "", p + Vector3(0, 2.25, 0.6), 18, "f2d98a"))
		orders.append({})
		dirty_tables.append(false)
		var dish_visual := _plate_model(self)
		dish_visual.position = p + Vector3(0, 0.9, 0)
		dish_visual.visible = false
		table_plates.append(dish_visual)
		var ready := _plate_model(self)
		ready.position = PASS_POSITION + Vector3((i % 4) * 0.18 - 0.3, 0.95 + (i / 4) * 0.08, 0)
		ready.visible = false
		ready_plates.append(ready)
	_box(self, GRILL_POSITION + Vector3(0, 0.7, 0), Vector3(2.8, 1.3, 1.25), "577277", true)
	_box(self, GRILL_POSITION + Vector3(0, 1.42, 0), Vector3(3, 0.12, 1.4), "c7cfcc")
	_box(self, GRILL_POSITION + Vector3(-0.4, 1.52, 0), Vector3(1.2, 0.1, 0.65), "394a50")
	for n in range(6):
		_box(self, GRILL_POSITION + Vector3(-0.88 + n * 0.18, 1.6, 0), Vector3(0.06, 0.05, 0.48), "de9e41")
	_box(self, Vector3(5.5, 0.7, 1.5), Vector3(1.2, 1.3, 0.1), "884b2b", true)
	_label(self, "BẾP   E\nBẢNG MÓN", Vector3(5.5, 0.8, 1.57), 16, "e7d5b3")
	# Cô Năm keeps her grocery counter separate from the kitchen.
	_box(self, COUNTER_POSITION + Vector3(0, 0.75, 0), Vector3(3.6, 1.0, 0.8), "468232", true)
	_box(self, COUNTER_POSITION + Vector3(0, 1.3, 0), Vector3(3.8, 0.12, 1.0), "e7d5b3")
	_label(self, "TẠP HOÁ CÔ NĂM", COUNTER_POSITION + Vector3(0, 2.4, -0.45), 24, "f2d98a")
	PersonRig3D.build(self, "co_nam").position = COUNTER_POSITION + Vector3(0, 0, -0.85)
	# Bảo cooks independently, leaving grill and beer to Rin.
	bao_model = PersonRig3D.build(self, "bao")
	bao_model.position = GRILL_POSITION + Vector3(-0.7, 0, -1.3)
	bao_label = _label(self, "Bảo • bếp", GRILL_POSITION + Vector3(-0.7, 2.35, -1.3), 20, "f0d39b")
	_box(self, PASS_POSITION + Vector3(0, 0.83, 0), Vector3(1.1, 0.12, 0.75), "a27d4c", true)
	for x: float in [-0.4, 0.4]:
		_box(self, PASS_POSITION + Vector3(x, 0.4, 0), Vector3(0.07, 0.8, 0.6), "685448")
	_label(self, "NHẬN MÓN • E", PASS_POSITION + Vector3(0, 1.5, 0), 18, "e5cf9d")
	_box(self, BEER_POSITION + Vector3(0, 0.85, 0), Vector3(0.5, 1.2, 0.5), "91a4a3", true)
	_label(self, "RÓT BIA • E", BEER_POSITION + Vector3(0, 1.75, 0), 18, "e5cf9d")
	_box(self, Vector3(0, 1.4, FRONT_Z), Vector3(width, 3.0, 0.15), "35434d", true).visible = false
	for x: float in [-ROOM_X, ROOM_X]:
		_box(self, Vector3(x, 1.4, mid_z), Vector3(0.15, 3.0, depth), "35434d", true).visible = false
	player = CharacterBody3D.new()
	add_child(player)
	player.position = Vector3(0, 0, 2)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.6
	collider.shape = capsule
	collider.position.y = 0.8
	player.add_child(collider)
	body = PersonRig3D.build(player, "rin")

func _build_cat() -> void:
	cat_node = PersonRig3D.build(self, "cat")
	cat_node.position = Vector3(-3.3, 0, -6.6)

func _add_traffic() -> void:
	var traffic := CustomerTraffic3D.new()
	traffic.host = self
	add_child(traffic)

func _sync_staff() -> void:
	for worker in staff_workers:
		var table: int = worker["table"]
		if table >= 0 and not orders[table].is_empty():
			orders[table]["staff_claimed"] = false
		(worker["node"] as Node3D).queue_free()
	staff_workers.clear()
	for person in staff_roster.hired():
		var node := PersonRig3D.build(self, "guest", person.body_color.to_html(false))
		node.position = Vector3(3.3 + staff_workers.size() * 0.7, 0, -0.5)
		staff_workers.append({"data": person, "node": node, "table": -1, "picked": false})
	if shift_running:
		_dispatch_ready()

func _dispatch_ready() -> void:
	for i in range(orders.size()):
		if orders[i].is_empty() or str(orders[i].get("phase", "waiting")) != "waiting" or not bool(orders[i].get("cooked", false)) or bool(orders[i].get("staff_claimed", false)) or carrying_table == i:
			continue
		for worker in staff_workers:
			if int(worker["table"]) == -1:
				worker["table"] = i
				orders[i]["staff_claimed"] = true
				break

func _move_staff(delta: float) -> void:
	for worker in staff_workers:
		var node: Node3D = worker["node"]
		var table: int = worker["table"]
		if table < 0:
			var dirty: int = dirty_tables.find(true)
			if dirty >= 0:
				var clean_target: Vector3 = TABLES[dirty] + Vector3(0, 0, 1.1)
				StaffPathing3D.step(node, TABLES, clean_target, delta * 3.0)
				if node.position.distance_to(clean_target) < 0.06:
					_clean_table(dirty)
				continue
			var home := Vector3(3.3 + staff_workers.find(worker) * 0.7, 0, -0.5)
			StaffPathing3D.step(node, TABLES, home, delta * 2.5)
			continue
		if orders[table].is_empty():
			worker["picked"] = false
			worker["table"] = -1
			continue
		var picked: bool = bool(worker.get("picked", false))
		var target: Vector3 = TABLES[table] + Vector3(0, 0, 1.2) if picked else PASS_POSITION + Vector3(0, 0, 1.0)
		var person: StaffData = worker["data"]
		StaffPathing3D.step(node, TABLES, target, delta * person.walk_speed / 23.0)
		if node.position.distance_to(target) < 0.05:
			if not picked:
				worker["picked"] = true
			else:
				_serve(table)
				worker["table"] = -1
				worker["picked"] = false

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = RestaurantHud3D.new()
	add_child(hud)
	hud.setup(self, _ui_theme(), _panel_style())
	hud.menu_requested.connect(_toggle_planning)
	hud.renovate_requested.connect(_open_renovation)
	hud.close_requested.connect(_close_early)
	hud.sail_requested.connect(_sail)
	note = Label.new()
	note.position = Vector2(12, 326)
	note.add_theme_font_size_override("font_size", 11)
	note.add_theme_stylebox_override("normal", _panel_style())
	note.custom_minimum_size.x = 610
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", Color("e7d5b3"))
	layer.add_child(note)
	planning_panel = MenuPanel3D.new()
	layer.add_child(planning_panel)
	market_panel = PanelContainer.new()
	market_panel.position = Vector2(170, 65)
	market_panel.custom_minimum_size = Vector2(300, 225)
	layer.add_child(market_panel)
	market_list = VBoxContainer.new()
	market_panel.add_child(market_list)
	market_panel.hide()
	summary_panel = PanelContainer.new()
	summary_panel.position = Vector2(135, 48)
	summary_panel.custom_minimum_size = Vector2(370, 110)
	layer.add_child(summary_panel)
	var summary_box := VBoxContainer.new()
	summary_panel.add_child(summary_box)
	summary_text = Label.new()
	summary_box.add_child(summary_text)
	var close_summary := Button.new()
	close_summary.text = "Đóng"
	close_summary.pressed.connect(summary_panel.hide)
	summary_box.add_child(close_summary)
	summary_panel.hide()
	for panel: PanelContainer in [market_panel, summary_panel]:
		panel.theme = _ui_theme()
		panel.add_theme_stylebox_override("panel", _panel_style())
	action_prompt = PanelContainer.new()
	action_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_prompt.theme = _ui_theme()
	action_prompt.add_theme_stylebox_override("panel", _panel_style())
	layer.add_child(action_prompt)
	action_text = Label.new()
	action_text.add_theme_color_override("font_color", Color("f0d39b"))
	action_prompt.add_child(action_text)
	action_prompt.hide()
	add_child(load("res://scenes/ui/pause_menu.tscn").instantiate())
	add_child(load("res://scenes/ui/phone_app.tscn").instantiate())
	bag.build_fridge(self)
	_refresh_market()

func _refresh_market() -> void:
	for old in market_list.get_children():
		old.queue_free()
	var title := Label.new()
	title.text = "CÔ NĂM • TẠP HOÁ  |  Tiền: %dk" % GameState.money
	market_list.add_child(title)
	for dish in menu.dishes:
		if not dish.is_market_dish() or dish.unlock_day > GameState.day:
			continue
		var row := HBoxContainer.new()
		market_list.add_child(row)
		var buy := Button.new()
		buy.text = "%s  •  %dk  (còn %d)" % [dish.display_name, dish.market_cost, market_stock.portions(dish)]
		buy.disabled = GameState.money < dish.market_cost
		buy.pressed.connect(_buy_market.bind(dish, false))
		row.add_child(buy)
		if dish.has_bulk():
			var bulk := Button.new()
			bulk.text = "Lô %dk" % dish.bulk_cost
			bulk.disabled = GameState.money < dish.bulk_cost
			bulk.pressed.connect(_buy_market.bind(dish, true))
			row.add_child(bulk)
	var close := Button.new()
	close.text = "Đóng"
	close.pressed.connect(func() -> void:
		market_panel.hide()
		if not shift_running and not shift_over:
			planning_panel.open())
	market_list.add_child(close)

func _open_market() -> void:
	planning_panel.hide()
	_refresh_market()
	market_panel.show()

func _buy_market(dish: DishData, bulk: bool) -> void:
	var cost := dish.buy_cost(bulk)
	if not GameState.spend_money(cost):
		_show_note("Không đủ tiền mua %s." % dish.display_name)
		return
	if shift_running:
		bag.add(dish, bulk)
		_show_note("Mua xong. Đem túi cất vô tủ lạnh (E).")
	else:
		market_stock.add(dish, dish.buy_units(bulk))
	market_spent += cost
	Sfx.play("bag")
	_refresh_market()

func _open_renovation() -> void:
	if renovation == null:
		renovation = RenovationPreview3D.new()
		add_child(renovation)
		var list: Array[UpgradeData] = [seats_upgrade, decor_upgrade, kitchen_upgrade, fridge_upgrade]
		var spots: Array[Vector3] = []
		spots.assign(TABLES)
		renovation.setup(self, spots, list, _ui_theme())
		renovation.finished.connect(_on_renovation_finished)
	planning_panel.hide()
	renovation.open()

func _on_renovation_finished(applied: bool) -> void:
	if applied:
		_show_note("Sửa quán xong!")
	
func _buy_upgrade(upgrade: UpgradeData) -> void:
	if GameState.buy_upgrade(upgrade):
		_show_note("Đã nâng cấp %s. Có hiệu lực từ ca sau." % upgrade.display_name)
		
func _open_shift() -> void:
	if shift_running or shift_over or not _has_stock():
		return
	opening_variety = plan.variety_count()
	planning_panel.hide()
	shift_running = true
	seconds_left = SHIFT_SECONDS
	spawn_clock = tuning.first_spawn_delay
	_show_note("Bảo nấu món thường. E ở bàn nhận món; nướng và rót bia do Rin làm. T: đóng sớm.")

func _physics_process(delta: float) -> void:
	if get_tree().paused or _focus_lost:
		player.velocity = Vector3.ZERO
		return
	if shift_running:
		_move_staff(delta)
	if market_panel.visible or cooking_overlay.is_running() or is_renovating():
		player.velocity = Vector3.ZERO
		return
	var axes := Input.get_vector("turn_left", "turn_right", "throttle_forward", "throttle_back")
	var rin_scale := 1.0 / maxf(Engine.time_scale, 0.001) if WavePower.rin_unslowed else 1.0
	var right := demo_camera.global_basis.x
	right.y = 0.0
	var forward := demo_camera.global_basis.z
	forward.y = 0.0
	var direction: Vector3 = (right.normalized() * axes.x + forward.normalized() * axes.y).limit_length(1.0)
	_dash_cooldown = maxf(_dash_cooldown - delta * rin_scale, 0.0)
	if Input.is_action_just_pressed("dash") and _dash_cooldown <= 0.0 and direction.length_squared() > 0.01:
		_dash_left = 0.14
		_dash_cooldown = 0.45
		_dash_direction = direction.normalized()
	if _dash_left > 0.0:
		_dash_left = maxf(_dash_left - delta * rin_scale, 0.0)
		player.velocity = _dash_direction * 11.0 * rin_scale
	else:
		player.velocity = direction * 4.2 * rin_scale
	player.move_and_slide()
	step_clock += delta * rin_scale
	if player.velocity.length() > 0.1:
		player.rotation.y = lerp_angle(player.rotation.y, atan2(player.velocity.x, player.velocity.z), minf(delta * 10.0, 1.0))
	body.set_carrying(carrying_table >= 0)
	body.set_walking(axes.length(), step_clock)
	for i in range(guests.size()):
		guests[i].position.y = sin(floorf(step_clock * 5.0 + float(i))) * 0.025

func _process(delta: float) -> void:
	_refresh_action_prompt()
	if cat_node:
		cat_node.rotation.y = sin(Time.get_ticks_msec() / 650.0) * 0.06
	if note_clock > 0.0:
		note_clock -= delta
		if note_clock <= 0.0:
			note.text = ""
	if not shift_running or get_tree().paused:
		return
	seconds_left = maxf(seconds_left - delta, 0.0)
	DayClock.set_progress(1.0 - seconds_left / SHIFT_SECONDS, DayClock.shop_open_hour, DayClock.shop_close_hour)
	_tick_bao(delta)
	_sync_food_visuals()
	spawn_clock -= delta
	if spawn_clock <= 0.0 and seconds_left > 0.0:
		_spawn_order()
		spawn_clock = _next_spawn_interval()
	for i in range(orders.size()):
		if orders[i].is_empty():
			continue
		if str(orders[i].get("phase", "waiting")) == "eating":
			orders[i]["meal_left"] = float(orders[i]["meal_left"]) - delta
			if float(orders[i]["meal_left"]) <= 0.0:
				_finish_meal(i)
			continue
		orders[i]["patience"] = float(orders[i]["patience"]) - delta
		if float(orders[i]["patience"]) <= 0.0:
			_lose_order(i)
	if (seconds_left <= 0.0 or not _has_stock()) and orders.all(func(order: Dictionary) -> bool: return order.is_empty()):
		_end_shift()

func _spawn_order() -> void:
	var available := plan.available_dishes()
	for dish in menu.dishes:
		if dish.is_market_dish() and dish.unlock_day <= GameState.day and market_stock.portions(dish) > 0:
			available.append(dish)
	if available.is_empty() and regular_queue.is_empty():
		return
	var free: Array[int] = []
	for i in range(orders.size()):
		if orders[i].is_empty() and not dirty_tables[i]:
			free.append(i)
	if free.is_empty():
		return
	var table := free[rng.randi_range(0, free.size() - 1)]
	if not regular_queue.is_empty():
		var visit: Dictionary = regular_queue.pop_front()
		var regular_dish: DishData = visit["dish"]
		var reserved: Array[InventoryItem] = [visit["item"]]
		orders[table] = {"dish": regular_dish, "items": reserved, "freshness": 100.0,
			"patience": 38.0 * tuning.regular_patience_scale, "initial_patience": 38.0 * tuning.regular_patience_scale, "visit": visit,
			"cooked": false, "staff_claimed": false, "multiplier": 1.0, "rich": false}
		guests[table].visible = true
		order_labels[table].text = "%s\n%s" % [visit["order"]["who"], regular_dish.display_name]
		_show_note("%s tới nhận món đặt ở bàn %d." % [visit["order"]["who"], table + 1])
		return
	var dish := available[rng.randi_range(0, available.size() - 1)]
	var items: Array[InventoryItem] = []
	var freshness := 100.0
	if dish.is_market_dish():
		market_stock.take(dish)
		freshness = market_stock.last_freshness
	else:
		items = plan.take_portion(dish)
	var decor_level := GameState.get_upgrade_level("decor")
	var rich_chance: float = tuning.rich_chance_by_decor[clampi(decor_level, 0, tuning.rich_chance_by_decor.size() - 1)]
	var rich := rng.randf() < rich_chance
	var patience := 38.0 * (tuning.rich_patience_scale if rich else 1.0)
	if PetCat.is_present():
		patience *= tuning.cat_patience_scale
	orders[table] = {"dish": dish, "items": items, "freshness": freshness, "patience": patience, "initial_patience": patience,
		"visit": {}, "cooked": false, "staff_claimed": false, "multiplier": 1.0, "rich": rich,
		"party": PartyOrders3D.start(tuning, plan, menu, market_stock)}
	guests[table].visible = true
	order_labels[table].text = ("KHÁCH SANG\n" if rich else "") + orders[table]["party"].label(dish)
	_show_note("Bàn %d gọi %s." % [table + 1, dish.display_name])

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or get_tree().paused:
		return
	if OS.is_debug_build() and key.physical_keycode == KEY_F1 and not shift_running and not shift_over:
		_debug_fill_fish()
		get_viewport().set_input_as_handled()
		return
	if OS.is_debug_build() and key.physical_keycode == KEY_F2:
		_debug_fill_drinks()
		get_viewport().set_input_as_handled()
		return
	if OS.is_debug_build() and key.physical_keycode == KEY_F3 and not story_bridge.playing:
		var cutscenes: Array[Cutscene] = []
		cutscenes.append_array(arrival_cutscenes)
		cutscenes.append_array(after_shift_cutscenes)
		if not cutscenes.is_empty():
			var cutscene: Cutscene = cutscenes[debug_cutscene_index % cutscenes.size()]
			debug_cutscene_index += 1
			_show_note("[debug] cutscene: " + cutscene.id)
			story_bridge.play(cutscene)
			get_viewport().set_input_as_handled()
		return
	if OS.is_debug_build() and key.physical_keycode == KEY_F4:
		if WaveMark.has_power():
			GameState.story_flags.erase(WaveMark.FLAG)
		else:
			GameState.set_flag(WaveMark.FLAG)
		wave_power.charges = WaveMark.max_charges()
		_show_note("[debug] Nhịp Sóng: %s" % ("có (C)" if WaveMark.has_power() else "tắt"))
		get_viewport().set_input_as_handled()
		return
	if market_panel.visible:
		if key.physical_keycode == KEY_ESCAPE or key.physical_keycode == KEY_E:
			market_panel.hide()
			get_viewport().set_input_as_handled()
		return
	if key.physical_keycode == KEY_E:
		_interact()
		get_viewport().set_input_as_handled()
	elif key.physical_keycode == KEY_T:
		_close_early()
		get_viewport().set_input_as_handled()

func _close_early() -> void:
	if not shift_running or seconds_left <= 0.0:
		return
	seconds_left = 0.0
	_show_note("Rin: đóng cửa, phục vụ nốt khách đang ngồi.")

func is_renovating() -> bool:
	return renovation != null and renovation.layer != null and renovation.layer.visible

func _toggle_planning() -> void:
	if shift_running or shift_over:
		return
	if planning_panel.visible:
		planning_panel.close()
	else:
		market_panel.hide()
		planning_panel.open()

func _debug_fill_fish() -> void:
	if fish_catalog == null:
		return
	for fish in fish_catalog.fish:
		GameState.storage.append(InventoryItem.new(fish, 1.0))
	planning_panel.refresh()
	_show_note("[debug] Đã thêm mỗi loại cá vào kho.")

func _debug_fill_drinks() -> void:
	if menu == null:
		return
	for dish in menu.dishes:
		if dish.instant_serve:
			var units := dish.buy_units(dish.has_bulk())
			market_stock.add(dish, units)
			_show_note("[debug] +%d %s %s vào tủ lạnh" % [units, dish.unit_name, dish.display_name])
	if not shift_running and not shift_over:
		planning_panel.refresh()

func _interact() -> void:
	if cooking_overlay.is_running():
		return
	if cat_node and player.position.distance_to(cat_node.position) < 1.3:
		var dialogue := DialogueLibrary.pick(CAT_DIALOGUES) as Dialogue
		if dialogue:
			cat_dialogue.play(dialogue)
		return
	if bag.has_goods() and bag.near_fridge(player.position):
		bag.store(market_stock, menu.dishes)
		Sfx.play("bag")
		_show_note("Cất vô tủ lạnh xong.")
		return
	if player.position.distance_to(COUNTER_POSITION) < 2.1:
		_open_market()
		return
	if player.position.distance_to(BOARD_POSITION) < 2.2 and not shift_running and not shift_over:
		_toggle_planning()
		return
	if not shift_running:
		return
	if carrying_table >= 0:
		var table := carrying_table
		if player.position.distance_to(TABLES[table]) < 2.0:
			_serve(table)
		else:
			_show_note("Đem món tới bàn %d." % (table + 1))
		return
	for i: int in range(dirty_tables.size()):
		if dirty_tables[i] and player.position.distance_to(TABLES[i]) < 2.0:
			_clean_table(i)
			return
	if player.position.distance_to(PASS_POSITION) < 1.35:
		_pickup_ready()
		return
	var at_grill: bool = player.position.distance_to(GRILL_POSITION) < 2.4
	var at_beer: bool = player.position.distance_to(BEER_POSITION) < 1.7
	if at_grill or at_beer:
		for i: int in range(orders.size()):
			if orders[i].is_empty() or bool(orders[i].get("cooked", false)):
				continue
			var dish: DishData = orders[i]["dish"]
			if (at_beer and dish.instant_serve) or (at_grill and not ChefBao.cooks(dish) and not dish.instant_serve):
				cooking_table = i
				cooking_overlay.start(dish)
				return
		_show_note("Chưa có món đang chờ tại đây.")

func _on_cooking_finished(_dish: DishData, _result: CookingGameBase.Result, multiplier: float) -> void:
	if cooking_table < 0 or orders[cooking_table].is_empty():
		cooking_table = -1
		return
	var table := cooking_table
	cooking_table = -1
	orders[table]["cooked"] = true
	orders[table]["multiplier"] = multiplier
	var visit: Dictionary = orders[table].get("visit", {})
	if not visit.is_empty():
		visit["cooked"] = true
	_dispatch_ready()
	_show_note("Món bàn %d đã xong!" % (table + 1))

func _on_cooking_spilled(dish: DishData) -> void:
	if dish.is_market_dish():
		market_stock.spill(dish, 1)

func _serve(table: int) -> void:
	var order := orders[table]
	if order.is_empty() or not bool(order.get("cooked", false)) or str(order.get("phase", "waiting")) != "waiting":
		return
	if carrying_table != table and not bool(order.get("staff_claimed", false)):
		return
	order["phase"] = "eating"
	order["meal_left"] = MEAL_SECONDS
	if carrying_table == table:
		carrying_table = -1
	order_labels[table].text = "Bàn %d • đang ăn" % (table + 1)
	_show_note("Mời bàn %d dùng món!" % (table + 1))
	_dispatch_ready()

func _finish_meal(table: int) -> void:
	var order := orders[table]
	if order.is_empty() or str(order.get("phase", "")) != "eating":
		return
	var dish: DishData = order["dish"]
	var ingredients: Array[InventoryItem] = order["items"]
	var visit: Dictionary = order.get("visit", {})
	var plate := DishShelf.Plate.new(dish, ingredients, float(order["multiplier"]), visit)
	var variety := MenuPlan.variety_multiplier(opening_variety, MenuPanel3D.VARIETY_TABLE)
	var price := TableBill.plate_price(plate, variety, DailyTrend.price_scale(dish))
	if bool(order.get("rich", false)):
		price = roundi(float(price) * tuning.rich_price_scale)
	if dish.is_market_dish():
		price = roundi(float(price) * KitchenLogic.freshness_multiplier(float(order["freshness"])))
	var party: PartyOrders3D = order.get("party")
	if party:
		party.bill += price
		if party.advance(order, tuning, plan, menu, market_stock):
			order_labels[table].text = party.label(order["dish"])
			_show_note("Bàn %d gọi tiếp %s." % [table + 1, order["dish"].display_name])
			_dispatch_ready()
			return
		price = party.bill
	var patience_ratio: float = float(order["patience"]) / float(order.get("initial_patience", 38.0))
	var tip := roundi(price * (tuning.tip_ratio + staff_roster.tip_bonus())) if visit.is_empty() and patience_ratio > tuning.tip_patience_threshold else 0
	GameState.add_money(price + tip)
	earned += price + tip
	if not visit.is_empty():
		FishOrders.complete(visit["order"])
		GameState.set_flag("regular_served_once")
		visit["served"] = true
	served += 1
	if carrying_table == table:
		carrying_table = -1
	orders[table] = {}
	dirty_tables[table] = true
	guests[table].visible = false
	order_labels[table].text = "Bàn %d • E dọn" % (table + 1)
	_show_note("%s: +%dk. Cảm ơn khách bàn %d!" % [dish.display_name, price + tip, table + 1])
	Sfx.play("coins")
	_dispatch_ready()

func _lose_order(table: int) -> void:
	var already_cooked: bool = bool(orders[table].get("cooked", false))
	var left_party: PartyOrders3D = orders[table].get("party")
	if left_party:
		var part_paid: int = left_party.abandon(plan, market_stock)
		GameState.add_money(part_paid)
		earned += part_paid
	if table == cooking_table:
		cooking_table = -1
	if table == carrying_table:
		carrying_table = -1
	if not already_cooked:
		var dish: DishData = orders[table]["dish"]
		var visit: Dictionary = orders[table].get("visit", {})
		if not visit.is_empty():
			FishOrders.release(visit)
			visit["released"] = true
		elif dish.is_market_dish():
			market_stock.add(dish, dish.portion_units, float(orders[table]["freshness"]))
		else:
			var ingredients: Array[InventoryItem] = orders[table]["items"]
			plan.return_portion(dish, ingredients)
	orders[table] = {}
	guests[table].visible = false
	order_labels[table].text = ""
	lost += 1
	_show_note("Khách bàn %d đợi lâu quá nên bỏ về." % (table + 1))
	_dispatch_ready()

func _end_shift() -> void:
	if shift_over:
		return
	shift_running = false
	shift_over = true
	DayClock.set_progress(1.0, DayClock.shop_open_hour, DayClock.shop_close_hour)
	var leftover := plan.total_portions()
	var limited_variety := opening_variety < 2
	plan.clear(GameState.storage)
	for visit in regular_visits:
		if not bool(visit.get("cooked", false)) and not bool(visit.get("released", false)) and not bool(visit.get("served", false)):
			FishOrders.release(visit)
			visit["released"] = true
	FishOrders.expire_after_shift(fish_catalog)
	for person in staff_roster.hired():
		GameState.set_flag("worked_" + person.id)
	wages_paid = mini(staff_roster.wages(), GameState.money)
	GameState.add_money(-wages_paid)
	var stars := DayRating.stars(served, lost, limited_variety)
	GameState.last_rating = stars
	GameState.add_day_record({"day": GameState.day, "earned": earned, "market": market_spent, "rating": stars, "served": served, "left": lost, "wages": wages_paid})
	summary_text.text = "HẾT CA • XÓM ĐÈN\nPhục vụ: %d  |  Bỏ về: %d\nThu: %dk  |  Chợ: %dk  |  Lương: %dk\nDư: %d phần  |  Đánh giá: %d sao" % [served, lost, earned, market_spent, wages_paid, leftover, stars]
	summary_panel.show()

func _sail_without_shift() -> void:
	plan.clear(GameState.storage)
	for visit in regular_visits:
		FishOrders.release(visit)
	FishOrders.expire_after_shift(fish_catalog)
	_sail()

func _sail() -> void:
	if sailing or (not shift_over and _has_stock()):
		return
	sailing = true
	if shift_over:
		await story_bridge.play_eligible(after_shift_cutscenes)
	bag.store(market_stock, menu.dishes)
	var freshness_loss := float(GameState.get_upgrade_value(fridge_upgrade)) if fridge_upgrade else 35.0
	GameState.advance_day(freshness_loss)
	FishOrders.roll_new_order(rng, fish_catalog)
	GameState.resume_at = "sea"
	SceneRouter.go_to(SEA_SCENE)

func _show_note(words: String) -> void:
	note.text = words
	note_clock = 4.0

func _has_stock() -> bool:
	if not plan.is_sold_out() or not regular_queue.is_empty():
		return true
	for dish: DishData in menu.dishes:
		if dish.is_market_dish() and dish.unlock_day <= GameState.day and market_stock.portions(dish) > 0:
			return true
	return false

func _tick_bao(delta: float) -> void:
	if bao_table >= 0:
		if orders[bao_table].is_empty():
			bao_table = -1
		else:
			bao_seconds -= delta
			bao_model.rotation.y = sin(step_clock * 7.0) * 0.08
			if bao_seconds <= 0.0:
				var table: int = bao_table
				bao_table = -1
				orders[table]["cooked"] = true
				var visit: Dictionary = orders[table].get("visit", {})
				if not visit.is_empty():
					visit["cooked"] = true
				_show_note("Bảo: Món bàn %d xong rồi Rin!" % (table + 1))
				_dispatch_ready()
	if bao_table < 0:
		bao_label.text = "Bảo • bếp"
		for i: int in range(orders.size()):
			if orders[i].is_empty() or bool(orders[i].get("cooked", false)):
				continue
			var dish: DishData = orders[i]["dish"]
			if ChefBao.cooks(dish):
				bao_table = i
				bao_seconds = maxf(1.8, 5.0 - DishBook.kitchen_level())
				bao_label.text = "Bảo: " + dish.display_name
				break

func _pickup_ready() -> bool:
	if carrying_table >= 0:
		return false
	for i: int in range(orders.size()):
		if orders[i].is_empty() or not bool(orders[i].get("cooked", false)) or bool(orders[i].get("staff_claimed", false)) or str(orders[i].get("phase", "waiting")) != "waiting":
			continue
		carrying_table = i
		_show_note("Đem %s tới bàn %d." % [orders[i]["dish"].display_name, i + 1])
		return true
	_show_note("Bảo: Chưa có món trên bàn nhận.")
	return false

func _clean_table(table: int) -> void:
	if table < 0 or table >= dirty_tables.size() or not dirty_tables[table]:
		return
	dirty_tables[table] = false
	table_plates[table].visible = false
	order_labels[table].text = ""
	Sfx.play("ok")
	_show_note("Đã dọn bàn %d." % (table + 1))

func _plate_model(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	_box(root, Vector3.ZERO, Vector3(0.36, 0.035, 0.3), "e8d9b7")
	for i: int in range(3):
		_box(root, Vector3(-0.1 + i * 0.1, 0.045, 0), Vector3(0.075, 0.05, 0.18), "c97649")
	return root

func _sync_food_visuals() -> void:
	for i: int in range(orders.size()):
		var order: Dictionary = orders[i]
		ready_plates[i].visible = not order.is_empty() and bool(order.get("cooked", false)) and str(order.get("phase", "waiting")) == "waiting" and carrying_table != i and not bool(order.get("staff_claimed", false))
		table_plates[i].visible = dirty_tables[i] or (not order.is_empty() and str(order.get("phase", "waiting")) == "eating")

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("202c38")
	style.border_color = Color("697575")
	style.set_border_width_all(1)
	style.set_content_margin_all(5)
	style.set_corner_radius_all(3)
	return style

func _ui_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 12
	theme.set_color("font_color", "Label", Color("e9dfc5"))
	theme.set_color("font_color", "Button", Color("e9dfc5"))
	return theme

func _refresh_action_prompt() -> void:
	if action_prompt == null:
		return
	action_prompt.hide()
	if get_tree().paused or market_panel.visible or cooking_overlay.is_running() or _focus_lost or is_renovating():
		return
	var at: Vector3 = player.position + Vector3(0, 2.3, 0)
	var words: String = ""
	if not shift_running:
		if player.position.distance_to(COUNTER_POSITION) < 2.1:
			at = COUNTER_POSITION + Vector3(0, 2.0, 0)
			words = "[E] Mua rau / bia · Cô Năm"
		elif player.position.distance_to(BOARD_POSITION) < 2.2 and not shift_over:
			at = BOARD_POSITION + Vector3(0, 2.0, 0)
			words = "[E] Lên thực đơn"
	elif carrying_table >= 0:
		at = TABLES[carrying_table] + Vector3(0, 1.9, 0)
		words = "Bàn %d · mang món tới đây" % (carrying_table + 1)
		if player.position.distance_to(TABLES[carrying_table]) < 2.0:
			words = "[E] Phục vụ bàn %d" % (carrying_table + 1)
	elif player.position.distance_to(COUNTER_POSITION) < 2.1:
		at = COUNTER_POSITION + Vector3(0, 2.0, 0)
		words = "[E] Mua rau / bia · Cô Năm"
	else:
		var cleaning: bool = false
		for i: int in range(dirty_tables.size()):
			if dirty_tables[i] and player.position.distance_to(TABLES[i]) < 2.0:
				at = TABLES[i] + Vector3(0, 1.5, 0)
				words = "[E] Dọn bàn %d" % (i + 1)
				cleaning = true
				break
		if not cleaning:
			if player.position.distance_to(PASS_POSITION) < 1.35:
				at = PASS_POSITION + Vector3(0, 1.5, 0)
				words = "[E] Nhận món Bảo đã nấu"
			elif player.position.distance_to(BEER_POSITION) < 1.7:
				at = BEER_POSITION + Vector3(0, 1.9, 0)
				words = "[E] Rót bia cho khách"
			elif player.position.distance_to(GRILL_POSITION) < 2.4:
				at = GRILL_POSITION + Vector3(0, 1.9, 0)
				words = "[E] Nướng món đang chờ"
	if words.is_empty():
		return
	action_text.text = words
	action_prompt.reset_size()
	var screen: Vector2 = demo_camera.unproject_position(at)
	var size: Vector2 = get_viewport().get_visible_rect().size
	action_prompt.position = Vector2(clampf(screen.x - action_prompt.size.x * 0.5, 6.0, maxf(6.0, size.x - action_prompt.size.x - 6.0)), clampf(screen.y, 32.0, size.y - 55.0))
	action_prompt.show()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focus_lost = true
		_dash_left = 0.0
		for action: String in ["turn_left", "turn_right", "throttle_forward", "throttle_back", "dash"]:
			Input.action_release(action)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focus_lost = false

func _apply_arrival_choice() -> void:
	if not GameState.story_flags.has(ArrivalCutscenes.HIRE_VY_FLAG):
		return
	GameState.story_flags.erase(ArrivalCutscenes.HIRE_VY_FLAG)
	var vy: StaffData = staff_roster.catalog.find("vy")
	if vy != null and staff_roster.hire(vy):
		_show_note("Vy vào làm từ hôm nay!")
