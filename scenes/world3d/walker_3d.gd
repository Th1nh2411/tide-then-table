class_name Walker3D
extends RefCounted
## WASD walking for the small first-person places (bedroom, waterfront):
## direction from the camera (FirstPersonView3D's), flat on the ground.


static func make_player(parent: Node3D, at: Vector3) -> CharacterBody3D:
	var player := CharacterBody3D.new()
	parent.add_child(player)
	player.position = at
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.6
	shape.shape = capsule
	shape.position.y = 0.8
	player.add_child(shape)
	return player


static func step(player: CharacterBody3D, camera: Camera3D, speed: float) -> void:
	var axes := Input.get_vector("turn_left", "turn_right", "throttle_forward", "throttle_back")
	var right := camera.global_basis.x
	var forward := camera.global_basis.z
	right.y = 0.0
	forward.y = 0.0
	var direction := (right.normalized() * axes.x + forward.normalized() * axes.y).limit_length(1.0)
	player.velocity = direction * speed
	player.move_and_slide()


## Flat distance on the ground, for "is Rin at this spot".
static func near(player: Node3D, point: Vector3, reach: float) -> bool:
	var at := player.global_position
	return Vector2(at.x - point.x, at.z - point.z).length() < reach
