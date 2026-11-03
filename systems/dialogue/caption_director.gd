class_name CaptionDirector
extends RefCounted
## Pure: the direction word of a sound placed in the world, seen from the
## camera ("sau lưng", "bên trái", ...), and the caption's final text.

## Wider than this (degrees off the view) = beside, not in front.
const FRONT_DEG := 40.0
## Beyond this = behind.
const BACK_DEG := 130.0
## Closer than this (m, flat) the sound has no side.
const NEAR := 0.3


static func direction(view: Transform3D, at: Vector3) -> String:
	var local := view.affine_inverse() * at
	var flat := Vector2(local.x, -local.z)
	if flat.length() < NEAR:
		return ""
	var deg := absf(rad_to_deg(atan2(flat.x, flat.y)))
	if deg <= FRONT_DEG:
		return "phía trước"
	if deg >= BACK_DEG:
		return "sau lưng"
	return "bên phải" if flat.x > 0.0 else "bên trái"


## "[text — where]"; brackets are added unless already there.
static func compose(text: String, where: String = "") -> String:
	var body := text.trim_prefix("[").trim_suffix("]")
	if where != "":
		body += " — " + where
	return "[" + body + "]"
