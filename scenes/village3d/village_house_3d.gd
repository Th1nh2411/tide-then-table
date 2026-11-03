class_name VillageHouse3D
extends RefCounted
## Rin's house on the waterfront (village map): the walkable room inside
## (BedroomBuilder3D in a "House" node at VillageLayout3D.ROOM), its door
## (VillageDoor3D), a tin roof over it, a front window that glows at night
## and a porch bulb by the door.

const B = preload("res://scenes/restaurant3d/restaurant_room_builder_3d.gd")


static func build(host: VillageScene3D) -> void:
	var room := Node3D.new()
	room.name = "House"
	host.add_child(room)
	room.position = VillageLayout3D.ROOM
	host.calendar = BedroomBuilder3D.build(room)
	host.door = VillageDoor3D.build(room)
	var half := BedroomBuilder3D.HALF
	var top := BedroomBuilder3D.HEIGHT
	B.box(room, Vector3(0, top + 0.18, 0.1), Vector3(half.x * 2.0 + 0.9, 0.12, half.y * 2.0 + 1.1), "5b3a2e").material_override = HorrorMaterials.tiled("roof_tin_rusty", 1.4)
	# A low concrete step outside the door.
	B.box(room, BedroomBuilder3D.DOOR + Vector3(0, 0.03, -0.45), Vector3(1.3, 0.06, 0.6), "77736a")
	# Front window (sea side): dark by day, warm at night.
	var at := Vector3(-1.0, 1.55, -half.y - 0.06)
	B.box(room, at, Vector3(0.9, 0.7, 0.02), "2b2a26")
	var lit := B.box(room, at + Vector3(0, 0, -0.005), Vector3(0.9, 0.7, 0.02), "e9b36a")
	var glow := lit.material_override as StandardMaterial3D
	glow.emission_enabled = true
	glow.emission = Color("ffb35a")
	glow.emission_energy_multiplier = 0.6
	host.lighting.show_in(lit, [VillageLighting3D.Phase.NIGHT])
	host.lighting.show_in(room.get_node("DawnWindow") as Node3D, [VillageLighting3D.Phase.MORNING])
	host.lighting.add_lamp(room, BedroomBuilder3D.DOOR + Vector3(0.75, 2.25, -0.2))
