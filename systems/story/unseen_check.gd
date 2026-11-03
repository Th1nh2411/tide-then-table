class_name UnseenCheck
extends RefCounted
## "Is Rin looking at it?" for the uncanny tricks (pure math + one ray):
## things move only while unseen, i.e. outside the camera's view (frustum
## test with a margin, so nothing pops at the screen edge) or inside it but
## hidden behind something solid.

## Extra degrees around the frustum still counted as "in view".
const MARGIN_DEG := 8.0


## Whether `point` is inside a camera's view cone: eye position, forward
## direction, vertical fov (degrees, Camera3D.fov with KEEP_HEIGHT), aspect.
static func in_view(eye: Vector3, forward: Vector3, fov_deg: float, aspect: float, point: Vector3,
		margin_deg: float = MARGIN_DEG, far: float = 300.0) -> bool:
	var ahead := forward.normalized()
	var to := point - eye
	var depth := to.dot(ahead)
	if depth <= 0.01 or depth > far:
		return false
	var side := ahead.cross(Vector3.UP)
	if side.length_squared() < 0.0001:
		side = Vector3.RIGHT  # looking straight up / down
	side = side.normalized()
	var up := side.cross(ahead).normalized()
	var half_v := deg_to_rad(fov_deg * 0.5)
	var half_h := atan(tan(half_v) * aspect)
	var margin := deg_to_rad(margin_deg)
	return absf(atan2(to.dot(side), depth)) <= half_h + margin \
		and absf(atan2(to.dot(up), depth)) <= half_v + margin


## Unseen = out of view, or in view but behind something.
static func unseen(visible_in_view: bool, occluded: bool) -> bool:
	return not visible_in_view or occluded


## Camera-node version of in_view.
static func camera_sees(camera: Camera3D, point: Vector3, margin_deg: float = MARGIN_DEG) -> bool:
	if camera == null:
		return false
	var size := camera.get_viewport().get_visible_rect().size
	var aspect := size.x / maxf(size.y, 1.0)
	return in_view(camera.global_position, -camera.global_basis.z, camera.fov, aspect, point, margin_deg, camera.far)


## A solid body between the eye and the point (ray against physics).
static func occluded(camera: Camera3D, point: Vector3, exclude: Array[RID] = []) -> bool:
	if camera == null or not camera.is_inside_tree():
		return false
	var space := camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, point)
	query.exclude = exclude
	return not space.intersect_ray(query).is_empty()


## True when none of `points` (head, feet...) can be seen right now.
static func all_unseen(camera: Camera3D, points: Array[Vector3]) -> bool:
	if camera == null:
		return true
	for p in points:
		var seen := camera_sees(camera, p)
		if seen and not occluded(camera, p):
			return false
	return true


## Degrees between where the camera looks and `point` (0 = dead centre).
static func look_angle(camera: Camera3D, point: Vector3) -> float:
	if camera == null:
		return 180.0
	return rad_to_deg((-camera.global_basis.z).angle_to(point - camera.global_position))
