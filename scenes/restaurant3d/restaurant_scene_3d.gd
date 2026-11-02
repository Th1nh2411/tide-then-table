class_name RestaurantScene3D
extends Node3D
## Xóm Đèn restaurant in 3D: fixed menu, Bảo cooks, Rin carries, beer at the keg.
## Orchestrator: room -> RestaurantRoomBuilder3D, overlay -> RestaurantPanels3D,
## Bảo -> RestaurantCrew3D, shift
## clock -> RestaurantShift3D, orders -> RestaurantService3D, E -> RestaurantInteract3D,
## Rin's walking -> RinMover3D, the street ends -> StreetEnds3D, omen props -> RestaurantOmens3D.
## The underscore wrappers stay: tests and the bot call them.

const SHIFT_SECONDS := RestaurantShift3D.SHIFT_SECONDS
# Layout lives in RestaurantLayout3D; aliases keep the old RestaurantScene3D.X names working.
const TABLES := RestaurantLayout3D.TABLES
const ROOM_X := RestaurantLayout3D.ROOM_X
const BACK_Z := RestaurantLayout3D.BACK_Z
const WALL_H := RestaurantLayout3D.WALL_H
const FRONT_Z := RestaurantLayout3D.FRONT_Z
const ROAD_DEPTH := RestaurantLayout3D.ROAD_DEPTH
const COUNTER_POSITION := RestaurantLayout3D.COUNTER_POSITION
const BOARD_POSITION := RestaurantLayout3D.BOARD_POSITION
const PASS_POSITION := RestaurantLayout3D.PASS_POSITION
const GRILL_POSITION := RestaurantLayout3D.GRILL_POSITION
const BEER_POSITION := RestaurantLayout3D.BEER_POSITION
const MEAL_SECONDS := 5.0

## Opens the shift as soon as Rin arrives (tests that drive the shift turn it off).
@export var auto_open := true

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
var player: CharacterBody3D
var body: PersonRig3D
var guests: Array[Node3D] = []
var order_labels: Array[Label3D] = []
var orders: Array[Dictionary] = []
var hud: RestaurantHud3D
var panels: RestaurantPanels3D
var crew: RestaurantCrew3D
var service: RestaurantService3D
var mover: RinMover3D
var interaction: RestaurantInteract3D
var shift: RestaurantShift3D
var shift_running := false
var shift_over := false
var seconds_left := SHIFT_SECONDS
var spawn_clock := 2.0
var carrying_table := -1
var served := 0
var lost := 0
## What the guests paid this shift: no longer money to spend, only counted
## for the ending's run card (GameState.day_history).
var earned := 0
var step_clock := 0.0
var sailing := false
var rng := RandomNumberGenerator.new()
var tuning: ServiceTuning
var demo_camera: Camera3D
var dirty_tables: Array[bool] = []
var table_plates: Array[Node3D] = []
var ready_plates: Array[Node3D] = []
var bao_model: PersonRig3D
var bao_label: Label3D
var goal_pulse: TargetPulse3D

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
	RestaurantRoomBuilder3D.build(self)
	var traffic := CustomerTraffic3D.new()
	traffic.host = self
	add_child(traffic)
	RestaurantSetup3D.build_ui(self)
	RestaurantSetup3D.open_day(self)
	StreetEnds3D.build(self)
	RestaurantOmens3D.build(self)
	RamGuest3D.attach(self)  # rằm only: anh Út and his ginger tea
	_play_arrival.call_deferred()
	Sfx.ambience("street")
	Sfx.bed("street")

## No cutscenes in the horror build: the shift simply opens when Rin arrives.
func _play_arrival() -> void:
	if auto_open and not shift_over:
		_open_shift()

# --- Bảo ---
func _tick_bao(delta: float) -> void:
	crew.tick_bao(delta)

## Nothing modal is left in the restaurant (no menu, market or cooking overlay).
func modal_open() -> bool:
	return false

# --- Frame loop ---
func _open_shift() -> void:
	shift.open_shift()

func _physics_process(delta: float) -> void:
	if get_tree().paused or mover.focus_lost:
		mover.stop(delta)
		return
	mover.move(delta)

func _process(delta: float) -> void:
	panels.refresh_prompt(demo_camera, get_tree().paused or mover.focus_lost or modal_open())
	# The next goal pulses softly instead of text over tables and stations.
	if goal_pulse:
		goal_pulse.set_target(null if modal_open() else RestaurantGoal3D.target(self))
	panels.tick(delta)
	if not shift_running or get_tree().paused:
		return
	shift.tick(delta)

# --- Orders ---
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or get_tree().paused:
		return
	if key.physical_keycode == KEY_E:
		_interact()
		get_viewport().set_input_as_handled()
	elif key.physical_keycode == KEY_T:
		_close_early()
		get_viewport().set_input_as_handled()

func _close_early() -> void:
	shift.close_early()

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

func _walk_home() -> void:
	shift.walk_home()

func _show_note(words: String) -> void:
	panels.say(words)

func _panel_style() -> StyleBoxFlat:
	return RestaurantPanels3D.panel_style()

func _ui_theme() -> Theme:
	return RestaurantPanels3D.ui_theme()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if mover:
			mover.on_focus(what == NOTIFICATION_APPLICATION_FOCUS_IN)
