class_name VillageScene3D
extends RestaurantScene3D
## Xóm Đèn as one walkable first-person map (PLAN §10 "Map chung"): Rin's
## room inside his house on the waterfront, the pier with ông Tư's thúng and
## the lighthouses, the lane, and the restaurant street (this class extends
## RestaurantScene3D, so the street keeps its own coordinates and all of its
## shift / service / crew / traffic / omen code). Layout: VillageLayout3D;
## building: VillageBuilder3D; light by time and zone: VillageLighting3D;
## E outside the restaurant: VillageSpots3D; sound by area: VillageAudio3D;
## day turns: VillageDay3D (each morning reloads this scene).
## Morning: Rin wakes in bed (judged night; NightmareWake3D after a reset).
## The shift opens when he first walks into the street; after it, night
## everywhere: the bed (sleep) or the thúng (the night sea, which docks back
## here on the pier at night).

## The gap in the street's east wall (RestaurantRoomBuilder3D reads it).
var street_exit := VillageLayout3D.EXIT_Z
## Loaded at night on the pier (back from the sea).
var night := false
var leaving := false
## Nightmare wake (NightmareWake3D): eye moved / pitch held; no walking meanwhile.
var waking := false
var eye_offset := Vector3.ZERO
var held_pitch := NAN
## FirstPersonView3D looks this way first.
var start_yaw := 0.0
var text: OnScreenText
var calendar: Label3D
var door: VillageDoor3D
var waterfront: Node3D
var lighting: VillageLighting3D
var spots: VillageSpots3D
var sounds := VillageAudio3D.new()
var dock_omens: DockOmens3D
## Evening after a shift: a subtle omen's echo waits for Rin on the waterfront.
var _echo_pending := false


func _ready() -> void:
	night = GameState.has_flag(VillageDay3D.NIGHT_FLAG)
	GameState.story_flags.erase(VillageDay3D.NIGHT_FLAG)
	var was_ram := RamNight.is_ram()
	var result := LoopCalendar.Result.NONE
	if not night:
		result = VillageDay3D.judge_morning()
		if result == LoopCalendar.Result.END:
			leaving = true  # nothing is built; straight on to the ending
			set_process(false)
			set_physics_process(false)
			set_process_unhandled_key_input(false)
			VillageDay3D.go_to_ending(self)
			return
	auto_open = false  # the shift opens when Rin first walks into the street
	super._ready()
	lighting = VillageLighting3D.new()
	lighting.name = "Lighting"
	add_child(lighting)
	lighting.setup(self)
	text = OnScreenText.new()
	add_child(text)
	spots = VillageSpots3D.new(self)
	VillageBuilder3D.build(self)
	calendar.text = LoopCalendar.date_text(GameState.day).replace(" tháng", "\ntháng")
	VillageAudio3D.prebuild()
	if night:
		_start_night()
	else:
		_start_morning(result, was_ram)
	sounds.update(player.global_position, 0.0)


func _start_morning(result: LoopCalendar.Result, was_ram: bool) -> void:
	lighting.set_phase(VillageLighting3D.Phase.MORNING, false)
	_place(VillageLayout3D.morning_start(), VillageLayout3D.room_point(BedroomBuilder3D.DOOR))
	DayClock.set_progress(0.0, DayClock.shop_open_hour, DayClock.shop_close_hour)
	if result == LoopCalendar.Result.RESET:
		# A calm night gone wrong (stayed home / came back short): the drowned
		# came to the door. Three knocks in the dark, wet steps up to the bed.
		var visited := LoopCalendar.last_calm_miss
		if visited:
			WetFootprints3D.build(self, VillageLayout3D.room_point(BedroomBuilder3D.DOOR), VillageLayout3D.room_point(BedroomBuilder3D.BEDSIDE))
		NightmareWake3D.play(self, "Hộc... hộc...", visited)
		if was_ram:
			VillageDay3D.gate_closed(self)  # rằm went by with nothing found
	GameState.resume_at = "home"
	SaveSystem.autosave("home")


## Back from the sea: night, on the pier by the thúng, facing the village.
func _start_night() -> void:
	shift_over = true
	lighting.set_phase(VillageLighting3D.Phase.NIGHT, false)
	_place(VillageLayout3D.pier_start(), VillageLayout3D.waterfront_point(WaterfrontBuilder3D.DOOR))
	var ut := get_node_or_null("AnhUt")
	if ut:
		ut.queue_free()  # his tea was at the shift, before the sea
	_begin_evening(false)


func _place(at: Vector3, facing: Vector3) -> void:
	player.position = at
	var to := facing - at
	start_yaw = atan2(-to.x, -to.z)
	player.rotation.y = start_yaw + PI


## After the shift (or back from the sea): the dock omens show, rằm lanterns.
func _begin_evening(echo: bool) -> void:
	dock_omens = VillageBuilder3D.build_dock_omens(self)
	RamShore3D.attach(waterfront)
	_echo_pending = echo


func _open_shift() -> void:
	var was_running := shift_running
	super._open_shift()
	if shift_running and not was_running and lighting:
		lighting.set_phase(VillageLighting3D.Phase.SHIFT)


func _end_shift() -> void:
	var was_over := shift_over
	super._end_shift()
	if shift_over and not was_over and lighting:
		lighting.set_phase(VillageLighting3D.Phase.NIGHT)
		_begin_evening(true)


func _physics_process(delta: float) -> void:
	if leaving or waking or get_tree().paused or mover.focus_lost:
		mover.stop(delta)
		return
	var before := player.global_position
	mover.move(delta)
	sounds.update(player.global_position, before.distance_to(player.global_position))


func _process(delta: float) -> void:
	super._process(delta)
	if leaving:
		text.prompt("")
		return
	var at := player.global_position
	lighting.set_inside(VillageLayout3D.in_room(at))
	if not shift_running and not shift_over and at.x < VillageLayout3D.SHIFT_X:
		_open_shift()
	if _echo_pending and sounds.area == "waterfront":
		_echo_pending = false
		OmenEcho3D.attach(self, VillageLayout3D.waterfront_point(WaterfrontBuilder3D.PIER_POST) + Vector3(0, 1.0, 0))
	var what := "" if waking or get_tree().paused else spots.target()
	text.prompt(spots.prompt(what))


## E: the room / pier first (VillageSpots3D), else the restaurant's stations.
func _interact() -> void:
	if leaving or waking:
		return
	var what := spots.target()
	if what != "":
		spots.act(what)
		return
	super._interact()


## The boxed line on the mùng 9 paper after a wrong night ("" otherwise).
func paper_hint() -> String:
	return VillageSpots3D.paper_hint()
