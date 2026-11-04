class_name RestaurantOmens3D
extends Node3D
## The restaurant's omen props (PLAN §10 H5), each in its normal or its
## wrong state (OmenPicker.state): Cô Năm's mâm cúng (OmenOffering3D, a
## custom: only some nights),
## the LED strip (OmenLedSign3D), a motorbike parked at the curb (on the
## "xe_khong_nguoi" night it faces the shop, headlight on, dripping, nobody
## gets off) and the street ones (StreetOmens3D). One call from the scene.

const BIKE_OMEN := "xe_khong_nguoi"
const OFFERING_POSITION := Vector3(11.9, 0, -2.5)
const LED_POSITION := Vector3(3.0, 3.05, -7.78)
## Clear of the riding lane (CustomerTraffic3D.LANE_Z) even nose-in.
const BIKE_POSITION := Vector3(-13.0, 0, 8.45)

var host: RestaurantScene3D


static func build(owner: RestaurantScene3D) -> RestaurantOmens3D:
	var omens := RestaurantOmens3D.new()
	omens.name = "Omens"
	omens.host = owner
	owner.add_child(omens)
	return omens


func _ready() -> void:
	if OmenPicker.state(OmenOffering3D.OMEN_ID) != "":
		var offering := OmenOffering3D.new()
		offering.name = "Offering"
		add_child(offering)
		offering.position = OFFERING_POSITION
		RestaurantRoomBuilder3D.solid_block(self, OFFERING_POSITION + Vector3(0, 0.4, 0), Vector3(0.95, 0.8, 0.6))
	var led := OmenLedSign3D.new()
	led.name = "LedSign"
	add_child(led)
	led.position = LED_POSITION
	_build_bike()
	var street := StreetOmens3D.new()
	street.name = "Street"
	street.host = host
	add_child(street)


func _build_bike() -> void:
	var bike := Node3D.new()
	bike.name = "ParkedBike"
	add_child(bike)
	bike.position = BIKE_POSITION
	RestaurantBatchVisuals.add(bike, "motorbike", Vector3.ZERO)
	GuestBikes3D.ground(bike)
	if not OmenPicker.is_tonight(BIKE_OMEN):
		bike.rotation.y = PI * 0.5  # parked along the curb, lights off
		return
	bike.rotation.y = PI  # nose to the shop (models face +Z)
	OmenProps3D.glow_box(bike, Vector3(0, 0.82, 0.88), Vector3(0.16, 0.1, 0.05), "fff1c2", 5.0)
	var beam := SpotLight3D.new()
	bike.add_child(beam)
	beam.position = Vector3(0, 0.82, 0.95)
	beam.rotation.y = PI  # SpotLight shines down -Z; the nose is +Z
	beam.light_color = Color("fff1c2")
	beam.light_energy = 3.0
	beam.spot_range = 9.0
	beam.spot_angle = 22.0
	# Dripped water: a small oval under the front wheel, on the pavement side
	# of the curb (not a mat under the whole bike).
	var puddle := MeshInstance3D.new()
	var oval := CylinderMesh.new()
	oval.top_radius = 0.3
	oval.bottom_radius = 0.3
	oval.height = 0.004
	oval.radial_segments = 20
	oval.rings = 1
	puddle.mesh = oval
	puddle.scale = Vector3(1.0, 1.0, 1.3)
	puddle.position = Vector3(0, 0.006, 0.55)
	puddle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var wet := StandardMaterial3D.new()
	wet.albedo_color = Color("141c24")
	wet.roughness = 0.1
	puddle.material_override = wet
	puddle.set_meta(StylePass3D.SKIP, true)  # wet: keeps its shine
	bike.add_child(puddle)
