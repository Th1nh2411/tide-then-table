class_name UncannyShift3D
extends Node
## The shift's uncanny tricks (UncannyDirector plan), on the guests: one
## casts no shadow, one keeps turning his head to follow Rin, one holds
## still too long, one walks at a few frames a second or slides without a
## step, a face breaks into noise for a blink, the lights drop for two
## frames and a guest is suddenly facing Rin, a guest walking off (or Bảo
## at his stove) with the same face on the back of the head. Plus this loop's subtitle
## trick (Bảo's line repeated / Rin called "Tư" / a line nobody says) and
## anh Út's tiny cues on rằm (eyes following, a smile held a bit too long).

## First trick this many seconds into the shift, the rest spread after it.
@export var first_at := 14.0
@export var spread := 80.0
@export var subtitle_at := 26.0
@export var near := 6.0

var host: VillageScene3D
var plan: Dictionary = {}
var _queue: Array[Array] = []  # [time, id]
var _clock := 0.0
var _subtitle_done := false
var _ut: UncannyActor3D
var _ut_frozen := false
var _ut_watching := false


static func attach(owner: VillageScene3D, plan_: Dictionary) -> UncannyShift3D:
	var node := UncannyShift3D.new()
	node.name = "UncannyShift"
	node.host = owner
	node.plan = plan_
	owner.add_child(node)
	return node


func _ready() -> void:
	var light: Array = plan.get("light", [])
	var shift_ids: Array[String] = []
	for id: String in light:
		if id in ["missing_shadow", "flicker_pose", "stare", "freeze", "choppy", "wrong_walk", "glitch_face", "two_faces"]:
			shift_ids.append(id)
	for i in shift_ids.size():
		_queue.append([first_at + spread * float(i) / maxf(shift_ids.size(), 1.0), shift_ids[i]])
	_subtitle_done = not UncannyDirector.subtitle_due(plan)


func _process(delta: float) -> void:
	if plan.get("ut_cues", false) and RamNight.is_ram():
		_ut_cues()
	if not host.shift_running:
		return
	_clock += delta
	if not _queue.is_empty() and _clock >= float(_queue[0][0]):
		var entry: Array = _queue.pop_front()
		if not _play(str(entry[1])):
			entry[0] = _clock + 3.0  # nobody to do it on yet: later, after the others
			_queue.append(entry)
			_queue.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	if not _subtitle_done and _clock >= subtitle_at:
		_subtitle_done = true
		_subtitle()


func camera() -> Camera3D:
	return get_viewport().get_camera_3d()


## A seated, visible guest (nearest to Rin first); null if none.
func _guest() -> PersonRig3D:
	var best: PersonRig3D
	var best_d := INF
	for node in host.guests:
		var rig := node as PersonRig3D
		if rig and rig.visible:
			var d := rig.global_position.distance_to(host.player.global_position)
			if d < best_d:
				best = rig
				best_d = d
	return best


func _walker() -> PersonRig3D:
	for child in host.get_children():
		if child is CustomerTraffic3D:
			for trip: Dictionary in (child as CustomerTraffic3D).trips:
				var walker: Variant = trip.get("walker")
				if is_instance_valid(walker) and (walker as Node3D).visible:
					return (walker as Node).get_node_or_null("WalkerActor") as PersonRig3D
	return null


## Someone Rin sees from behind: a guest walking off, else Bảo at his stove.
func _back_turned() -> PersonRig3D:
	for child in host.get_children():
		if child is CustomerTraffic3D:
			for trip: Dictionary in (child as CustomerTraffic3D).trips:
				var walker: Variant = trip.get("walker")
				if str(trip.get("phase", "")) == "walking_out" and is_instance_valid(walker):
					var rig := (walker as Node).get_node_or_null("WalkerActor") as PersonRig3D
					if rig and UncannyDirector.two_faces_ok(rig):
						return rig
	if host.bao_model and host.bao_model.visible and UncannyDirector.two_faces_ok(host.bao_model):
		return host.bao_model
	return null


func _play(id: String) -> bool:
	var rig := _walker() if id in ["choppy", "wrong_walk"] else _guest()
	if id == "two_faces":
		rig = _back_turned()
	if rig == null:
		return false
	var actor := UncannyActor3D.attach(rig)
	match id:
		"missing_shadow":
			UncannyMoves3D.remove_shadow(rig)
		"stare":
			actor.stare_at(camera(), 150.0, 0.6)
			get_tree().create_timer(9.0).timeout.connect(func() -> void:
				if is_instance_valid(actor): actor.stop_stare(0.8))
		"freeze":
			actor.freeze(4.5)
		"choppy":
			actor.choppy(7.0)
		"wrong_walk":
			actor.freeze()  # slides along its path without a step
		"two_faces":
			actor.two_faces(true)  # shows once Rin is behind and looks away
		"glitch_face":
			actor.glitch_face(true)
			get_tree().create_timer(0.45).timeout.connect(func() -> void:
				if is_instance_valid(actor): actor.glitch_face(false))
		"flicker_pose":
			var lights: Array[Node3D] = []
			for light in UncannyScene3D.lights_under(host):
				if light.global_position.x < VillageLayout3D.EXIT_X:
					lights.append(light)
			UncannyScene3D.flicker_pose(self, lights, func() -> void:
				actor.stare_at(camera(), 150.0, 0.0)
				actor.freeze(3.0))
			get_tree().create_timer(3.5).timeout.connect(func() -> void:
				if is_instance_valid(actor): actor.stop_stare(0.0))
	return true


func _subtitle() -> void:
	var kind := str(plan.get("subtitle", ""))
	var line := SubtitleTricks.line_for(kind, RestaurantFish3D.ASK_LINE, GameState.day + LoopCalendar.loops())
	if line == "":
		return
	GameState.set_flag(UncannyDirector.SUBTITLE_FLAG)
	host._show_note(line)


## Rằm: anh Út's eyes follow Rin a little (natural range), and once the tea
## is answered his smile stays a beat too long. Never his true face.
func _ut_cues() -> void:
	var ut := host.get_node_or_null("AnhUt") as RamGuest3D
	if ut == null or not ut.arrived:
		return
	if _ut == null:
		for child in ut.get_children():
			if child is PersonRig3D:
				_ut = UncannyActor3D.attach(child as PersonRig3D)
		if _ut == null:
			return
	var close := _ut.rig.global_position.distance_to(host.player.global_position) < near
	if close != _ut_watching:
		_ut_watching = close
		if close:
			_ut.stare_at(camera(), 55.0, 0.8)
		else:
			_ut.stop_stare(0.8)
	if ut.answered and not _ut_frozen:
		_ut_frozen = true
		_ut.freeze(1.8)
