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
	Vector3(-2.3, 0, -3.0), Vector3(-2.3, 0, -0.8),
	Vector3(-2.3, 0, 1.4), Vector3(-2.3, 0, 3.6),
	Vector3(-5.3, 0, -3.0), Vector3(-5.3, 0, -0.8),
	Vector3(-5.3, 0, 1.4), Vector3(-5.3, 0, 3.6),
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
var staff_roster: StaffRoster
var regular_visits: Array[Dictionary] = []
var regular_queue: Array[Dictionary] = []
var player: CharacterBody3D
var body: Node3D
var arms: Array[Node3D] = []
var legs: Array[Node3D] = []
var guests: Array[Node3D] = []
var order_labels: Array[Label3D] = []
var orders: Array[Dictionary] = []
var hud: Label
var note: Label
var planning_panel: PanelContainer
var planning_list: VBoxContainer
var market_panel: PanelContainer
var market_list: VBoxContainer
var summary_panel: PanelContainer
var summary_text: Label
var renovation_box: VBoxContainer
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
var cat_node: Node3D
var cat_dialogue: DialogueBox

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
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
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
	_refresh_planning()
	story_bridge = load("res://scenes/story3d/story_bridge_3d.tscn").instantiate()
	add_child(story_bridge)
	_play_arrival.call_deferred()
	Sfx.ambience("street")

func _play_arrival() -> void:
	planning_panel.hide()
	await story_bridge.play_eligible(arrival_cutscenes)
	planning_panel.show()

func _build_room() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("172038")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("e7d5b3")
	environment.environment = settings
	add_child(environment)
	var camera := Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 14.0
	camera.position = Vector3(4.5, 12, 15)
	camera.look_at(Vector3(0, 0, -0.5))
	camera.current = true
	_box(self, Vector3(0, -0.24, 0), Vector3(16, 0.4, 12), "394a50")
	for x in range(16):
		for z in range(11):
			_box(self, Vector3(x - 7.5, -0.02, z - 5.0), Vector3(0.96, 0.05, 0.96), "819796" if (x + z) % 2 else "c09473")
	_box(self, Vector3(0, 1.5, -5.5), Vector3(16, 3, 0.3), "c09473", true)
	_box(self, Vector3(0, 0.4, -5.32), Vector3(16, 0.8, 0.1), "577277")
	_box(self, Vector3(0, 3.04, -5.30), Vector3(9, 0.65, 0.14), "7a4841")
	_label(self, "HẢI SẢN XÓM ĐÈN", Vector3(0, 3.04, -5.20), 52, "f2d98a")
	for n in range(16):
		var color := "577277" if n % 2 else "e7d5b3"
		_box(self, Vector3(n - 7.5, 2.55, -4.3), Vector3(0.98, 0.09, 1.65), color)
		_box(self, Vector3(n - 7.5, 2.4, -3.48), Vector3(0.98, 0.24, 0.08), color)
	var decor_level := GameState.get_upgrade_level("decor")
	if decor_level > 0:
		for x in [-6.0, -3.0, 0.0, 3.0, 6.0]:
			_box(self, Vector3(x, 2.25, -3.35), Vector3(0.04, 0.40, 0.04), "402751")
			_box(self, Vector3(x, 2.02, -3.35), Vector3(0.33, 0.28, 0.33), "de9e41")
	if decor_level > 1:
		for x in [-6.7, 6.7]:
			_box(self, Vector3(x, 0.36, 4.3), Vector3(0.6, 0.72, 0.6), "7a4841")
			_box(self, Vector3(x, 0.87, 4.3), Vector3(0.85, 0.45, 0.85), "468232")
	_box(self, Vector3(0, -0.05, 5.6), Vector3(16, 0.2, 0.3), "e7d5b3", true)
	_box(self, Vector3(0, -0.2, 6.2), Vector3(16, 0.2, 1), "202e37")
	var table_count := clampi(int(GameState.get_upgrade_value(seats_upgrade)), 1, TABLES.size()) if seats_upgrade else 4
	for i in range(table_count):
		var p: Vector3 = TABLES[i]
		_box(self, p + Vector3(0, 0.8, 0), Vector3(1.5, 0.12, 1.2), "c7cfcc", true)
		for x in [-0.57, 0.57]:
			for z in [-0.4, 0.4]:
				_box(self, p + Vector3(x, 0.4, z), Vector3(0.07, 0.8, 0.07), "577277")
		for side in [-1.0, 1.0]:
			_box(self, p + Vector3(side * 1.02, 0.46, 0), Vector3(0.55, 0.12, 0.55), "3c5e8b" if side < 0 else "a53030")
		var guest := Node3D.new()
		add_child(guest)
		guest.position = p + Vector3(0, 0, 1.15)
		guests.append(guest)
		_make_person(guest, "7a4841" if i == 0 else "468232")
		guest.visible = false
		order_labels.append(_label(self, "", p + Vector3(0, 2.25, 0.6), 18, "f2d98a"))
		orders.append({})
	_box(self, Vector3(5.1, 0.7, -2.8), Vector3(2.8, 1.3, 1.25), "577277", true)
	_box(self, Vector3(5.1, 1.42, -2.8), Vector3(3, 0.12, 1.4), "c7cfcc")
	_box(self, Vector3(4.7, 1.52, -2.8), Vector3(1.2, 0.1, 0.65), "394a50")
	for n in range(6):
		_box(self, Vector3(4.22 + n * 0.18, 1.6, -2.8), Vector3(0.06, 0.05, 0.48), "de9e41")
	_box(self, Vector3(1.4, 0.7, 2.5), Vector3(1.2, 1.3, 0.1), "884b2b", true)
	_label(self, "BẾP   E\nBẢNG MÓN", Vector3(1.4, 0.8, 2.57), 16, "e7d5b3")
	# Cô Năm keeps her grocery counter separate from the kitchen.
	_box(self, Vector3(5.9, 0.75, 2.55), Vector3(2.5, 1.0, 0.8), "468232", true)
	_box(self, Vector3(5.9, 1.3, 2.55), Vector3(2.7, 0.12, 1.0), "e7d5b3")
	_label(self, "TẠP HOÁ CÔ NĂM", Vector3(5.9, 2.4, 2.1), 24, "f2d98a")
	var co_nam := Node3D.new()
	add_child(co_nam)
	co_nam.position = Vector3(5.9, 0, 1.7)
	_make_person(co_nam, "468232")
	_box(co_nam, Vector3(0, 1.94, -0.18), Vector3(0.30, 0.17, 0.24), "202e37")
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
	body = Node3D.new()
	player.add_child(body)
	_make_person(body, "e7d5b3", true)

