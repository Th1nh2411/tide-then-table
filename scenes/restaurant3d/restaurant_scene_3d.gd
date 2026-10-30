class_name RestaurantScene3D
extends Node3D
## Xóm Đèn restaurant in 3D. Uses the saved inventory, real dishes and shift ledger.
## Orchestrator: room -> RestaurantRoomBuilder3D, overlay -> RestaurantPanels3D,
## Bảo + helpers -> RestaurantCrew3D, debug keys -> RestaurantDebug3D.

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
# Layout lives in RestaurantLayout3D; aliases keep the old RestaurantScene3D.X names working.
const TABLES := RestaurantLayout3D.TABLES
const ROOM_X := RestaurantLayout3D.ROOM_X
const BACK_Z := RestaurantLayout3D.BACK_Z
const WALL_H := RestaurantLayout3D.WALL_H
const FRONT_Z := RestaurantLayout3D.FRONT_Z
const ROAD_DEPTH := RestaurantLayout3D.ROAD_DEPTH
const COUNTER_POSITION := RestaurantLayout3D.COUNTER_POSITION
const DECOR_LANTERNS := RestaurantLayout3D.DECOR_LANTERNS
const DECOR_PLANTERS := RestaurantLayout3D.DECOR_PLANTERS
const PLANTER_Z := RestaurantLayout3D.PLANTER_Z
const BOARD_POSITION := RestaurantLayout3D.BOARD_POSITION
const PASS_POSITION := RestaurantLayout3D.PASS_POSITION
const GRILL_POSITION := RestaurantLayout3D.GRILL_POSITION
const BEER_POSITION := RestaurantLayout3D.BEER_POSITION
const MEAL_SECONDS := 5.0

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
var planning_panel: MenuPanel3D
var panels: RestaurantPanels3D
var crew: RestaurantCrew3D
var service: RestaurantService3D
var debug_keys: RestaurantDebug3D
var story_bridge
var cooking_overlay: CookingOverlay
var staff_workers: Array[Dictionary]:
	get: return crew.workers
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
var sailing := false
var wages_paid := 0
var wave_power: WavePower
var rng := RandomNumberGenerator.new()
var tuning: ServiceTuning
var cat_node: PersonRig3D
var cat_dialogue: DialogueBox
var opening_variety: int = 0
var demo_camera: Camera3D
var _focus_lost: bool = false
var _dash_left: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_direction := Vector3.ZERO
var _movement_time_scale := 1.0
var dirty_tables: Array[bool] = []
var table_plates: Array[Node3D] = []
var ready_plates: Array[Node3D] = []
var bao_model: PersonRig3D
var bao_label: Label3D
## This shift's events (RestaurantService3D fills it; new one at shift start).
var shift_log := ShiftLog.new()
## Set at closing by RestaurantGoals3D.finish_shift (challenges, achievements).
var shift_results: Dictionary = {}
var goals: RestaurantGoals3D
var goal_pulse: TargetPulse3D
## Xóm Đèn Review posts, followers and the weekly ranking at closing.
var social: RestaurantSocial3D

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
	return rng.randf_range(tuning.min_spawn_interval, tuning.max_spawn_interval) * decor_scale * rating_scale \
		* RestaurantSocial3D.spawn_scale()

func _ready() -> void:
	goal_pulse = TargetPulse3D.new()
	add_child(goal_pulse)
	rng.randomize()
	tuning = _pick_tuning()
	panels = RestaurantPanels3D.new(self)
	crew = RestaurantCrew3D.new(self)
	service = RestaurantService3D.new(self)
	debug_keys = RestaurantDebug3D.new(self)
	market_stock = MarketStock.new(GameState.pantry)
	staff_roster = StaffRoster.new(staff_catalog, GameState.staff)
	if GameState.day >= staff_catalog.unlock_day:
		staff_roster.arrivals(GameState.day)
	GameState.staff_changed.connect(_sync_staff)
	staff_roster.changed.connect(_sync_staff)
	regular_visits = FishOrders.reserve_for_shift(menu)
	regular_queue = regular_visits.duplicate()
	RestaurantRoomBuilder3D.build(self)
	var traffic := CustomerTraffic3D.new()
	traffic.host = self
	add_child(traffic)
	if PetCat.is_present():
		cat_node = RestaurantRoomBuilder3D.build_cat(self)
	_sync_staff()
	_build_ui()
	cat_dialogue = DialogueBox.new()
	add_child(cat_dialogue)
	var tracker := QuestTracker.new()
	tracker.catalog = fish_catalog
	tracker.origin = Vector2(6, 56)
	tracker.hidden_when = func() -> bool: return modal_open() or panels.summary_visible() \
		or (story_bridge != null and story_bridge.playing)
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
	($WorldMenuBoard as WorldMenuBoard3D).bind(plan, menu)
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

func _build_ui() -> void:
	panels.build()
	planning_panel = panels.planning
	hud = RestaurantHud3D.new()
	add_child(hud)
	hud.setup(self, _ui_theme(), _panel_style())
	hud.menu_requested.connect(_toggle_planning)
	hud.renovate_requested.connect(_open_renovation)
	hud.close_requested.connect(_close_early)
	hud.sail_requested.connect(_sail)
	goals = RestaurantGoals3D.new(self)
	goals.build()
	social = RestaurantSocial3D.new(self)
	social.build()
	add_child(load("res://scenes/ui/pause_menu.tscn").instantiate())
	add_child(load("res://scenes/ui/phone_app.tscn").instantiate())
	bag.build_fridge(self)
	panels.refresh_market()

