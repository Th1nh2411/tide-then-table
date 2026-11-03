class_name SeaTrip3D
extends RefCounted
## A night trip's start and end in the 3D sea: the night-start lines, lamp
## oil (clock + light), ending the trip (back to the village's pier at night:
## the night counts as "went out" with the basket's fish for LoopCalendar,
## judged when Rin wakes) and the whirlpool ending.

const ENDING_SCENE := "res://scenes/ending/ending_scene.tscn"


## A short line at the start of the night, then the fog if it is up.
static func night_start_lines(sea: SeaScene3D, fog_tonight: bool) -> void:
	if fog_tonight:
		sea._say("Biển lặng lạ thường... phía đông bắc sương dày lên.", 3.0)
	elif Story.is_fog_open():
		sea._say("Sương phủ kín góc đông bắc... trong đó có ánh sáng gì vậy?", 3.0)


static func spend_oil(sea: SeaScene3D, units: float) -> void:
	sea.oil = maxf(sea.oil - units, 0.0)
	var fraction := sea.oil / maxf(sea.oil_capacity, 1.0)
	DayClock.set_progress(1.0 - fraction, DayClock.night_start_hour, DayClock.dawn_hour)
	if not sea.oil_low_sent and fraction <= 0.25 and sea.oil > 0.0:
		sea.oil_low_sent = true
		sea._say("Đèn leo lét rồi... về thôi.", 3.0)
	if is_instance_valid(sea.boat_lamp):
		sea.boat_lamp.light_energy = 2.5 * lerpf(0.3, 1.0, clampf(fraction * 2.0, 0.0, 1.0))


static func end_trip(sea: SeaScene3D, towed: bool) -> void:
	if sea.ending:
		return
	sea.ending = true
	_go_home(sea, towed)


## Đêm âm (DarkNight3D): the light dies, hands take the boat; he never
## reaches the dock. Counts as "went out" on an omen night -> loop reset.
static func taken_by_the_sea(sea: SeaScene3D) -> void:
	if sea.ending:
		return
	sea.ending = true
	var dark := DarkNight3D.active(sea)
	if dark:
		await dark.play_taken()
	if not is_instance_valid(sea) or not sea.is_inside_tree():
		return
	GameState.trip_notes.append("Rin không về tới bến.")
	_go_home(sea, false, true)


## A broken hull gets a free patch; Rin is back on the pier at night and
## walks home to bed (the morning judges the night). `taken`: the sea took
## him, nothing comes home: he wakes straight into the (reset) morning.
static func _go_home(sea: SeaScene3D, towed: bool, taken: bool = false) -> void:
	if towed:
		BoatCondition.tow_patch(20.0)
		GameState.trip_notes.append("Rin được kéo thuyền về bến trong đêm.")
	DayClock.stop()
	var fish := 0 if taken else sea.rod.basket.count()
	LoopCalendar.choose(true, fish)
	if taken:
		SceneRouter.go_to(VillageLayout3D.SCENE)
	else:
		VillageDay3D.back_from_sea()


static func enter_whirlpool(sea: SeaScene3D) -> void:
	if sea.ending:
		return
	sea.ending = true
	DayClock.stop()
	GameState.set_flag(Story.ENDING_SEEN_FLAG)
	Sfx.play("whoosh")
	sea.boat.velocity = Vector3.ZERO
	var tween := sea.create_tween().set_parallel()
	tween.tween_property(sea.boat, "position", sea.WHIRLPOOL_POS, 2.0)
	tween.tween_property(sea.boat, "rotation:y", sea.boat.rotation.y + TAU * 3.0, 2.0)
	tween.tween_property(sea.boat_visual, "scale", Vector3.ONE * 0.3, 2.0)
	await tween.finished
	SceneRouter.go_to(ENDING_SCENE, Color.WHITE)
