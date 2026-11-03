class_name RamShore3D
extends Node3D
## Hoa đăng on rằm (PLAN §10 H7): villagers stand at the water's edge below
## the waterfront and set paper lanterns afloat, one every few seconds; they
## drift out to sea. Their talk shows when Rin comes close (RamLinesData
## .shore). Added to the rằm evening waterfront (village map) and to the true
## ending's dawn.

const VILLAGERS: Array[Vector3] = [Vector3(-3.6, 0, 2.5), Vector3(-1.2, 0, 2.4), Vector3(1.9, 0, 2.6)]
const DRIFT := Vector3(0.05, 0, -0.32)
const MAX_LANTERNS := 22
const TALK_REACH := 3.2

@export var release_seconds := 2.2
## Villagers talk to Rin (off in the epilogue, which has its own lines).
@export var talk := true

var lanterns: Array[Node3D] = []
var _clock := 0.0
var _next := 0
var _talked := false
var _rng := RandomNumberGenerator.new()
var _text: OnScreenText


static func attach(owner: Node3D) -> RamShore3D:
	if not RamNight.is_ram():
		return null
	var shore := RamShore3D.new()
	shore.name = "RamShore"
	owner.add_child(shore)
	return shore


func _ready() -> void:
	_rng.seed = 715
	var variants: Array[String] = ["guest_1", "guest_2", "guest_3"]
	for i in VILLAGERS.size():
		var person := PersonRig3D.build(self, variants[i])
		person.position = VILLAGERS[i]
		person.rotation.y = PI  # facing the sea
	# A few already out on the water.
	for i in 8:
		var at := Vector3(_rng.randf_range(-6.0, 4.0), WaterfrontBuilder3D.WATER_Y + 0.08, _rng.randf_range(-14.0, 0.5))
		lanterns.append(RamFx3D.lantern(self, at, i % 3 == 0))
	_text = OnScreenText.new()
	add_child(_text)


func _process(delta: float) -> void:
	_clock += delta
	if _clock >= release_seconds:
		_clock = 0.0
		release()
	for lantern in lanterns:
		lantern.position += DRIFT * delta
		lantern.position.y = WaterfrontBuilder3D.WATER_Y + 0.08 + sin(Time.get_ticks_msec() / 700.0 + lantern.position.x) * 0.03
		lantern.rotation.y += delta * 0.15
	if talk and not _talked:
		var village := get_tree().current_scene as VillageScene3D
		var player: Node3D = village.player if village else null
		if player and Walker3D.near(player, to_global(VILLAGERS[1]), TALK_REACH):
			_talked = true
			RamFx3D.say_lines(_text, RamFx3D.LINES.shore, 3.6)


## One more lantern set afloat in front of the next villager.
func release() -> void:
	var from := VILLAGERS[_next % VILLAGERS.size()]
	_next += 1
	var lantern := RamFx3D.lantern(self, Vector3(from.x + _rng.randf_range(-0.4, 0.4), WaterfrontBuilder3D.WATER_Y + 0.08, 0.9), _next % 2 == 0)
	lanterns.append(lantern)
	if lanterns.size() > MAX_LANTERNS:
		lanterns.pop_front().queue_free()
	if _next % 4 == 1:
		Sfx.play("bell", 0.0)