func _make_person(parent: Node3D, shirt: String, rin := false) -> void:
	_box(parent, Vector3(0, 1.05, 0), Vector3(0.46, 0.65, 0.33), shirt)
	_box(parent, Vector3(0, 1.72, 0), Vector3(0.39, 0.42, 0.37), "ad7757")
	_box(parent, Vector3(0, 1.97, 0), Vector3(0.48, 0.14, 0.44), "202e37" if rin else "394a50")
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		parent.add_child(leg)
		leg.position = Vector3(side * 0.13, 0.66, 0)
		_box(leg, Vector3(0, -0.27, 0), Vector3(0.15, 0.55, 0.18), "ad7757")
		var arm := Node3D.new()
		parent.add_child(arm)
		arm.position = Vector3(side * 0.31, 1.35, 0)
		_box(arm, Vector3(0, -0.3, 0), Vector3(0.12, 0.61, 0.14), "ad7757")
		if rin:
			legs.append(leg)
			arms.append(arm)
	if rin:
		for x in [-0.11, 0.11]:
			_box(parent, Vector3(x, 1.76, 0.19), Vector3(0.17, 0.11, 0.035), "202e37")

func _build_cat() -> void:
	cat_node = Node3D.new()
	add_child(cat_node)
	cat_node.position = Vector3(3.3, 0, 0.6)
	_box(cat_node, Vector3(0, 0.22, 0), Vector3(0.72, 0.42, 0.48), "de9e41")
	_box(cat_node, Vector3(-0.32, 0.34, 0.16), Vector3(0.38, 0.36, 0.36), "e8c170")
	for x in [-0.44, -0.19]:
		_box(cat_node, Vector3(x, 0.58, 0.16), Vector3(0.12, 0.22, 0.12), "de9e41")
	_box(cat_node, Vector3(0.48, 0.41, -0.12), Vector3(0.10, 0.57, 0.12), "de9e41")

