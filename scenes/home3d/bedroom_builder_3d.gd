class_name BedroomBuilder3D
extends RefCounted
## Builds Rin's small rented room (ông Tư's old house) on the village map
## (VillageHouse3D puts it on the waterfront, in this node's local space): a
## warm bulb, the bed, the tear-off calendar on the wall, the doorway (the
## door itself is VillageDoor3D) and the morning paper pushed under it.

const B = preload("res://scenes/restaurant3d/restaurant_room_builder_3d.gd")
const HALF := Vector2(2.5, 2.0)  # room half size, x / z
const HEIGHT := 2.6
const DOOR := Vector3(1.5, 0, -2.0)
const PAPER := Vector3(1.4, 0.01, -1.55)
const CALENDAR := Vector3(-0.6, 1.5, -1.93)  # wall face is at z -1.95
## "Những điều kiêng": grandmother's note pinned left of the door.
const NOTE := Vector3(0.45, 1.42, -1.935)
const NOTE_SIZE := Vector2(0.3, 0.41)
const START := Vector3(-0.7, 0, 0.9)
## Floor beside the bed, by the pillow end (wet footprints end here).
const BEDSIDE := Vector3(-1.0, 0, 1.15)
const BED := Vector3(-1.7, 0, 0.7)
## Half the doorway's width in the north wall.
const DOOR_HALF := 0.47
const DOOR_HEIGHT := 2.05
## South window (centre x, sill-to-head centre y), clear of ông Tư's altar.
const WINDOW := Vector2(1.0, 1.5)
const WINDOW_SIZE := Vector2(0.9, 0.8)
## Writing area on the calendar sheet (under its red top), metres.
const DATE_BOX := Vector2(0.3, 0.27)


static func build(host: Node3D) -> Label3D:
	_light(host)
	var w := HALF.x * 2.0
	var d := HALF.y * 2.0
	var wall := HorrorMaterials.tiled("wall_plaster_old", 1.6, Color(0.82, 0.8, 0.74))
	# Floor a hair above the village ground (no z-fighting with it).
	B.box(host, Vector3(0, -0.04, 0), Vector3(w, 0.1, d), "5b4a3c").material_override = HorrorMaterials.tiled("tiles_cement_floor", 1.2)
	B.box(host, Vector3(0, HEIGHT + 0.05, 0), Vector3(w, 0.1, d), "3a3530").material_override = HorrorMaterials.tiled("floor_wood_planks", 1.6, Color(0.55, 0.52, 0.5))
	B.box(host, Vector3(0, HEIGHT * 0.5, HALF.y), Vector3(w, HEIGHT, 0.1), "8a8070", true).material_override = wall
	for side: float in [-1.0, 1.0]:
		B.box(host, Vector3(side * HALF.x, HEIGHT * 0.5, 0), Vector3(0.1, HEIGHT, d), "8a8070", true).material_override = wall
	# North wall with the doorway: left, right, and the lintel over it.
	var left := DOOR.x - DOOR_HALF + HALF.x
	var right := HALF.x - DOOR.x - DOOR_HALF
	B.box(host, Vector3(-HALF.x + left * 0.5, HEIGHT * 0.5, -HALF.y), Vector3(left, HEIGHT, 0.1), "8a8070", true).material_override = wall
	B.box(host, Vector3(HALF.x - right * 0.5, HEIGHT * 0.5, -HALF.y), Vector3(right, HEIGHT, 0.1), "8a8070", true).material_override = wall
	B.box(host, Vector3(DOOR.x, (HEIGHT + DOOR_HEIGHT) * 0.5, -HALF.y), Vector3(DOOR_HALF * 2.0, HEIGHT - DOOR_HEIGHT, 0.1), "8a8070", true).material_override = wall
	_window(host)
	# Bed against the west wall, a low table.
	ConceptModel3D.sized(host, "wooden_bed", BED, Vector3(1.0, 1.6, 2.0))
	B.solid_block(host, BED + Vector3(0, 0.22, 0), Vector3(1.0, 0.44, 2.0))
	ConceptModel3D.fit(host, "low_table_tea", Vector3(0.9, 0, 1.3), Vector3(0.8, 0.8, 0.7))
	B.solid_block(host, Vector3(0.9, 0.25, 1.3), Vector3(0.8, 0.5, 0.5))
	ConceptModel3D.sized(host, "wooden_wardrobe", Vector3(1.95, 0, 0.65), Vector3(0.8, 1.85, 0.5), -PI * 0.5)
	B.solid_block(host, Vector3(1.95, 0.9, 0.65), Vector3(0.5, 1.8, 0.8))
	ConceptModel3D.fit(host, "altar_ong_tu", Vector3(-0.65, 1.4, 1.76), Vector3(1.0, 0.7, 0.45), PI)
	ConceptModel3D.fit(host, "hat_hook", Vector3(2.35, 1.2, -0.8), Vector3(0.5, 0.65, 0.35), -PI * 0.5)
	# The paper on the floor just inside the door.
	B.box(host, PAPER, Vector3(0.34, 0.01, 0.24), "d9d2c0").rotation.y = 0.3
	# Tear-off calendar: a red-topped block on the wall, the date in big ink.
	B.box(host, CALENDAR, Vector3(0.36, 0.45, 0.02), "3a3026")
	HorrorMaterials.picture(host, "calendar_sheet", CALENDAR + Vector3(0, 0, 0.012), Vector2(0.34, 0.425))
	# The note: a yellowed page on a red pin, its title in ink.
	HorrorMaterials.picture(host, "paper_diary_page", NOTE, NOTE_SIZE).rotation.z = 0.04
	B.box(host, NOTE + Vector3(0, NOTE_SIZE.y * 0.5 - 0.03, 0.01), Vector3(0.025, 0.025, 0.02), "a8262c")
	var heading := B.label(host, "Những điều kiêng", NOTE + Vector3(0, 0.13, 0.004), 18, "27324a")
	heading.pixel_size = 0.0015
	var date := B.label(host, "", CALENDAR + Vector3(0, -0.03, 0.016), 34, "2a2230")
	date.pixel_size = 0.003
	return date


