class_name VillageAudio3D
extends RefCounted
## Sound by where Rin is on the village map: the ambience + horror bed of the
## area (VillageLayout3D.area) and a footstep for the ground under him every
## STEP_METRES (Sfx.step: planks on the pier, sand on the waterfront, a dull
## scuff on dirt / tiles). The beds are built once at load (no hitch later).

const STEP_METRES := 0.72
## Area -> [ambience loop, bed mix].
const AREAS := {
	"house": ["sea", "house"],
	"lane": ["street", "lane"],
	"waterfront": ["sea", "waterfront"],
	"street": ["street", "street"],
}

var area := ""
var _walked := 0.0


static func prebuild() -> void:
	var beds: Array[String] = []
	for name: String in AREAS:
		beds.append(str((AREAS[name] as Array)[1]))
	Sfx.prebuild_beds(beds)


## Call every physics frame with how far Rin moved.
func update(at: Vector3, moved: float) -> void:
	var now := VillageLayout3D.area(at)
	if now != area:
		area = now
		var mix: Array = AREAS[now]
		Sfx.ambience(str(mix[0]))
		Sfx.bed(str(mix[1]))
	_walked += moved
	if _walked >= STEP_METRES:
		_walked = 0.0
		Sfx.step(VillageLayout3D.surface(at))