func _sync_staff() -> void:
	for worker in staff_workers:
		var table: int = worker["table"]
		if table >= 0 and not orders[table].is_empty():
			orders[table]["staff_claimed"] = false
		(worker["node"] as Node3D).queue_free()
	staff_workers.clear()
	for person in staff_roster.hired():
		var node := Node3D.new()
		add_child(node)
		node.position = Vector3(3.3 + staff_workers.size() * 0.7, 0, -0.5)
		_make_person(node, person.body_color.to_html(false))
		staff_workers.append({"data": person, "node": node, "table": -1})
	if shift_running:
		_dispatch_ready()

func _dispatch_ready() -> void:
	for i in range(orders.size()):
		if orders[i].is_empty() or not bool(orders[i].get("cooked", false)) or bool(orders[i].get("staff_claimed", false)) or carrying_table == i:
			continue
		for worker in staff_workers:
			if int(worker["table"]) == -1:
				worker["table"] = i
				orders[i]["staff_claimed"] = true
				break
		if not bool(orders[i].get("staff_claimed", false)) and carrying_table < 0:
			carrying_table = i
			_show_note("Đem %s ra bàn %d." % [orders[i]["dish"].display_name, i + 1])

func _move_staff(delta: float) -> void:
	for worker in staff_workers:
		var node: Node3D = worker["node"]
		var table: int = worker["table"]
		if table < 0:
			var home := Vector3(3.3 + staff_workers.find(worker) * 0.7, 0, -0.5)
			node.position = node.position.move_toward(home, delta * 2.5)
			continue
		if orders[table].is_empty():
			worker["table"] = -1
			continue
		var target: Vector3 = TABLES[table] + Vector3(0, 0, 1.2)
		var person: StaffData = worker["data"]
		node.position = node.position.move_toward(target, delta * person.walk_speed / 23.0)
		if node.position.distance_to(target) < 0.05:
			worker["table"] = -1
			_serve(table)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(12, 9)
	hud.add_theme_font_size_override("font_size", 13)
	hud.add_theme_color_override("font_color", Color("f2d98a"))
	layer.add_child(hud)
	note = Label.new()
	note.position = Vector2(12, 316)
	note.add_theme_color_override("font_color", Color("e7d5b3"))
	layer.add_child(note)
	planning_panel = PanelContainer.new()
	planning_panel.position = Vector2(132, 32)
	planning_panel.custom_minimum_size = Vector2(375, 290)
	layer.add_child(planning_panel)
	var scroll := ScrollContainer.new()
	planning_panel.add_child(scroll)
	planning_list = VBoxContainer.new()
	planning_list.custom_minimum_size.x = 350
	scroll.add_child(planning_list)
	market_panel = PanelContainer.new()
	market_panel.position = Vector2(170, 65)
	market_panel.custom_minimum_size = Vector2(300, 225)
	layer.add_child(market_panel)
	market_list = VBoxContainer.new()
	market_panel.add_child(market_list)
	market_panel.hide()
	summary_panel = PanelContainer.new()
	summary_panel.position = Vector2(135, 43)
	summary_panel.custom_minimum_size = Vector2(370, 270)
	layer.add_child(summary_panel)
	var summary_box := VBoxContainer.new()
	summary_panel.add_child(summary_box)
	summary_text = Label.new()
	summary_box.add_child(summary_text)
	renovation_box = VBoxContainer.new()
	summary_box.add_child(renovation_box)
	var sail := Button.new()
	sail.text = "Ra khơi →"
	sail.pressed.connect(_sail)
	summary_box.add_child(sail)
	summary_panel.hide()
	add_child(load("res://scenes/ui/pause_menu.tscn").instantiate())
	add_child(load("res://scenes/ui/phone_app.tscn").instantiate())
	_update_hud()
	_refresh_market()
	_refresh_renovations()

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
	close.pressed.connect(func() -> void: market_panel.hide())
	market_list.add_child(close)

