class_name VillageNpcs3D
extends Node3D
## The villagers outside the restaurant street (PLAN §10 "Mọi nhân vật đều
## có vai trò"), each with one short E line a day from data:
## - ông Tám (data/story/ong_tam.tres): sits patching a thúng on the
##   waterfront at dawn; ghost-month customs; on mùng 9 after a reset his
##   first line names, vaguely, the kind of thing the wrong night missed.
## - chú Hai (data/story/chu_hai.tres, ChuHai3D): in the lane, pushing his
##   bike to market at dawn, smoking by his door at night; the second tell of
##   the name-call omen. From mùng 14 he is gone, only his bike is left.
## Nobody is out during the shift, nobody comes into Rin's room.
## One line in VillageScene3D._ready; E and the prompt go through here.

const TAM: NpcLinesData = preload("res://data/story/ong_tam.tres")
const NODE_NAME := "VillageNpcs"
## Ông Tám's stool, waterfront-local: beside the thúng on the sand (WaterfrontLife3D).
const TAM_SEAT := Vector3(0.25, 0, 3.0)
const TAM_REACH := 2.0

var host: VillageScene3D
var tam: PersonRig3D
var tam_talk: NpcTalk3D
var hai: ChuHai3D
var _stool: Node3D


static func attach(owner: VillageScene3D) -> VillageNpcs3D:
	var npcs := VillageNpcs3D.new()
	npcs.name = NODE_NAME
	npcs.host = owner
	owner.add_child(npcs)
	return npcs


func _ready() -> void:
	var seat := VillageLayout3D.waterfront_point(TAM_SEAT)
	_stool = RestaurantRoomBuilder3D.STOOL_PILOT.instantiate()
	add_child(_stool)
	_stool.position = seat
	_stool.scale = Vector3.ONE * WorldPresentation3D.RESTAURANT_STOOL_SCALE
	tam = PersonRig3D.build(self, "ong_tam")
	tam.name = "OngTam"
	tam.position = seat
	tam.rotation.y = 0.95  # between the thúng and the houses (Rin comes from there)
	tam.set_seated(true)
	tam_talk = NpcTalk3D.new(tam, TAM, TAM_REACH)
	tam_talk.turn = false
	tam_talk.head_height = 1.1
	hai = ChuHai3D.new()
	hai.name = "ChuHai"
	hai.host = host
	add_child(hai)
	_update()


func _process(_delta: float) -> void:
	_update()


func phase() -> VillageLighting3D.Phase:
	return host.lighting.phase if host.lighting else VillageLighting3D.Phase.MORNING


func _update() -> void:
	var morning := phase() == VillageLighting3D.Phase.MORNING
	tam.visible = morning
	_stool.visible = morning
	hai.set_phase(phase())


## Who E would talk to now (null = nobody).
func talker() -> NpcTalk3D:
	if host.player == null or get_tree().paused:
		return null
	var at := host.player.global_position
	for talk: NpcTalk3D in [tam_talk, hai.talk]:
		if talk and talk.can_talk(at, host.demo_camera):
			return talk
	return null


## E: true when someone answered.
func interact() -> bool:
	var talk := talker()
	if talk == null:
		return false
	host._show_note(talk.say())
	return true


func prompt() -> String:
	var talk := talker()
	return "" if talk == null else "hỏi"
