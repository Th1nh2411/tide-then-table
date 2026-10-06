class_name SeaZone
extends ColorRect
## Water area belonging to one fishing zone. The rect is both the visual
## (shallow = light, open sea = dark) and where the spawner places spots.

@export var zone: FishData.Zone = FishData.Zone.NEARSHORE
## Fishing spots spawned here at the start of each day.
@export var spot_count: int = 4


## Topmost visible SeaZone under `pos` among `zones_root`'s children
## (later children are drawn on top, e.g. the fog over the open sea).
static func find_at(zones_root: Node, pos: Vector2) -> SeaZone:
	var children := zones_root.get_children()
	children.reverse()
	for child in children:
		var sea_zone := child as SeaZone
		if sea_zone and sea_zone.visible and sea_zone.get_global_rect().has_point(pos):
			return sea_zone
	return null
