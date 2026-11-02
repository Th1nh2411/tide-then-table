class_name SeaTrip3D
extends RefCounted
## A night trip's start and end in the 3D sea: the night-start lines, lamp
## oil (clock + light), unloading at the dock, ending the trip (back to the
## bedroom: the night counts as "went out" for LoopCalendar), the whirlpool
## ending and Rin fainting in a fight.

const BEDROOM_SCENE := "res://scenes/home3d/bedroom_scene_3d.tscn"
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


static func unload(sea: SeaScene3D) -> void:
	if sea.hold.items.is_empty():
		sea._say("Khoang trống. Nhấn R để về nhà.", 2.0)
		return
	var items := sea.hold.items.duplicate()
	for item in items:
		sea.hold.remove(item)
	sea._say("Đã dỡ %d con cá. Có thể ra biển tiếp hoặc nhấn R về nhà." % items.size(), 3.0)
	sea._update_hud()


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
	_go_home(sea, false)


## A broken hull gets a free patch, then the bedroom judges the night.
static func _go_home(sea: SeaScene3D, towed: bool) -> void:
	if towed:
		BoatCondition.tow_patch(20.0)
		GameState.trip_notes.append("Rin được kéo thuyền về bến trong đêm.")
	DayClock.stop()
	LoopCalendar.choose(true)
	SceneRouter.go_to(BEDROOM_SCENE)


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


static func rin_fainted(sea: SeaScene3D) -> void:
	GameState.trip_notes.append("Rin bất tỉnh khi vật lộn với cá ngoài khơi.")
	sea._say("Choáng quá... may có người kéo thuyền về bến.", 3.0)
	if sea.hold_ui and sea.hold_ui.visible:
		await sea.hold_ui.closed
	end_trip(sea, true)
