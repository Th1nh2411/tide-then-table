class_name CutsceneMarkers3D
extends RefCounted
## Authored 3D staging points for cutscenes, per scene kind. Derived from the
## 2D marker layout (pixels) so the same .tres files work in both versions.

const BASE_ZOOM := {"restaurant": 1.0, "sea": 2.0}

## kind -> marker name -> 2D pixel position of the original scene.
const PIXELS := {
	"restaurant": {
		"room_view": Vector2(320, 180), "rin_spot": Vector2(296, 136), "door": Vector2(-12, 216),
		"bao_stop": Vector2(344, 136), "kitchen_view": Vector2(340, 140), "bao_stove": Vector2(376, 104),
		"nam_shop": Vector2(528, 94), "nam_visit": Vector2(440, 134), "nam_counter": Vector2(504, 124),
		"guest_seat": Vector2(216, 104), "vy_start": Vector2(-12, 136), "vy_stop": Vector2(268, 138),
		"board_view": Vector2(330, 230), "run_view": Vector2(170, 190), "run_mid": Vector2(150, 216),
	},
	"sea": {
		"dock_view": Vector2(990, 1150), "crate_spot": Vector2(1010, 1172), "rin_start": Vector2(1000, 1150),
		"rin_stop": Vector2(1022, 1176), "cat_start": Vector2(890, 1192), "cat_sneak": Vector2(995, 1176),
		"rin_pet": Vector2(1006, 1178), "fog_view": Vector2(1680, 260), "fog_glow": Vector2(1720, 190),
	},
}

## 2D pixel -> world position in the 3D scene of that kind.
static func to_world(kind: String, pixel: Vector2) -> Vector3:
	if kind == "sea":
		return Vector3((pixel.x - 1000.0) / 30.0, 0.0, 3.0 + (pixel.y - 1150.0) / 30.0)
	return Vector3((pixel.x - 320.0) / 45.0 + 2.0, 0.0, (pixel.y - 150.0) / 45.0 - 1.5)


static func has_kind(kind: String) -> bool:
	return PIXELS.has(kind)


## Marker names a cutscene uses (camera / spawn / move_to), "@group" ones skipped.
static func used_names(cutscene: Cutscene) -> PackedStringArray:
	var names := PackedStringArray()
	for command in CutsceneScript.parse(cutscene.script_text):
		var args: PackedStringArray = command["args"]
		var marker := ""
		match command["cmd"]:
			"camera":
				marker = args[0]
			"move_to":
				marker = args[1]
			"spawn":
				marker = args[2]
		if marker != "" and not marker.begins_with("@"):
			names.append(marker)
	return names
