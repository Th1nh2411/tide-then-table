class_name RamSea3D
extends Node3D
## The sea on đêm rằm (PLAN §10 H7), added by SeaSetup3D on the last night.
## Drank anh Út's tea: Rin grows drowsy and anh Út comes for him (RamDrowse3D).
## Refused it: the dead light a trail of ghost-lights on the water from the
## dock to the lobster raft, with ghosts standing beside it; close to the
## raft, Rin's lamp catches anh Út at work (RamReveal3D).

const NODE_NAME := "RamSea"
const TRAIL_STEP := 4.5
const TRAIL_SHOW := 18.0
const REVEAL_DISTANCE := 11.0
const GHOST_EVERY := 3

@export var whisper_gap := 11.0

var sea: SeaScene3D
var drank := false
var text: OnScreenText
var trail: Array[MeshInstance3D] = []
var ghosts: Array[StandardMaterial3D] = []
var drowse: RamDrowse3D
var revealing := false
var _clock := 0.0
var _whisper := 0


static func attach(host: SeaScene3D) -> RamSea3D:
	if not RamNight.is_ram():
		return null
	var ram := RamSea3D.new()
	ram.name = NODE_NAME
	ram.sea = host
	host.add_child(ram)
	return ram


static func active(host: Node) -> RamSea3D:
	return host.get_node_or_null(NODE_NAME) as RamSea3D


func _ready() -> void:
	drank = RamNight.drank()
	text = OnScreenText.new()
	add_child(text)
	text.layer = 48  # readable over the drowsy blur and the reveal's flashes
	if drank:
		drowse = RamDrowse3D.new()
		drowse.ram = self
		add_child(drowse)
		return
	_build_trail()
	_clock = whisper_gap - 3.0


## Ghost-lights from the dock to the raft, bending a little, and the dead beside them.
func _build_trail() -> void:
	var from := sea.START
	var to := sea.RAFT_POS
	var length := from.distance_to(to)
	var side := (to - from).normalized().cross(Vector3.UP)
	var count := int(length / TRAIL_STEP)
	for i in range(1, count):
		var t := float(i) / count
		var at := from.lerp(to, t) + side * sin(t * PI) * 5.0
		at.y = SeaWater3D.WATER_Y + 0.15
		var light := OmenProps3D.sphere(self, at, 0.12, "5fd8cc", 2.2)
		light.set_meta("phase", float(i) * 0.7)
		trail.append(light)
		if i % GHOST_EVERY == 0:
			var ghost := RamFx3D.ghost(self, at + side * 2.2 * (1.0 if i % 2 == 0 else -1.0) + Vector3(0, -0.2, 0))
			var holder := RamFx3D.ghost_holder(ghost)
			var to_dock := from - holder.position
			holder.rotation.y = atan2(to_dock.x, to_dock.z)  # models face +Z: towards the coming boat
			ghosts.append(ghost)
	OmenProps3D.light(self, Vector3(to.x, 1.2, to.z), "39ff8a", 1.2, 7.0)  # the green lamp on the raft


func _process(delta: float) -> void:
	if drank or revealing or sea.ending:
		return
	var boat := sea.boat.position
	var time := Time.get_ticks_msec() / 1000.0
	for light in trail:
		var near := light.position.distance_to(boat) < TRAIL_SHOW
		light.visible = near
		if near:
			light.position.y = SeaWater3D.WATER_Y + 0.15 + sin(time * 1.5 + float(light.get_meta("phase"))) * 0.06
	for ghost in ghosts:
		var holder := RamFx3D.ghost_holder(ghost)
		var close := holder.position.distance_to(boat) < 5.0
		ghost.albedo_color.a = move_toward(ghost.albedo_color.a, 0.0 if close else 0.42, delta * 0.8)
	_clock += delta
	if _clock >= whisper_gap:
		_clock = 0.0
		_whisper_next()
	if boat.distance_to(sea.RAFT_POS) < REVEAL_DISTANCE:
		reveal()


func _whisper_next() -> void:
	var lines := RamFx3D.LINES.whispers_trail
	if lines.is_empty():
		return
	Sfx.play("whisper", 0.1)
	text.say(lines[_whisper % lines.size()], 2.5)
	_whisper += 1


func reveal() -> void:
	if revealing:
		return
	revealing = true
	RamReveal3D.play(self)


## R at the dock does nothing while drugged (he can't get off the boat).
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if drank and key and key.pressed and key.physical_keycode == KEY_R:
		get_viewport().set_input_as_handled()