## Puts `words` on the calendar, shrunk to fit its sheet (PaperFit).
static func set_date(date: Label3D, words: String) -> void:
	date.text = words
	PaperFit.fit_label3d(date, DATE_BOX, 34, 10)


## South window: dim dawn glass behind iron bars in a wooden frame, the
## shutters folded open outside.
static func _window(host: Node3D) -> void:
	var z := HALF.y
	var at := Vector3(WINDOW.x, WINDOW.y, z)
	var pane := B.box(host, at + Vector3(0, 0, -0.065), Vector3(WINDOW_SIZE.x, WINDOW_SIZE.y, 0.02), "6f8296")
	var glow := pane.material_override as StandardMaterial3D
	glow.emission_enabled = true
	glow.emission = Color("4f6a83")
	glow.emission_energy_multiplier = 0.35
	B.box(host, at + Vector3(0, 0, 0.06), Vector3(WINDOW_SIZE.x, WINDOW_SIZE.y, 0.01), "1d1f22")  # seen from outside
	var wood := HorrorMaterials.tiled("door_wood_old", 0.8, Color(0.6, 0.55, 0.5))
	for side: float in [-1.0, 1.0]:
		B.box(host, at + Vector3(side * (WINDOW_SIZE.x * 0.5 + 0.04), 0, -0.08), Vector3(0.08, WINDOW_SIZE.y + 0.16, 0.06), "4a3a2c").material_override = wood
		B.box(host, at + Vector3(0, side * (WINDOW_SIZE.y * 0.5 + 0.04), -0.08), Vector3(WINDOW_SIZE.x + 0.16, 0.08, 0.08), "4a3a2c").material_override = wood
		# Shutters folded back against the outside wall.
		B.box(host, at + Vector3(side * (WINDOW_SIZE.x * 0.75 + 0.06), 0, 0.09), Vector3(WINDOW_SIZE.x * 0.5, WINDOW_SIZE.y, 0.03), "4a3a2c").material_override = wood
	for i in 4:
		var x := (float(i) + 0.5) / 4.0 * WINDOW_SIZE.x - WINDOW_SIZE.x * 0.5
		B.box(host, at + Vector3(x, 0, -0.085), Vector3(0.025, WINDOW_SIZE.y, 0.025), "1c1c1c")


## The bulb, and pale dawn through the window ("DawnWindow": the village
## lighting turns it off after dark).
static func _light(host: Node3D) -> void:
	var bulb := OmniLight3D.new()
	host.add_child(bulb)
	bulb.position = Vector3(0.4, HEIGHT - 0.35, -0.2)
	bulb.light_color = Color("ffcf94")
	bulb.light_energy = 0.9
	bulb.omni_range = 5.0
	bulb.shadow_enabled = true
	var dawn := SpotLight3D.new()
	dawn.name = "DawnWindow"
	host.add_child(dawn)
	dawn.position = Vector3(WINDOW.x, 1.6, HALF.y - 0.15)
	dawn.rotation_degrees.x = -25.0
	dawn.light_color = Color("9fb4d4")
	dawn.light_energy = 1.2
	dawn.spot_range = 6.0
	dawn.spot_angle = 40.0
	dawn.shadow_enabled = true
