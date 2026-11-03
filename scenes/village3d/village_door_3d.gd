class_name VillageDoor3D
extends Node3D
## The wooden door of Rin's room (village map): E opens / closes it from
## either side. It swings out towards the sea on a hinge at its left edge;
## the leaf carries its own collider, so a closed door keeps Rin in.
## Placed at the doorway's foot (BedroomBuilder3D.DOOR, room space).

const WIDTH := 0.9
const HEIGHT := 2.0
const THICK := 0.06

@export var open_angle := 1.65
@export var swing_seconds := 0.55

var is_open := false
var _hinge := Node3D.new()
var _tween: Tween


static func build(room: Node3D) -> VillageDoor3D:
	var door := VillageDoor3D.new()
	door.name = "Door"
	room.add_child(door)
	door.position = BedroomBuilder3D.DOOR
	return door


func _ready() -> void:
	add_child(_hinge)
	_hinge.position = Vector3(-WIDTH * 0.5, 0, 0)
	var middle := Vector3(WIDTH * 0.5, HEIGHT * 0.5, 0)
	RestaurantRoomBuilder3D.box(_hinge, middle, Vector3(WIDTH, HEIGHT, THICK), "4a3a2e")
	HorrorMaterials.picture(_hinge, "door_wood_old", middle + Vector3(0, 0, THICK * 0.5 + 0.004), Vector2(WIDTH, HEIGHT))
	HorrorMaterials.picture(_hinge, "door_wood_old", middle - Vector3(0, 0, THICK * 0.5 + 0.004), Vector2(WIDTH, HEIGHT), PI)
	RestaurantRoomBuilder3D.box(_hinge, Vector3(WIDTH - 0.1, 1.0, 0), Vector3(0.05, 0.05, THICK + 0.08), "b8a070")
	var body := StaticBody3D.new()
	_hinge.add_child(body)
	body.position = middle
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(WIDTH, HEIGHT, THICK + 0.04)
	shape.shape = box
	body.add_child(shape)


## Middle of the doorway at eye height (what E aims at).
func aim_point() -> Vector3:
	return global_position + Vector3(0, 1.1, 0)


func toggle() -> void:
	set_open(not is_open)


## `silent`: no creak (UncannyScene3D closes it while Rin is away).
func set_open(open: bool, animate: bool = true, silent: bool = false) -> void:
	if open == is_open:
		return
	is_open = open
	if _tween:
		_tween.kill()
	var angle := open_angle if open else 0.0
	if not silent:
		Sfx.play("door_open" if open else "door_close", 0.04)
	if not animate or not is_inside_tree():
		_hinge.rotation.y = angle
		return
	_tween = create_tween()
	_tween.tween_property(_hinge, "rotation:y", angle, swing_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