func _buy_market(dish: DishData, bulk: bool) -> void:
	var cost := dish.buy_cost(bulk)
	if not GameState.spend_money(cost):
		_show_note("Không đủ tiền mua %s." % dish.display_name)
		return
	market_stock.add(dish, dish.buy_units(bulk))
	market_spent += cost
	Sfx.play("bag")
	_refresh_market()
	_update_hud()

func _refresh_renovations() -> void:
	for old in renovation_box.get_children():
		old.queue_free()
	var title := Label.new()
	title.text = "SỬA QUÁN • NÂNG CẤP CHO CA SAU"
	renovation_box.add_child(title)
	for upgrade in [kitchen_upgrade, fridge_upgrade, seats_upgrade, decor_upgrade]:
		if upgrade == null:
			continue
		var level := GameState.get_upgrade_level(upgrade.id)
		var cost: int = upgrade.next_cost(level)
		var buy := Button.new()
		buy.text = "%s  •  %s" % [upgrade.display_name, "Tối đa" if cost < 0 else "Mua %dk" % cost]
		buy.disabled = cost < 0 or GameState.money < cost
		buy.pressed.connect(_buy_upgrade.bind(upgrade))
		renovation_box.add_child(buy)

func _buy_upgrade(upgrade: UpgradeData) -> void:
	if GameState.buy_upgrade(upgrade):
		_show_note("Đã nâng cấp %s. Có hiệu lực từ ca sau." % upgrade.display_name)
		_refresh_renovations()
		_update_hud()

func _refresh_planning() -> void:
	for old in planning_list.get_children():
		old.queue_free()
	var title := Label.new()
	title.text = "LÊN THỰC ĐƠN  •  Kho: %d con  •  %d/%d món" % [GameState.storage.size(), plan.used_slots(), plan.slots]
	planning_list.add_child(title)
	var seen := false
	for dish in menu.dishes:
		if dish.ingredients.is_empty() or dish.kitchen_level > plan.kitchen_level or not DishBook.is_known(dish):
			continue
		if plan.get_portion_count(dish) == 0 and not KitchenLogic.can_cook(dish, GameState.storage):
			continue
		seen = true
		var row := HBoxContainer.new()
		planning_list.add_child(row)
		var add := Button.new()
		add.text = "+ %s (%d)" % [dish.display_name, plan.get_portion_count(dish)]
		add.disabled = not plan.can_add(dish, GameState.storage)
		add.pressed.connect(_add_portion.bind(dish))
		row.add_child(add)
		var remove := Button.new()
		remove.text = "−"
		remove.disabled = plan.get_portion_count(dish) == 0
		remove.pressed.connect(_remove_portion.bind(dish))
		row.add_child(remove)
	if not seen:
		var empty := Label.new()
		empty.text = "Chưa có cá trong kho. Ra biển bắt cá trước."
		planning_list.add_child(empty)
	var auto := Button.new()
	auto.text = "Tự xếp từ kho"
	auto.pressed.connect(func() -> void:
		plan.auto_fill(menu.dishes, GameState.storage)
		_refresh_planning())
	planning_list.add_child(auto)
	var open := Button.new()
	open.text = "Mở quán"
	open.disabled = plan.is_sold_out()
	open.pressed.connect(_open_shift)
	planning_list.add_child(open)
	if plan.is_sold_out():
		var skip := Button.new()
		skip.text = "Không có hàng • ra khơi"
		skip.pressed.connect(_sail_without_shift)
		planning_list.add_child(skip)

func _add_portion(dish: DishData) -> void:
	plan.add_portion(dish, GameState.storage)
	_refresh_planning()

func _remove_portion(dish: DishData) -> void:
	plan.remove_portion(dish, GameState.storage)
	_refresh_planning()

func _open_shift() -> void:
	planning_panel.hide()
	shift_running = true
	seconds_left = SHIFT_SECONDS
	spawn_clock = tuning.first_spawn_delay
	_show_note("Quán mở cửa! WASD đi, E ở bếp để nấu, E gần bàn để bưng món.")
	_update_hud()

