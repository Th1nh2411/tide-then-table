class_name ChuHai3D
extends Node3D
## Chú Hai, the lane neighbour (VillageNpcs3D; data/story/chu_hai.tres): his
## house is the lime-washed one on the lane's north side. At dawn he pushes
## his bike a few steps out towards the street (to market) once Rin comes
## into the lane; during the shift he and the bike are away; at night he
## smokes by his door, the bike back beside him. From `gone_from_day`
## (mùng 14) he went to sea and did not come back: only the bike stays by
## the door. Solid while there; never on the lane's walking line (z ~3.5).

const LINES: NpcLinesData = preload("res://data/story/chu_hai.tres")
const DOOR := Vector3(24.6, 0, 1.45)
const BIKE_HOME := Vector3(26.4, 0, 1.45)
const BIKE_MARKET := Vector3(23.4, 0, 1.45)
const BIKE_SIZE := Vector3(0.7, 1.1, 1.8)
## Him from the bike's centre while pushing: lane side, by the handlebar.
const BESIDE := Vector3(-0.45, 0, 0.62)
const REACH := 1.9
const EMBER := Vector3(0.03, 1.56, 0.16)

@export var gone_from_day := 6
@export var push_speed := 0.55

var host: VillageScene3D
var rig: PersonRig3D
var talk: NpcTalk3D
var bike: Node3D
var gone := false
var phase := -1
var _bike_shape: CollisionShape3D
var _ember: OmniLight3D
var _ember_dot: MeshInstance3D
var _pushed := false


func _ready() -> void:
	gone = GameState.day >= gone_from_day
	bike = Node3D.new()
	bike.name = "Bike"
	add_child(bike)
	bike.position = BIKE_HOME
	VillageProps3D.place(bike, StreetLife3D._bike_id(), Vector3.ZERO, BIKE_SIZE, PI * 0.5)
	var body := StaticBody3D.new()
	bike.add_child(body)
	_bike_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(BIKE_SIZE.z, BIKE_SIZE.y, BIKE_SIZE.x)
	_bike_shape.shape = box
	_bike_shape.position.y = BIKE_SIZE.y * 0.5
	body.add_child(_bike_shape)
	if gone:
		return
	rig = PersonRig3D.build(self, "chu_hai")
	rig.name = "Hai"
	talk = NpcTalk3D.new(rig, LINES, REACH)
	talk.listener = host.player
	# The cigarette's ember at his mouth.
	_ember_dot = OmenProps3D.glow_box(rig, EMBER, Vector3(0.018, 0.018, 0.018), "ff6a2a", 5.0)
	_ember = OmenProps3D.light(rig, EMBER + Vector3(0, 0, 0.05), "ff8a4a", 0.35, 1.4)


## Where he is for this time of day (VillageLighting3D.Phase).
func set_phase(next: int) -> void:
	if next == phase:
		return
	phase = next
	var away := next == VillageLighting3D.Phase.SHIFT
	_set_bike(not away, BIKE_HOME)
	if rig == null:
		_set_bike(true, BIKE_HOME)  # gone: the bike never moves again
		return
	rig.visible = not away
	talk.talks = 0
	talk.night = next == VillageLighting3D.Phase.NIGHT
	_ember.visible = talk.night
	_ember_dot.visible = talk.night
	if next == VillageLighting3D.Phase.MORNING:
		rig.position = BIKE_HOME + BESIDE
		rig.rotation.y = -PI * 0.5  # towards the street
	elif talk.night:
		rig.position = DOOR + Vector3(0, 0, 0.35)
		rig.rotation.y = 0.25  # out over the lane


func _set_bike(on: bool, at: Vector3) -> void:
	bike.visible = on
	bike.position = at
	_bike_shape.disabled = not on


func _process(delta: float) -> void:
	if rig == null or not rig.visible:
		return
	if talk.holding(delta):
		return
	if talk.night:
		_ember.light_energy = 0.3 + 0.12 * sin(Time.get_ticks_msec() / 260.0)
	elif not _pushed and host.player and VillageLayout3D.area(host.player.global_position) == "lane":
		_push(delta)


## A few steps west with the bike, then he stops (the engine won't start).
func _push(delta: float) -> void:
	var step := minf(push_speed * delta, bike.position.x - BIKE_MARKET.x)
	if step <= 0.0:
		_pushed = true
		return
	bike.position.x -= step
	var before := rig.global_position
	rig.position = bike.position + BESIDE
	rig.drive_ground_motion(rig.global_position - before, delta, false)
