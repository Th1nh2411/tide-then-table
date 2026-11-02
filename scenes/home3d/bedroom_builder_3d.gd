class_name BedroomBuilder3D
extends RefCounted
## Builds Rin's small rented room (ông Tư's old house) for BedroomScene3D:
## dim dawn light through the window, a warm bulb, the bed, the tear-off
## calendar on the wall, the door and the morning paper pushed under it.

const B = preload("res://scenes/restaurant3d/restaurant_room_builder_3d.gd")
const HALF := Vector2(2.5, 2.0)  # room half size, x / z
const HEIGHT := 2.6
const DOOR := Vector3(1.5, 0, -2.0)
const PAPER := Vector3(1.4, 0.01, -1.55)
const CALENDAR := Vector3(-0.6, 1.5, -1.93)  # wall face is at z -1.95
const START := Vector3(-0.7, 0, 0.9)


static func build(host: Node3D) -> Label3D:
	_light(host)
	var w := HALF.x * 2.0
	var d := HALF.y * 2.0
	var wall := HorrorMaterials.tiled("wall_plaster_old", 1.6, Color(0.82, 0.8, 0.74))
	B.box(host, Vector3(0, -0.05, 0), Vector3(w, 0.1, d), "5b4a3c").material_override = HorrorMaterials.tiled("floor_wood_planks", 1.2)
	B.box(host, Vector3(0, HEIGHT + 0.05, 0), Vector3(w, 0.1, d), "3a3530").material_override = HorrorMaterials.tiled("floor_wood_planks", 1.6, Color(0.55, 0.52, 0.5))
	for side: float in [-1.0, 1.0]:
		B.box(host, Vector3(0, HEIGHT * 0.5, side * HALF.y), Vector3(w, HEIGHT, 0.1), "8a8070", true).material_override = wall
		B.box(host, Vector3(side * HALF.x, HEIGHT * 0.5, 0), Vector3(0.1, HEIGHT, d), "8a8070", true).material_override = wall
	# Window in the south wall: a pale pane of dawn.
	var pane := B.box(host, Vector3(0, 1.5, HALF.y - 0.06), Vector3(1.0, 0.8, 0.02), "9fb4c4")
	var glow := pane.material_override as StandardMaterial3D
	glow.emission_enabled = true
	glow.emission = Color("6f8aa3")
	glow.emission_energy_multiplier = 0.8
	# Bed against the west wall, a low table, a hook with ông Tư's nón lá.
	B.box(host, Vector3(-1.7, 0.22, 0.7), Vector3(1.0, 0.44, 2.0), "6b5240", true)
	B.box(host, Vector3(-1.7, 0.47, 0.7), Vector3(0.94, 0.08, 1.9), "d8cdb4")
	B.box(host, Vector3(-1.7, 0.55, 1.45), Vector3(0.6, 0.1, 0.35), "e8e0cc")
	B.box(host, Vector3(0.9, 0.25, 1.3), Vector3(0.8, 0.5, 0.5), "6b5240", true)
	# Door with its handle; light leaks under it.
	B.box(host, DOOR + Vector3(0, 1.0, 0.03), Vector3(0.9, 2.0, 0.06), "4a3a2e")
	HorrorMaterials.picture(host, "door_wood_old", DOOR + Vector3(0, 1.0, 0.065), Vector2(0.9, 2.0))
	# The paper on the floor just inside the door.
	B.box(host, PAPER, Vector3(0.34, 0.01, 0.24), "d9d2c0").rotation.y = 0.3
	# Tear-off calendar: a red-topped block on the wall, the date in big ink.
	B.box(host, CALENDAR, Vector3(0.36, 0.45, 0.02), "3a3026")
	HorrorMaterials.picture(host, "calendar_sheet", CALENDAR + Vector3(0, 0, 0.012), Vector2(0.34, 0.425))
	var date := B.label(host, "", CALENDAR + Vector3(0, -0.03, 0.016), 34, "2a2230")
	date.pixel_size = 0.003
	return date


static func _light(host: Node3D) -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("0d0f14")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("5d6a78")
	settings.ambient_light_energy = 0.35
	environment.environment = settings
	host.add_child(environment)
	var bulb := OmniLight3D.new()
	host.add_child(bulb)
	bulb.position = Vector3(0.4, HEIGHT - 0.35, -0.2)
	bulb.light_color = Color("ffcf94")
	bulb.light_energy = 0.9
	bulb.omni_range = 5.0
	bulb.shadow_enabled = true
	var dawn := SpotLight3D.new()
	host.add_child(dawn)
	dawn.position = Vector3(0, 1.6, HALF.y + 0.4)
	dawn.rotation_degrees.x = -25.0
	dawn.light_color = Color("9fb4d4")
	dawn.light_energy = 1.2
	dawn.spot_range = 6.0
	dawn.spot_angle = 40.0
	dawn.shadow_enabled = true