# --- Crew (Bảo + helpers) ---
func _sync_staff() -> void:
	crew.sync_staff()

func _dispatch_ready() -> void:
	crew.dispatch_ready()

func _move_staff(delta: float) -> void:
	crew.move_staff(delta)

func _tick_bao(delta: float) -> void:
	crew.tick_bao(delta)

# --- Market / renovation ---
func _open_market() -> void:
	panels.open_market()

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
	panels.refresh_market()

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
		_show_note("Đã thuê thêm mặt bằng và mở bàn mới." if renovation and renovation.last_seat_change else "Sửa quán xong!")

func _buy_upgrade(upgrade: UpgradeData) -> void:
	if GameState.buy_upgrade(upgrade):
		_show_note("Đã nâng cấp %s. Có hiệu lực từ ca sau." % upgrade.display_name)

func is_renovating() -> bool:
	return renovation != null and renovation.layer != null and renovation.layer.visible

## Any full panel on screen: Rin freezes, E hints and other buttons step aside.
## (The end-of-shift summary is a note, not a modal: Rin still walks and the evening buttons stay.)
func modal_open() -> bool:
	return planning_panel.visible or panels.market_panel.visible \
		or is_renovating() or cooking_overlay.is_running()

# --- Frame loop ---
func _open_shift() -> void:
	if shift_running or shift_over or not _has_stock():
		return
	opening_variety = plan.variety_count()
	planning_panel.hide()
	shift_running = true
	seconds_left = SHIFT_SECONDS
	spawn_clock = tuning.first_spawn_delay
	goals.start_shift()
	_show_note("Bảo nấu món thường. E ở bàn nhận món; nướng và rót bia do Rin làm. T: đóng sớm.")

func _physics_process(delta: float) -> void:
	if get_tree().paused or _focus_lost:
		player.velocity = Vector3.ZERO
		body.drive_ground_motion(Vector3.ZERO,delta,false)
		return
	if shift_running:
		_move_staff(delta)
	if modal_open():
		player.velocity = Vector3.ZERO
		body.drive_ground_motion(Vector3.ZERO,delta,false)
		return
	var axes := Input.get_vector("turn_left", "turn_right", "throttle_forward", "throttle_back")
	var rin_scale := 1.0 / maxf(Engine.time_scale, 0.001) if WavePower.rin_unslowed else 1.0
	# Keep acceleration and momentum in real-time units when Wave Power slows the world.
	player.velocity *= rin_scale / _movement_time_scale
	_movement_time_scale = rin_scale
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
		var speed := 2.3 if carrying_table >= 0 else 3.0
		var desired := direction * speed * rin_scale
		# Dash ends at walking/running speed, rather than coasting several extra metres.
		player.velocity = player.velocity.limit_length(speed*rin_scale)
		player.velocity = player.velocity.move_toward(desired,(20.0 if axes.length_squared() > .01 else 28.0)*delta*rin_scale*rin_scale)
	var before := player.global_position
	player.move_and_slide()
	var moved := player.global_position-before
	step_clock += delta * rin_scale
	if moved.length_squared() > 0.000001:
		player.rotation.y = lerp_angle(player.rotation.y, atan2(moved.x, moved.z), 1.0-exp(-16.0*delta*rin_scale))
	body.set_carrying(carrying_table >= 0)
	body.drive_ground_motion(moved,delta,false)

func _process(delta: float) -> void:
	panels.refresh_prompt(demo_camera, get_tree().paused or _focus_lost or modal_open())
	# The next goal pulses softly instead of text over tables and stations.
	if goal_pulse:
		goal_pulse.set_target(null if modal_open() else RestaurantGoal3D.target(self))
	if cat_node:
		cat_node.rotation.y = sin(Time.get_ticks_msec() / 650.0) * 0.06
	panels.tick(delta)
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

# --- Orders ---
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or get_tree().paused:
		return
	if debug_keys.handle(key):
		get_viewport().set_input_as_handled()
		return
	if panels.market_panel.visible:
		if key.physical_keycode == KEY_ESCAPE or key.physical_keycode == KEY_E:
			panels.market_panel.hide()
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

func _toggle_planning() -> void:
	if shift_running or shift_over:
		return
	if planning_panel.visible:
		planning_panel.close()
	else:
		panels.market_panel.hide()
		planning_panel.open()

func _interact() -> void:
	if planning_panel.visible and player.position.distance_to(BOARD_POSITION) < 2.2:
		_toggle_planning()
		return
	if modal_open():
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

# --- End of shift / leaving ---
# --- Orders (rules in RestaurantService3D) ---
func _spawn_order() -> void:
	service.spawn_order()

func _serve(table: int) -> void:
	service.serve(table)

func _finish_meal(table: int) -> void:
	service.finish_meal(table)

func _lose_order(table: int) -> void:
	service.lose_order(table)

func _pickup_ready() -> bool:
	return service.pickup_ready()

func _clean_table(table: int) -> void:
	service.clean_table(table)

func _end_shift() -> void:
	service.end_shift()

func _sync_food_visuals() -> void:
	service.sync_food_visuals()

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
	panels.say(words)

func _has_stock() -> bool:
	if not plan.is_sold_out() or not regular_queue.is_empty():
		return true
	for dish: DishData in menu.dishes:
		if dish.is_market_dish() and dish.unlock_day <= GameState.day and market_stock.portions(dish) > 0:
			return true
	return false

func _panel_style() -> StyleBoxFlat:
	return RestaurantPanels3D.panel_style()

func _ui_theme() -> Theme:
	return RestaurantPanels3D.ui_theme()

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
