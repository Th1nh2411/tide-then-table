class_name Walker3D
extends RefCounted
## Ground helpers for first-person places (village spots, rằm props).


## Flat distance on the ground, for "is Rin at this spot".
static func near(player: Node3D, point: Vector3, reach: float) -> bool:
	var at := player.global_position
	return Vector2(at.x - point.x, at.z - point.z).length() < reach
