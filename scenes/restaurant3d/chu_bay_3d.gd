class_name ChuBay3D
extends Node3D
## Chú Bảy, the kind old regular (PLAN §10 "Ma da + chú Bảy"): every shift he
## sits at the corner table under a weak bulb, looking out east to the sea,
## a cup of tea in front of him. He is the lighthouse keeper killed last
## year; nothing says so. Fair-play tells: nobody serves him or sits with him
## (his table is not a service table, FloorGrid3D blocks it), his tea is
## always full and never steams, his clothes are damp (WET tint) with a
## puddle under the stool that never dries, water drips when Rin stands
## close. Lines: ChuBayTalk3D. On an omen day he is there only at the start
## of the shift (to say "Tối nay ở nhà đi con.") and then gone, the cup left.
## Never touched by uncanny effects or chases (meta uncanny_skip).

const SKETCH: NoteData = preload("res://data/story/chu_bay_sketch.tres")
const NODE_NAME := "ChuBay"
const TABLE := Vector3(-4.2, 0, 0.6)
const SEAT := TABLE + Vector3(-0.95, 0, 0)
const CUP := TABLE + Vector3(0.05, 0.84, 0.18)
## Damp cloth: darker, a little cold.
const WET := Color(0.6, 0.66, 0.7)
## Loop flag: the sketch was handed over (he gives it again after a reset).
const SKETCH_FLAG := "bay_sketch"
## The way to the raft, pen strokes in paper fractions (shore, pier, posts, path, raft).
const STROKES := [
	Vector2(0.2, 0.86), Vector2(0.8, 0.86), Vector2(0.48, 0.86), Vector2(0.48, 0.8),
	Vector2(0.52, 0.86), Vector2(0.52, 0.8), Vector2(0.5, 0.78), Vector2(0.5, 0.7),
	Vector2(0.5, 0.7), Vector2(0.53, 0.66), Vector2(0.53, 0.66), Vector2(0.6, 0.63),
	Vector2(0.6, 0.63), Vector2(0.69, 0.6), Vector2(0.66, 0.57), Vector2(0.72, 0.63),
	Vector2(0.72, 0.57), Vector2(0.66, 0.63), Vector2(0.47, 0.74), Vector2(0.47, 0.72),
	Vector2(0.5, 0.67), Vector2(0.5, 0.65), Vector2(0.56, 0.63), Vector2(0.56, 0.61),
	Vector2(0.62, 0.56), Vector2(0.64, 0.5), Vector2(0.64, 0.5), Vector2(0.66, 0.56),
]

## Omen day: he leaves once this fraction of the shift has gone.
@export var omen_leave_fraction := 0.35
@export var drip_reach := 1.7
@export var drip_every := Vector2(1.6, 3.2)

var host: RestaurantScene3D
var rig: PersonRig3D
var talk: ChuBayTalk3D
var omen := false
var cup: Node3D
var _drip := 0.0
var _bulb: OmniLight3D


static func attach(owner: RestaurantScene3D) -> ChuBay3D:
	var bay := ChuBay3D.new()
	bay.name = NODE_NAME
	bay.host = owner
	owner.add_child(bay)
	return bay


static func of(owner: Node) -> ChuBay3D:
	return owner.get_node_or_null(NODE_NAME) as ChuBay3D


func _ready() -> void:
	set_meta(ChaseRules.SKIP_META, true)
	omen = GameState.has_flag(LoopCalendar.OMEN_FLAG)
	var table: Node3D = RestaurantRoomBuilder3D.TABLE_PILOT.instantiate()
	add_child(table)
	table.position = TABLE
	table.rotation.y = RestaurantLayout3D.TABLE_YAW
	RestaurantRoomBuilder3D.solid_block(self, TABLE + Vector3(0, 0.8, 0), RestaurantLayout3D.TABLE_COLLISION_SIZE)
	var stool: Node3D = RestaurantRoomBuilder3D.STOOL_PILOT.instantiate()
	add_child(stool)
	stool.position = SEAT
	stool.scale = Vector3.ONE * WorldPresentation3D.RESTAURANT_STOOL_SCALE
	# The puddle under his stool, the full cup (tea to the brim, no steam), the weak bulb.
	OmenProps3D.box(self, SEAT + Vector3(0.1, 0.004, 0.05), Vector3(0.8, 0.006, 0.55), "15191b")
	cup = Node3D.new()
	add_child(cup)
	cup.position = CUP
	OmenProps3D.box(cup, Vector3(0, 0.035, 0), Vector3(0.075, 0.07, 0.075), "cfc6ae")
	OmenProps3D.box(cup, Vector3(0, 0.071, 0), Vector3(0.062, 0.004, 0.062), "5a3c1c")
	OmenProps3D.box(self, TABLE + Vector3(0, 2.6, 0), Vector3(0.08, 0.1, 0.08), "c9b27a")
	_bulb = OmenProps3D.light(self, TABLE + Vector3(0, 2.45, 0), "e8c890", 0.45, 4.5)
	rig = PersonRig3D.build(self, "chu_bay")
	rig.name = "Bay"
	rig.set_meta(ChaseRules.SKIP_META, true)
	rig.position = SEAT
	rig.rotation.y = PI * 0.5  # facing the table and, past it, the sea
	rig.set_seated(true)
	rig.visible = false
	_wet(rig)
	talk = ChuBayTalk3D.new(rig)
	cup.visible = false


## Per-instance damp copies of his materials (StylePass grades them later).
static func _wet(person: PersonRig3D) -> void:
	for mesh: MeshInstance3D in person.visual().model.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.get_surface_override_material_count():
			var source := mesh.get_active_material(surface) as BaseMaterial3D
			if source == null:
				continue
			var damp := source.duplicate() as BaseMaterial3D
			damp.albedo_color = source.albedo_color * WET
			damp.roughness = 0.8
			mesh.set_surface_override_material(surface, damp)


## He is on his stool now.
func present() -> bool:
	if not host.shift_running:
		return false
	if omen:
		var gone := RestaurantShift3D.SHIFT_SECONDS - host.seconds_left
		return gone < RestaurantShift3D.SHIFT_SECONDS * omen_leave_fraction
	return true


func _process(delta: float) -> void:
	rig.visible = present()
	cup.visible = host.shift_running
	_bulb.light_energy = 0.42 + 0.06 * sin(Time.get_ticks_msec() / 700.0)
	if not rig.visible or host.player == null:
		return
	var at: Vector3 = host.player.global_position
	if Vector2(at.x - SEAT.x, at.z - SEAT.z).length() > drip_reach:
		return
	_drip -= delta
	if _drip <= 0.0:
		_drip = randf_range(drip_every.x, drip_every.y)
		Sfx.play_at("drip", rig.global_position + Vector3(0, 0.45, 0), self, randf_range(0.9, 1.1), 1.2)


## E on him: his line; the sketch line on mùng 11 also hands the paper over.
func say() -> String:
	var line := talk.say()
	if ChuBayTalk3D.is_sketch_line(line) and not GameState.has_flag(SKETCH_FLAG):
		give_sketch.call_deferred()
	return line


func give_sketch() -> void:
	GameState.set_flag(SKETCH_FLAG)
	Sfx.play("flip")
	await PaperReader.read_sketch(host, "diary", SKETCH.title, "\n".join(SKETCH.lines), PackedVector2Array(STROKES))


func hint() -> Dictionary:
	return {"at": SEAT + Vector3(0, 2.0, 0), "words": "[E] hỏi"}
