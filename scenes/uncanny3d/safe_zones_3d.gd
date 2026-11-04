class_name SafeZones3D
extends RefCounted
## Where a chaser (Chase3D) gives up on Rin: under a lit lamp (street lamps,
## the porch bulb, the lit pier lamp, the restaurant's lights), at the
## roadside shrine in the lane, inside his room with the door shut, and the
## restaurant street while the shift runs.

const TUNING: ProximityTuning = preload("res://data/story/proximity_tuning.tres")
const LIGHTS_META := "safe_lights"
const LIGHTS_AT_META := "safe_lights_at"
const REFRESH_MSEC := 2000


## Why `at` is safe ("room", "shrine", "shift", "light"), "" when it isn't.
static func reason(host: Node3D, at: Vector3, t: ProximityTuning = TUNING) -> String:
	var village := host as VillageScene3D
	if village:
		if VillageLayout3D.in_room(at) and village.door and not village.door.is_open:
			return "room"
		if _flat(at - VillageLaneBuilder3D.SHRINE) < t.shrine_radius:
			return "shrine"
	var street := host as RestaurantScene3D
	if street and street.shift_running and VillageLayout3D.area(at) == "street":
		return "shift"
	return "light" if lit(host, at, t) else ""


## Under a lamp that is on (bright and wide enough, not one in Rin's room).
static func lit(host: Node3D, at: Vector3, t: ProximityTuning = TUNING) -> bool:
	for light in _lights(host):
		if not is_instance_valid(light) or not light.is_visible_in_tree() or light.light_energy < t.light_min_energy:
			continue
		var reach := (light as OmniLight3D).omni_range if light is OmniLight3D else (light as SpotLight3D).spot_range
		var p := light.global_position
		if reach < t.light_min_range or VillageLayout3D.in_room(p) or p.y - at.y > 7.0:
			continue
		if _flat(p - at) < t.light_radius:
			return true
	return false


## Every point light under the host, cached for a moment (lamps rarely change).
static func _lights(host: Node3D) -> Array[Light3D]:
	var now := Time.get_ticks_msec()
	if host.has_meta(LIGHTS_META) and now - int(host.get_meta(LIGHTS_AT_META, 0)) < REFRESH_MSEC:
		var cached: Array[Light3D] = []
		cached.assign(host.get_meta(LIGHTS_META))
		return cached
	var found: Array[Light3D] = []
	for node: Node in host.find_children("*", "Light3D", true, false):
		if node is OmniLight3D or node is SpotLight3D:
			found.append(node as Light3D)
	host.set_meta(LIGHTS_META, found)
	host.set_meta(LIGHTS_AT_META, now)
	return found


static func _flat(v: Vector3) -> float:
	return Vector2(v.x, v.z).length()
