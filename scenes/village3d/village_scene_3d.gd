class_name VillageScene3D
extends RestaurantScene3D
## Xóm Đèn as one walkable first-person map (PLAN §10 "Map chung"): Rin's
## room inside his house on the waterfront, the pier with ông Tư's thúng and
## the lighthouses, the lane, and the restaurant street (this class extends
## RestaurantScene3D, so the street keeps its own coordinates and all of its
## shift / service / crew / traffic / omen code). Layout: VillageLayout3D;
## building: VillageBuilder3D; light by time and zone: VillageLighting3D;
## E outside the restaurant: VillageSpots3D; ông Tám / chú Hai:
## VillageNpcs3D; sound by area: VillageAudio3D;
## day turns: VillageDay3D (each morning reloads this scene).
## Morning: Rin wakes in bed (judged night; NightmareWake3D after a reset).
## The shift opens when he first walks into the street; after it, night
## everywhere: the bed (sleep) or the thúng (the night sea, which docks back
## here on the pier at night).

## The gap in the street's east wall (RestaurantRoomBuilder3D reads it).
var street_exit := VillageLayout3D.EXIT_Z
## The gap in its west wall: the pavement runs on into the fog (WorldEdgeLoop3D).
var street_west := StreetFacades3D.WEST_Z
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
## Ông Tám and chú Hai (VillageNpcs3D).
var npcs: VillageNpcs3D
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
	BedroomBuilder3D.set_date(calendar, LoopCalendar.date_text(GameState.day).replace(" tháng", "\ntháng"))
	VillageAudio3D.prebuild()
	if night:
		_start_night()
	else:
		_start_morning(result, was_ram)
	npcs = VillageNpcs3D.attach(self)
	sounds.update(player.global_position, 0.0)
	UncannyVillage3D.attach(self)  # wrong-looking things, dosed by day


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
		NightmareWake3D.play(self, "Hộc... hộc...", visited, WrongNightScare3D.due_at_wake(result))
		if was_ram:
			VillageDay3D.gate_closed(self)  # rằm went by with nothing found
	Chase3D.leave_trace(self)  # got away last night: wet steps up to the door
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
	follow_ground()
	sounds.update(player.global_position, before.distance_to(player.global_position))


## Walkers have no gravity: on the beach Rin's feet follow its slope.
func follow_ground() -> void:
	var sand := VillageLayout3D.beach_y(player.global_position)
	if not is_nan(sand):
		player.global_position.y = sand


func _process(delta: float) -> void:
	super._process(delta)
	if leaving:
		return
	var at := player.global_position
	lighting.set_inside(VillageLayout3D.in_room(at))
	if not shift_running and not shift_over and at.x < VillageLayout3D.SHIFT_X:
		_open_shift()
	if _echo_pending and sounds.area == "waterfront":
		_echo_pending = false
		OmenEcho3D.attach(self, VillageLayout3D.waterfront_point(WaterfrontBuilder3D.PIER_POST) + Vector3(0, 1.0, 0))


## The room / pier first, then villagers, then the restaurant's stations.
func prompt_verb() -> String:
	var what := spots.target() if spots else ""
	if what != "":
		return spots.prompt(what)
	var said := npcs.prompt() if npcs else ""
	return said if said != "" else super.prompt_verb()


func _prompt_blocked() -> bool:
	return leaving or waking or super._prompt_blocked()


## E: the room / pier first (VillageSpots3D), else the restaurant's stations.
func _interact() -> void:
	if leaving or waking:
		return
	var what := spots.target()
	if what != "":
		spots.act(what)
		return
	if npcs and npcs.interact():
		return
	super._interact()


## The boxed line on the mùng 9 paper after a wrong night ("" otherwise).
func paper_hint() -> String:
	return VillageSpots3D.paper_hint()
