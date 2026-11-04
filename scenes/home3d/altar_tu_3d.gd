class_name AltarTu3D
extends RefCounted
## Ông Tư's altar in Rin's room (BedroomBuilder3D "altar_ong_tu"): E lights
## a stick of incense (it keeps glowing for the rest of the day) and the old
## man's voice answers with one short dead whisper a day
## (data/story/ong_tu.tres; tonight's omen first when he has one).

const LINES: NpcLinesData = preload("res://data/story/ong_tu.tres")
## Room-local point E aims at (the shelf, BedroomBuilder3D places it at -0.65, 1.4, 1.76).
const AIM := Vector3(-0.65, 1.6, 1.68)
const INCENSE := Vector3(-0.58, 1.66, 1.58)

var talk := NpcTalk3D.new(null, LINES)
var incense: Node3D


## E on the altar: incense (once) and the whisper.
func light(host: RestaurantScene3D) -> void:
	if incense == null:
		incense = _incense(host)
		Sfx.play("tock")
	host._show_note(talk.say())


func _incense(host: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "AltarIncense"
	host.add_child(root)
	root.position = VillageLayout3D.room_point(INCENSE)
	OmenProps3D.box(root, Vector3(0, 0.03, 0), Vector3(0.07, 0.06, 0.07), "6b5a3a")  # the pot
	for i in 3:
		var x := (i - 1) * 0.018
		var stick := OmenProps3D.box(root, Vector3(x, 0.15, 0), Vector3(0.006, 0.2, 0.006), "8a3a2a")
		stick.rotation.z = (i - 1) * 0.12
		OmenProps3D.glow_box(root, Vector3(x * 2.4, 0.25, 0), Vector3(0.012, 0.012, 0.012), "ff7a3a", 4.0)
	OmenProps3D.light(root, Vector3(0, 0.28, 0), "ff9a5a", 0.25, 0.9)
	return root