func _physics_process(delta: float) -> void:
	if get_tree().paused or not shift_running:
		return
	_move_staff(delta)
	if market_panel.visible or cooking_overlay.is_running():
		return
	var axes := Input.get_vector("turn_left", "turn_right", "throttle_forward", "throttle_back")
	var rin_scale := 1.0 / maxf(Engine.time_scale, 0.001) if WavePower.rin_unslowed else 1.0
	player.velocity = Vector3(axes.x, 0, axes.y) * 4.2 * rin_scale
	player.move_and_slide()
	step_clock += delta * rin_scale
	if player.velocity.length() > 0.1:
		player.rotation.y = lerp_angle(player.rotation.y, atan2(axes.x, axes.y), minf(delta * 10.0, 1.0))
	var beat := floorf(step_clock * 8.0) / 8.0
	body.position.y = absf(sin(beat * 11.0)) * 0.04 * axes.length()
	for i in range(2):
		var side := -1.0 if i == 0 else 1.0
		legs[i].rotation.x = side * sin(beat * 11.0) * 0.4 * axes.length()
		arms[i].rotation.x = -side * sin(beat * 11.0) * 0.33 * axes.length()
	for i in range(guests.size()):
		guests[i].position.y = sin(floorf(step_clock * 5.0 + float(i))) * 0.025

func _process(delta: float) -> void:
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
	spawn_clock -= delta
	if spawn_clock <= 0.0 and seconds_left > 0.0:
		_spawn_order()
		spawn_clock = _next_spawn_interval()
	for i in range(orders.size()):
		if orders[i].is_empty():
			continue
		orders[i]["patience"] = float(orders[i]["patience"]) - delta
		if float(orders[i]["patience"]) <= 0.0:
			_lose_order(i)
	if seconds_left <= 0.0 and orders.all(func(order: Dictionary) -> bool: return order.is_empty()):
		_end_shift()
	_update_hud()

