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
	_roof(room, half, top)
	ConceptModel3D.spawn(room, "water_jar", Vector3(2.1, 0, -2.65), 0.72)
	B.solid_block(room, Vector3(2.1, 0.35, -2.65), Vector3(0.5, 0.7, 0.5))
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
	_window_frame(room, at)
	host.lighting.show_in(room.get_node("DawnWindow") as Node3D, [VillageLighting3D.Phase.MORNING])
	var lamp := BedroomBuilder3D.DOOR + Vector3(0.75, 2.2, -0.32)
	B.box(room, lamp + Vector3(0, 0.12, 0.14), Vector3(0.04, 0.04, 0.32), "2a2a28")  # bracket from the wall
	host.lighting.add_lamp(room, lamp)


## Pitched tin roof with eaves over a soffit, and a small tin awning over the door.
static func _roof(room: Node3D, half: Vector2, top: float) -> void:
	var b := BoxBatch3D.new()
	var tin := HorrorMaterials.tiled("roof_tin_rusty", 1.4)
	var soffit := HorrorMaterials.tiled("floor_wood_planks", 1.2, Color(0.45, 0.4, 0.36))
	var span := Vector3(half.x * 2.0 + 0.9, 0.08, half.y * 2.0 + 1.2)
	b.box(soffit, Vector3(0, top + 0.14, 0.0), span)
	b.gable(tin, Vector3(0, top + 0.18, 0.0), Vector3(span.x, 1.25, span.z))
	var gable_wall := HorrorMaterials.tiled("wall_plaster_old", 1.6, Color(0.82, 0.8, 0.74))
	for side: float in [-1.0, 1.0]:
		b.gable(gable_wall, Vector3(side * (half.x - 0.02), top + 0.18, 0.0), Vector3(0.06, 1.15, half.y * 2.0), 0.0)
	var door := BedroomBuilder3D.DOOR
	b.box(tin, door + Vector3(0, 2.35, -0.55), Vector3(1.6, 0.04, 1.0), 0.0, 0.25)
	for side: float in [-1.0, 1.0]:
		b.box(BoxBatch3D.color("3e3024"), door + Vector3(side * 0.7, 2.05, -0.35), Vector3(0.06, 0.06, 0.6), 0.0, -0.6)
	b.commit(room, "HouseRoof")



## Wooden frame and iron bars over the front window.
static func _window_frame(room: Node3D, at: Vector3) -> void:
	var b := BoxBatch3D.new()
	var wood := HorrorMaterials.tiled("door_wood_old", 0.8, Color(0.6, 0.55, 0.5))
	for side: float in [-1.0, 1.0]:
		b.box(wood, at + Vector3(side * 0.49, 0, -0.03), Vector3(0.08, 0.86, 0.06))
		b.box(wood, at + Vector3(0, side * 0.39, -0.03), Vector3(1.06, 0.08, 0.08))
		b.box(wood, at + Vector3(side * 0.72, 0, -0.06), Vector3(0.42, 0.7, 0.03), side * 0.5)
	for i in 4:
		b.box(BoxBatch3D.color("1c1c1c"), at + Vector3(-0.34 + float(i) * 0.225, 0, -0.04), Vector3(0.025, 0.7, 0.025))
	b.commit(room, "FrontWindowFrame")