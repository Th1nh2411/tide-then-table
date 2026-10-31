class_name RestaurantScene3D
extends Node3D
## Xóm Đèn restaurant in 3D. Uses the saved inventory, real dishes and shift ledger.
## Orchestrator: room -> RestaurantRoomBuilder3D, overlay -> RestaurantPanels3D,
## Bảo + helpers -> RestaurantCrew3D, debug keys -> RestaurantDebug3D, shift
## clock -> RestaurantShift3D, orders -> RestaurantService3D, E -> RestaurantInteract3D,
## Rin's walking -> RinMover3D, market / renovation -> RestaurantShop3D.
## The underscore wrappers stay: tests and the bot call them.

const SEA_SCENE := RestaurantShift3D.SEA_SCENE
const SHIFT_SECONDS := RestaurantShift3D.SHIFT_SECONDS
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

## Rin's ground speeds (m/s). Near the Walk clip's own pace (~1.3) so steps
## match the ground; above ~2.25 the Run clip takes over (running, roll).
@export var walk_speed: float = 1.8
@export var carry_speed: float = 1.6
## Shift = run: speed (m/s, carrying scales it the same), seconds of stamina,
## rest before it refills, seconds to refill, level that ends being winded.
@export var run_speed: float = 3.2
@export var stamina_seconds: float = 3.5
@export var stamina_rest_delay: float = 0.5
@export var stamina_refill_seconds: float = 2.5
@export var stamina_resume: float = 0.35
## Space = a quick roll: seconds, ground speed (m/s), cooldown.
@export var roll_seconds: float = 0.6
@export var roll_speed: float = 4.0
@export var roll_cooldown: float = 0.8
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
var mover: RinMover3D
var interaction: RestaurantInteract3D
var shift: RestaurantShift3D
var shop: RestaurantShop3D
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

func _next_spawn_interval() -> float:
	return shift.next_spawn_interval()

func _ready() -> void:
	goal_pulse = TargetPulse3D.new()
	add_child(goal_pulse)
	rng.randomize()
	tuning = RestaurantShift3D.pick_tuning()
	panels = RestaurantPanels3D.new(self)
	crew = RestaurantCrew3D.new(self)
	service = RestaurantService3D.new(self)
	mover = RinMover3D.new(self)
	interaction = RestaurantInteract3D.new(self)
	shift = RestaurantShift3D.new(self)
	shop = RestaurantShop3D.new(self)
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
	RestaurantSetup3D.build_ui(self)
	RestaurantSetup3D.build_tools(self)
	RestaurantSetup3D.open_planning(self)
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
	shop.buy_market(dish, bulk)

func _open_renovation() -> void:
	shop.open_renovation()

func _buy_upgrade(upgrade: UpgradeData) -> void:
	shop.buy_upgrade(upgrade)

func is_renovating() -> bool:
	return shop.is_renovating()

## Any full panel on screen: Rin freezes, E hints and other buttons step aside.
## (The end-of-shift summary is a note, not a modal: Rin still walks and the evening buttons stay.)
func modal_open() -> bool:
	return planning_panel.visible or panels.market_panel.visible \
		or is_renovating() or cooking_overlay.is_running()

# --- Frame loop ---
func _open_shift() -> void:
	shift.open_shift()

func _physics_process(delta: float) -> void:
	if get_tree().paused or mover.focus_lost:
		mover.stop(delta)
		return
	if shift_running:
		_move_staff(delta)
	if modal_open():
		mover.stop(delta)
		return
	mover.move(delta)

func _process(delta: float) -> void:
	panels.refresh_prompt(demo_camera, get_tree().paused or mover.focus_lost or modal_open())
	# The next goal pulses softly instead of text over tables and stations.
	if goal_pulse:
		goal_pulse.set_target(null if modal_open() else RestaurantGoal3D.target(self))
	if cat_node:
		cat_node.rotation.y = sin(Time.get_ticks_msec() / 650.0) * 0.06
	panels.tick(delta)
	if not shift_running or get_tree().paused:
		return
	shift.tick(delta)

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
	shift.close_early()

func _toggle_planning() -> void:
	if shift_running or shift_over:
		return
	if planning_panel.visible:
		planning_panel.close()
	else:
		panels.market_panel.hide()
		planning_panel.open()

func _interact() -> void:
	interaction.interact()

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
	shift.sail_without_shift()

func _sail() -> void:
	shift.sail()

func _show_note(words: String) -> void:
	panels.say(words)

func _has_stock() -> bool:
	return shift.has_stock()

func _panel_style() -> StyleBoxFlat:
	return RestaurantPanels3D.panel_style()

func _ui_theme() -> Theme:
	return RestaurantPanels3D.ui_theme()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if mover:
			mover.on_focus(what == NOTIFICATION_APPLICATION_FOCUS_IN)

func _apply_arrival_choice() -> void:
	if not GameState.story_flags.has(ArrivalCutscenes.HIRE_VY_FLAG):
		return
	GameState.story_flags.erase(ArrivalCutscenes.HIRE_VY_FLAG)
	var vy: StaffData = staff_roster.catalog.find("vy")
	if vy != null and staff_roster.hire(vy):
		_show_note("Vy vào làm từ hôm nay!")
