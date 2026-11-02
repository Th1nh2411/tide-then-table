class_name SeaScene3D
extends Node3D
## Night trip in 3D. Persistent fish, upgrades, oil, hull and clock use the
## existing game systems; only the presentation and boat controller are new.
## Orchestrator: world -> SeaWorldBuilder3D, places/events -> SeaPlaces3D,
## rod/net/hold -> SeaCatch3D, HUD/navigation -> SeaHud3D, steering ->
## SeaBoatMover3D, oil / unload / trip end -> SeaTrip3D, debug keys -> SeaDebug3D.

const REST_SCENE := SeaTrip3D.REST_SCENE
const ENDING_SCENE := SeaTrip3D.ENDING_SCENE
const FISHING_OVERLAY := SeaSetup3D.FISHING_OVERLAY
const ROD_UPGRADE := preload("res://data/upgrades/rod_upgrade.tres")
const LAMP_UPGRADE := preload("res://data/upgrades/lamp_upgrade.tres")
const CAMERA_OFFSET := Vector3(0,6.2,8.4)
const CAMERA_LOOK_AHEAD := 1.8
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
## Paddle strokes of a rowed boat (thúng); its phase also poses Rin and the paddle.
var row := RowStroke.new()
var paddle: Node3D
var impact_cooldown := 0.0
## Bounce, spin, rocking, shake and splash of collisions (SeaBoatMover3D calls it).
var impact := SeaBoatImpact3D.new()
var elapsed := 0.0
var fishing := false
var ending := false
var status := ""
var status_until := 0.0
var _said: Array[Array] = []
var rng := RandomNumberGenerator.new()
var overlay: CanvasLayer
var debug_cutscene_index := 0
var hud_view: SeaHudView3D
## Current Rin / NEO line (hidden; hud_view's speech strip shows it).
var message: Label
var bubble_spots: Array[BubbleSpot3D] = []
var submerged: Array[SubmergedRock3D] = []
var cinematic: CastCinematic3D
## Tests and bots can turn the cast scene off (E then opens the minigame at once).
var cast_cinematic_enabled := true
var rin_figure: Array[Node3D] = []
var _cast_played := false
var wake_marks: Array[MeshInstance3D] = []
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
	SeaWorldBuilder3D.build_environment(self)
	SeaWorldBuilder3D.build_world(self)
	SeaWorldBuilder3D.build_pois(self)
	SeaPlaces3D.build_night_events(self)
	SeaWorldBuilder3D.build_map_adapter(self)
	SeaWorldBuilder3D.build_boat(self)
	if weather:
		boat_lamp.spot_range *= weather.lamp_scale
	SeaHud3D.build_hud(self)
	SeaHud3D.build_shared_ui(self)
	SeaSetup3D.build_tools(self)
	SeaHud3D.build_navigation(self)
	DayClock.start_night()
	DailyTrend.ensure()
	var fog_tonight := Story.check_day()
	GameState.resume_at = "sea"
	SaveSystem.autosave("sea")
	Sfx.ambience("sea")
	_night_start_lines(fog_tonight)
	_update_hud()

func _night_start_lines(fog_tonight: bool) -> void:
	SeaTrip3D.night_start_lines(self, fog_tonight)

func _physics_process(delta: float) -> void:
	if ending or fishing or poi_busy or (hold_ui and hold_ui.visible) or (phone_app and phone_app.visible):
		return
	elapsed += delta
	var motion := SeaBoatMover3D.drive(self, delta)
	if motion.is_empty():
		return
	var forward: Vector3 = motion[0]
	var forward_speed: float = motion[1]
	map_boat_proxy.position = SeaLayout3D.to_map(boat.position)
	map_boat_proxy.rotation = -PI / 2.0 - boat.rotation.y
	SeaWorldBuilder3D.animate(self, delta, forward, forward_speed)
	impact.apply(self, delta)
	_update_night_events(delta)
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
	if SeaDebug3D.handle(self, event as InputEventKey):
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
	return SeaPlaces3D.nearest(self)

func _is_towing() -> bool:
	return SeaPlaces3D.is_towing(self)

func _update_night_events(delta: float) -> void:
	SeaPlaces3D.update_night_events(self, delta)

func _try_visit_poi() -> bool:
	var id := _nearest_poi()
	if id.is_empty():
		return false
	poi_busy = true
	boat.velocity = Vector3.ZERO
	_visit_poi(id)
	return true

func _visit_poi(id: String) -> void:
	await SeaPlaces3D.visit(self, id)

func _visit_night_event(index: int) -> void:
	await SeaPlaces3D.visit_night_event(self, index)

func _enter_whirlpool() -> void:
	SeaTrip3D.enter_whirlpool(self)

## Lamp reach for bubbles and submerged rocks: shrinks as the oil runs low.
func _bubble_range() -> float:
	var fraction := oil / maxf(oil_capacity, 1.0)
	var base: float = boat_lamp.spot_range if is_instance_valid(boat_lamp) else 14.0
	return base * 0.6 * lerpf(0.55, 1.0, clampf(fraction * 2.0, 0.0, 1.0))


func _try_fish() -> void:
	SeaCatch3D.try_fish(self)

func _drop_net() -> void:
	SeaCatch3D.drop_net(self)

func _try_haul_net() -> bool:
	return SeaCatch3D.try_haul_net(self)

func _on_catch_detailed(fish: FishData, caught: bool, quality: float, count: int, size: float) -> void:
	SeaCatch3D.on_catch_detailed(self, fish, caught, quality, count, size)

func _store_catch(fish: FishData, quality: float, count: int, size: float) -> void:
	SeaCatch3D.store_catch(self, fish, quality, count, size)

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
	SeaTrip3D.unload(self)

func _end_trip(towed: bool, rescue_fee: int = -1) -> void:
	SeaTrip3D.end_trip(self, towed, rescue_fee)

## Rin / NEO line; waits for the current one to finish (one bubble at a time).
func _say(text: String, seconds: float) -> void:
	if message.text != "" and Time.get_ticks_msec() / 1000.0 < status_until:
		if text != status and _said.size() < 4:
			_said.append([text, seconds])
		return
	status = text
	status_until = Time.get_ticks_msec() / 1000.0 + seconds
	message.text = status

## Called from the HUD tick: shows the next queued line once the last one ends.
func _next_line() -> void:
	if Time.get_ticks_msec() / 1000.0 <= status_until:
		return
	message.text = ""
	if not _said.is_empty():
		var line: Array = _said.pop_front()
		_say(str(line[0]), float(line[1]))

func _update_hud() -> void:
	SeaHud3D.update(self)

func _map_pos(pos: Vector3) -> Vector2:
	return SeaLayout3D.to_map(pos)

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
	SeaTrip3D.spend_oil(self, units)


func _on_rin_fainted() -> void:
	SeaTrip3D.rin_fainted(self)


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
	return SeaHud3D.navigation_targets(self)
