class_name UncannyVillage3D
extends Node3D
## Places tonight's uncanny plan (UncannyDirector) on the village map. One
## line in VillageScene3D._ready. The shift's tricks (guests, subtitles,
## anh Út) live in UncannyShift3D; this node does the evening / night:
## slippers by the bed turned to face the door (the sea), the street's stools
## all turned one way, Rin's door closed without a sound, one person too
## many in the street, eyes under a house in the lane, a figure only in the
## water at the pier, the night's heavy effect, and ông Tư behind Rin on
## mùng 13 (TuGhostScare3D, which counts as that night's heavy one).

const SLIPPERS := Vector3(-0.35, 0, 1.3)  # room space, by the bed
const EXTRA_FIGURE := Vector3(-5.0, 0, 7.9)  # street, by the parked bikes
const EYES := Vector3(37.5, 0.45, 6.9)
const EYES_LAMP := Vector3(36.6, 2.3, 6.4)
## Done once the heavy effect played tonight (normal flag, holds the day).
const HEAVY_FLAG := "uncanny_heavy_day"

var host: VillageScene3D
var plan: Dictionary = {}
var slippers: Node3D
var _evening := false


static func attach(owner: VillageScene3D) -> UncannyVillage3D:
	var node := UncannyVillage3D.new()
	node.name = "Uncanny"
	node.host = owner
	owner.add_child(node)
	return node


func _ready() -> void:
	plan = UncannyDirector.tonight()
	slippers = UncannyScene3D.slippers(host, VillageLayout3D.room_point(SLIPPERS), PI)  # toes to the bed
	UncannyShift3D.attach(host, plan)
	if host.night:
		_start_evening()


func _process(_delta: float) -> void:
	if not _evening and host.shift_over:
		_start_evening()


func _start_evening() -> void:
	_evening = true
	if UncannyDirector.has(plan, "props_turned"):
		var door := VillageLayout3D.room_point(BedroomBuilder3D.DOOR)
		var yaw := atan2(door.x - slippers.global_position.x, door.z - slippers.global_position.z)
		UncannyScene3D.turn_when_unseen(self, slippers, yaw)
		UncannyScene3D.all_face_when_unseen(self, _stools(), VillageLayout3D.WATERFRONT)
	if UncannyDirector.has(plan, "door_closed") and host.door:
		UncannyScene3D.close_door_unseen(self, host.door, func() -> bool:
			return host.door.is_open and not VillageLayout3D.in_room(host.player.global_position) \
				and host.player.global_position.distance_to(host.door.global_position) > 6.0)
	# Avoidable sights get a "too close" zone (ProximityZone3D).
	if UncannyDirector.has(plan, "extra_figure"):
		ProximityZone3D.guard(UncannyScene3D.extra_figure(self, EXTRA_FIGURE, EXTRA_FIGURE + Vector3(0, 0, -3)))
	if UncannyDirector.has(plan, "glowing_eyes"):
		var lamp := OmenProps3D.light(self, EYES_LAMP, "ffcf8a", 0.25, 5.0)
		var eyes := UncannyEyes3D.spawn(self, EYES, EYES + Vector3(0, 0, -4), lamp)
		var zone := ProximityZone3D.guard(eyes)
		if zone:
			zone.on_gone = eyes.vanish
	if UncannyDirector.has(plan, "reflection"):
		_reflection_on_pier()
	_pier_figure_blocks.call_deferred()
	_guard_pier_figure.call_deferred()
	_heavy_or_tu()


## Omen "bóng người đầu cầu tàu", from the day wrong movement starts: the
## figure by the pier-head post is a little nearer the shore after every
## look, standing in the way to the thúng. The omen itself is unchanged.
func _pier_figure_blocks() -> void:
	if GameState.day < int(UncannyDirector.DOSE.light_from_day.get("stare", 4)):
		return
	var figure := _pier_figure()
	if figure == null:
		return
	var start := figure.position
	var trick := UnseenTrick3D.watch(self, func(step: int) -> void:
			figure.position = start + Vector3(0, 0, 2.2 * (step + 1)),
		func(_step: int) -> Array[Vector3]:
			var from := figure.global_position
			return [from + Vector3.UP * 0.3, from + Vector3.UP * 1.6,
				from + Vector3(0, 0.3, 2.2), from + Vector3(0, 1.6, 2.2)] as Array[Vector3],
		3)
	# Gone (noticed Rin) or chasing him: the trick stops.
	trick.gate = func() -> bool:
		if not is_instance_valid(figure) or figure.has_meta(Chase3D.META):
			trick.queue_free()
			return false
		return true


## The omen's figure at the pier head: too close and it notices him. On the
## pier it only shows its face; on the sand (after it crept ashore) it may chase.
func _guard_pier_figure() -> void:
	var figure := _pier_figure()
	if figure:
		var zone := ProximityZone3D.guard(figure, ProximityZone3D.Kind.CHASE)
		if zone:
			zone.no_chase = func() -> bool: return VillageLayout3D.on_pier(host.player.global_position)


func _pier_figure() -> Node3D:
	if not OmenPicker.is_tonight("bong_cau_tau") or host.dock_omens == null:
		return null
	return host.dock_omens.get_node_or_null("Model_drowned_figure") as Node3D


## Rin's area on the map ("house" / "street" / "lane" / "waterfront").
func area() -> String:
	return VillageLayout3D.area(host.player.global_position)


func _stools() -> Array[Node3D]:
	var stools: Array[Node3D] = []
	for child in host.get_children():
		if child is Node3D and String(child.name).begins_with("PilotStool_"):
			stools.append(child as Node3D)
	return stools


func _reflection_on_pier() -> void:
	var on_pier := func() -> bool: return VillageLayout3D.on_pier(host.player.global_position)
	while is_inside_tree() and not bool(on_pier.call()):
		await get_tree().create_timer(0.5).timeout
	if is_inside_tree():
		UncannyReflection3D.spawn(self, WaterfrontBuilder3D.WATER_Y + 0.02)


## One heavy thing tonight at most: ông Tư (mùng 13, once), else the plan's.
func _heavy_or_tu() -> void:
	var outside := func() -> bool:
		return host.shift_over and not host.leaving and not host.waking \
			and area() in ["lane", "waterfront"] and not VillageLayout3D.on_pier(host.player.global_position)
	var tu := TuGhostScare3D.attach(self, func() -> bool:
			return bool(outside.call()) and area() == "waterfront",
		func(words: String, seconds: float) -> void: host.text.say(words, seconds))
	if tu:
		return
	var heavy := str(plan.get("heavy", ""))
	if heavy == "" or int(GameState.story_flags.get(HEAVY_FLAG, -1)) == GameState.day:
		return
	var kind := UncannyHeavy3D.Kind.FLASH
	if heavy == "appear_close":
		kind = UncannyHeavy3D.Kind.APPEAR_CLOSE
	elif heavy == "dash":
		kind = UncannyHeavy3D.Kind.DASH
	var effect := UncannyHeavy3D.start(self, kind, outside)
	effect.finished.connect(func() -> void: GameState.set_flag(HEAVY_FLAG, GameState.day))
