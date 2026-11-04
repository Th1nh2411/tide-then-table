class_name LookAtSpeaker3D
extends RefCounted
## Talk camera: when someone starts a line (E on a villager, the altar, anh
## Út's tea, a dead voice behind Rin), Rin's first-person view turns to them
## (FirstPersonView3D.look_toward, ~0.3 s eased; the mouse takes over at once).

const SECONDS := 0.3
## Above a standing rig's feet, roughly the eyes.
const HEAD := 1.5


## Turns to a world point. False when it can't (no view, paused, fishing).
static func at(point: Vector3, seconds: float = SECONDS) -> bool:
	var found := view()
	return found != null and found.look_toward(point, seconds)


## Turns to a person's head: their UncannyActor3D head bone when they have
## one, else `head_height` above their feet.
static func person(rig: Node3D, head_height: float = HEAD, seconds: float = SECONDS) -> bool:
	if rig == null or not rig.is_inside_tree():
		return false
	var actor := rig.get_node_or_null(UncannyActor3D.NODE_NAME) as UncannyActor3D
	return at(actor.head_position() if actor else rig.global_position + Vector3.UP * head_height, seconds)


## SceneRouter's first-person view (null in scenes without one).
static func view() -> FirstPersonView3D:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("SceneRouter/FirstPersonView") as FirstPersonView3D
