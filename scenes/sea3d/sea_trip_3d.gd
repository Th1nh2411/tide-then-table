class_name SeaTrip3D
extends RefCounted
## A night trip's start and end in the 3D sea: the night-start lines, lamp
## oil (clock + NEO warnings at 25% / 10%), unloading at the dock, ending the
## trip (tow fee, towed boats paid, back to the bedroom: the night
## counts as "went out" for LoopCalendar), the whirlpool
## ending and Rin fainting in a fight.

const BEDROOM_SCENE := "res://scenes/home3d/bedroom_scene_3d.tscn"
const ENDING_SCENE := "res://scenes/ending/ending_scene.tscn"


## Same night-start lines as the 2D sea, queued one after another.
static func night_start_lines(sea: SeaScene3D, fog_tonight: bool) -> void:
	if GameState.last_spoiled_count > 0:
		sea._say("Hư mất %d con trong kho rồi, tiếc ghê..." % GameState.last_spoiled_count, 2.5)
		GameState.last_spoiled_count = 0
	if not GameState.has_flag("neo_hello"):
		GameState.set_flag("neo_hello")
		sea._say("NEO: Chào anh Rin. Rin's Catch đã khởi động lại. Tôi sẽ nhắc anh dầu đèn, khoang cá và đơn hàng.", 4.0)
	var trend := DailyTrend.announcement()
	if trend != "":
		sea._say(trend, 4.0)
	if fog_tonight:
		sea._say("Biển lặng lạ thường... phía đông bắc sương dày lên.", 3.0)
	elif Story.is_fog_open():
		sea._say("Sương phủ kín góc đông bắc... trong đó có ánh sáng gì vậy?", 3.0)
	if sea.weather and sea.weather.start_message != "":
		sea._say(sea.weather.start_message, 4.0)
	sea._say("Tìm bọt khí trên mặt biển. Bến ở phía sau.", 4.0)


static func spend_oil(sea: SeaScene3D, units: float) -> void:
	sea.oil = maxf(sea.oil - units, 0.0)
	var fraction := sea.oil / maxf(sea.oil_capacity, 1.0)
	DayClock.set_progress(1.0 - fraction, DayClock.night_start_hour, DayClock.dawn_hour)
	if not sea.oil_critical_sent and fraction <= 0.1 and sea.oil > 0.0:
		sea.oil_critical_sent = true
		sea._say("NEO: Dầu còn 10%. Anh Rin nên về bến ngay.", 3.0)
	elif not sea.oil_low_sent and fraction <= 0.25 and fraction > 0.1:
		sea.oil_low_sent = true
		sea._say("NEO: Dầu đèn còn 25%. Anh Rin quay về bến nhé.", 3.0)
	if is_instance_valid(sea.boat_lamp):
		sea.boat_lamp.light_energy = 2.5 * lerpf(0.3, 1.0, clampf(fraction * 2.0, 0.0, 1.0))


static func unload(sea: SeaScene3D) -> void:
	if sea.hold.items.is_empty():
		sea._say("Khoang trống. Nhấn R để về nhà.", 2.0)
		return
	var items := sea.hold.items.duplicate()
	for item in items:
		sea.hold.remove(item)
	GameState.unload_catch(items)
	sea._say("Đã dỡ %d con cá. Có thể ra biển tiếp hoặc nhấn R về nhà." % items.size(), 3.0)
	sea._update_hud()


static func end_trip(sea: SeaScene3D, towed: bool, rescue_fee: int = -1) -> void:
	if sea.ending:
		return
	sea.ending = true
	for event: Dictionary in sea.night_events:
		if event["towing"]:
			if towed:
				GameState.trip_notes.append("%s được cứu hộ kéo về luôn, không gửi tiền." % event["owner"])
			else:
				GameState.add_money(80)
				GameState.trip_notes.append("Kéo ghe %s về bến: +80k" % event["owner"])
	if towed:
		var fee := rescue_fee if rescue_fee >= 0 else (150 if BoatCondition.is_broken() else 80)
		GameState.spend_money(mini(fee, GameState.money))
		BoatCondition.tow_patch(20.0)
		GameState.trip_notes.append("Rin được kéo thuyền về bến trong đêm.")
	DayClock.stop()
	GameState.finish_sea_day(DayClock.current_minutes, towed, sea.hold.items.duplicate())
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
	end_trip(sea, true, 0)