func _spawn_order() -> void:
	var available := plan.available_dishes()
	for dish in menu.dishes:
		if dish.is_market_dish() and dish.unlock_day <= GameState.day and market_stock.portions(dish) > 0:
			available.append(dish)
	if available.is_empty() and regular_queue.is_empty():
		return
	var free: Array[int] = []
	for i in range(orders.size()):
		if orders[i].is_empty():
			free.append(i)
	if free.is_empty():
		return
	var table := free[rng.randi_range(0, free.size() - 1)]
	if not regular_queue.is_empty():
		var visit: Dictionary = regular_queue.pop_front()
		var regular_dish: DishData = visit["dish"]
		var reserved: Array[InventoryItem] = [visit["item"]]
		orders[table] = {"dish": regular_dish, "items": reserved, "freshness": 100.0,
			"patience": 38.0 * tuning.regular_patience_scale, "visit": visit,
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
	orders[table] = {"dish": dish, "items": items, "freshness": freshness, "patience": patience,
		"visit": {}, "cooked": false, "staff_claimed": false, "multiplier": 1.0, "rich": rich}
	guests[table].visible = true
	order_labels[table].text = ("KHÁCH SANG\n" if rich else "") + dish.display_name
	_show_note("Bàn %d gọi %s." % [table + 1, dish.display_name])

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or get_tree().paused:
		return
	if OS.is_debug_build() and key.physical_keycode == KEY_F1 and planning_panel.visible and not shift_running:
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
	if not shift_running:
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
		seconds_left = 0.0
		_show_note("Đóng cửa; phục vụ nốt khách đang ngồi.")
		get_viewport().set_input_as_handled()

func _debug_fill_fish() -> void:
	if fish_catalog == null:
		return
	for fish in fish_catalog.fish:
		GameState.storage.append(InventoryItem.new(fish, 1.0))
	_refresh_planning()
	_show_note("[debug] Đã thêm mỗi loại cá vào kho.")

func _debug_fill_drinks() -> void:
	if menu == null:
		return
	for dish in menu.dishes:
		if dish.instant_serve:
			var units := dish.buy_units(dish.has_bulk())
			market_stock.add(dish, units)
			_show_note("[debug] +%d %s %s vào tủ lạnh" % [units, dish.unit_name, dish.display_name])

func _interact() -> void:
	if cat_node and player.position.distance_to(cat_node.position) < 1.8:
		var dialogue := DialogueLibrary.pick(CAT_DIALOGUES) as Dialogue
		if dialogue:
			cat_dialogue.play(dialogue)
		else:
			_show_note("%s: Meo~" % CutsceneScript.pet_name())
		return
	if player.position.distance_to(Vector3(5.9, 0, 2.55)) < 2.8:
		_refresh_market()
		market_panel.show()
		return
	if carrying_table >= 0:
		var table := carrying_table
		if player.position.distance_to(TABLES[table] + Vector3(0, 0, 1.2)) < 2.0:
			_serve(table)
		else:
			_show_note("Đem món tới bàn %d." % (table + 1))
		return
	if player.position.distance_to(Vector3(5.1, 0, -2.8)) < 2.9:
		if cooking_table >= 0:
			_show_note("Bảo đang nấu...")
			return
		for i in range(orders.size()):
			if not orders[i].is_empty() and not bool(orders[i].get("cooked", false)):
				cooking_table = i
				cooking_overlay.start(orders[i]["dish"])
				_show_note("Bảo đang làm %s cho bàn %d." % [orders[i]["dish"].display_name, i + 1])
				return
		_show_note("Chưa có khách gọi món.")

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
	if order.is_empty():
		if carrying_table == table:
			carrying_table = -1
		return
	var dish: DishData = order["dish"]
	var ingredients: Array[InventoryItem] = order["items"]
	var visit: Dictionary = order.get("visit", {})
	var plate := DishShelf.Plate.new(dish, ingredients, float(order["multiplier"]), visit)
	var variety := MenuPlan.variety_multiplier(plan.variety_count(), [0.8, 0.8, 0.9, 1.0, 1.05, 1.1])
	var price := TableBill.plate_price(plate, variety, 1.0)
	if bool(order.get("rich", false)):
		price = roundi(float(price) * tuning.rich_price_scale)
	if dish.is_market_dish():
		price = roundi(float(price) * KitchenLogic.freshness_multiplier(float(order["freshness"])))
	var tip := roundi(price * (0.1 + staff_roster.tip_bonus())) if visit.is_empty() and float(order["patience"]) > 15.0 else 0
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
	guests[table].visible = false
	order_labels[table].text = ""
	_show_note("%s: +%dk. Cảm ơn khách bàn %d!" % [dish.display_name, price + tip, table + 1])
	Sfx.play("coins")
	_dispatch_ready()

func _lose_order(table: int) -> void:
	var already_cooked := table == carrying_table
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
	shift_running = false
	shift_over = true
	DayClock.set_progress(1.0, DayClock.shop_open_hour, DayClock.shop_close_hour)
	var leftover := plan.total_portions()
	var limited_variety := plan.used_slots() < 2
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
	_refresh_renovations()
	_update_hud()

func _sail_without_shift() -> void:
	plan.clear(GameState.storage)
	for visit in regular_visits:
		FishOrders.release(visit)
	FishOrders.expire_after_shift(fish_catalog)
	_sail()

func _sail() -> void:
	if sailing or (not shift_over and not plan.is_sold_out()):
		return
	sailing = true
	if shift_over:
		await story_bridge.play_eligible(after_shift_cutscenes)
	var freshness_loss := float(GameState.get_upgrade_value(fridge_upgrade)) if fridge_upgrade else 35.0
	GameState.advance_day(freshness_loss)
	FishOrders.roll_new_order(rng, fish_catalog)
	GameState.resume_at = "sea"
	SceneRouter.go_to(SEA_SCENE)

func _show_note(words: String) -> void:
	note.text = words
	note_clock = 4.0

func _update_hud() -> void:
	var state := "LÊN THỰC ĐƠN" if not shift_running and not shift_over else ("ĐÃ ĐÓNG CỬA" if shift_over else "ĐANG BÁN")
	hud.text = "XÓM ĐÈN • NGÀY %d • %s   |   %s   |   %dk\nWASD: đi  E: nấu / phục vụ / chợ Cô Năm  T: đóng sớm  J: điện thoại" % [GameState.day, DayClock.get_time_text(), state, GameState.money]
