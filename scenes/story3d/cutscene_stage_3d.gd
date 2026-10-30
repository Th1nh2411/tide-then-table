class_name CutsceneStage3D
extends Node
## 3D staging for StoryBridge3D: marker nodes (CutsceneMarkers), actors that
## walk between them, a cutscene camera, emotes, rain and slow-mo.

const KIND_COLORS := {
	"rin": Color(0.25, 0.5, 0.85), "bao": Color(0.85, 0.55, 0.2), "vy": Color(0.85, 0.35, 0.5),
	"co_nam": Color(0.5, 0.7, 0.35), "guest": Color(0.7, 0.7, 0.6), "guest_regular": Color(0.8, 0.65, 0.4),
	"cat": Color(0.9, 0.75, 0.4), "crate": Color(0.55, 0.38, 0.2), "glow": Color(0.4, 1.0, 1.0),
}
const EMOTE_TEXT := {"!": "!", "?": "?", "...": "...", "heart": "<3", "note": "~"}
const WALK_UNITS_PER_SECOND_MIN := 0.01

var kind: String = ""
var markers: Node3D
var effects: CutsceneEffects
var _camera: Camera3D
var _previous: Camera3D
var _offset: Vector3 = Vector3(0, 8, 10)
var _focus: Vector3 = Vector3.ZERO
var _base_size: float = 14.0
var _zoom: float = 1.0
var _actors: Dictionary = {}
var _hidden: Array[Node3D] = []
var _gameplay: Dictionary = {}
var _clock: float = 0.0
var _rig: Node3D


func setup(scene_kind: String) -> void:
	kind = scene_kind
	markers = Node3D.new()
	markers.name = "CutsceneMarkers"
	add_child(markers)
	var table: Dictionary = CutsceneMarkers3D.PIXELS.get(kind, {})
	for marker_name: String in table:
		var node := Marker3D.new()
		node.name = marker_name
		markers.add_child(node)
		node.position = CutsceneMarkers3D.to_world(kind, table[marker_name])
	effects = CutsceneEffects.new()
	add_child(effects)
	_camera = Camera3D.new()
	add_child(_camera)
	_rig = Node3D.new()
	add_child(_rig)


func begin() -> void:
	_previous = get_viewport().get_camera_3d()
	_zoom = CutsceneMarkers3D.BASE_ZOOM.get(kind, 1.0)
	if _previous:
		var forward := -_previous.global_basis.z
		var hit := _previous.global_position
		if absf(forward.y) > 0.001:
			hit = _previous.global_position + forward * (-_previous.global_position.y / forward.y)
		_focus = hit
		_offset = _previous.global_position - hit
		_camera.projection = _previous.projection
		_camera.fov = _previous.fov
		_base_size = _previous.size
		_camera.size = _base_size
	_apply_camera(_focus, _zoom)
	_camera.make_current()
	for group: StringName in [&"customers", &"staff"]:
		for node in get_tree().get_nodes_in_group(group):
			var n3 := node as Node3D
			if n3 and n3.visible:
				n3.visible = false
				_hidden.append(n3)


func end() -> void:
	reset()
	for actor: Node3D in _actors.values():
		actor.queue_free()
	_actors.clear()
	for real: Node3D in _gameplay.values():
		if is_instance_valid(real):
			real.visible = true
	_gameplay.clear()
	for node in _hidden:
		if is_instance_valid(node):
			node.visible = true
	_hidden.clear()
	if _previous and is_instance_valid(_previous):
		_previous.make_current()


func reset() -> void:
	effects.reset()


func marker(name_: String) -> Vector3:
	var offset := Vector3.ZERO
	var node: Node3D = null
	if name_.begins_with("@"):
		var parts := name_.substr(1).split("+")
		node = get_tree().get_first_node_in_group(parts[0]) as Node3D
		if node == null and parts[0] == "boat":
			node = get_parent().get_parent().get_node_or_null("Boat") as Node3D
		if parts.size() > 1:
			var xy := parts[1].split(",")
			offset = Vector3(float(xy[0]), 0.0, float(xy[1]) if xy.size() > 1 else 0.0) / 30.0
	else:
		node = markers.get_node_or_null(name_) as Node3D
	if node == null:
		push_warning("Cutscene marker '%s' not found" % name_)
		return _focus
	var p := node.global_position
	return Vector3(p.x, 0.0, p.z) + offset


## Runs a staging command. Returns true when the command was handled here.
func run(cmd: String, args: PackedStringArray, skipping: bool) -> bool:
	match cmd:
		"camera":
			var seconds := _num(args, 1, 1.0)
			await _move_camera(marker(args[0]), seconds, _num(args, 2, _zoom), skipping)
		"spawn":
			var actor := _make_actor(args[1], skipping)
			actor.scale = Vector3.ONE * _num(args, 3, 1.0)
			if actor.get_parent() == null:
				_rig.add_child(actor)
			actor.global_position = marker(args[2])
			_take_over(actor, args[1])
			if args[1] == "rin_faint" and _gameplay.has("rin"):
				_stand_in(actor, _gameplay["rin"])
			_actors[args[0]] = actor
		"move_to":
			var actor := _actors.get(args[0]) as Node3D
			if actor:
				var target := marker(args[1])
				if skipping:
					actor.global_position = target
				else:
					await _walk(actor, target, _num(args, 2, 1.0))
		"face":
			var actor := _actors.get(args[0]) as Node3D
			if actor:
				actor.rotation.y = -PI * 0.5 if args[1] == "left" else PI * 0.5
				_idle(actor)
		"emote":
			var actor := _actors.get(args[0]) as Node3D
			if actor and not skipping:
				_emote(actor, str(EMOTE_TEXT.get(args[1], args[1])), _num(args, 2, 1.0))
		"remove":
			var gone := _actors.get(args[0]) as Node
			if gone:
				gone.queue_free()
				_actors.erase(args[0])
		"rain":
			effects.set_rain(args[0] == "on")
		"slow":
			if skipping:
				effects.reset()
			else:
				await effects.slow(_num(args, 0, 1.0), _num(args, 1, 0.5))
		_:
			return false
	return true


func actor(name_: String) -> Node3D:
	return _actors.get(name_) as Node3D


func _apply_camera(focus: Vector3, zoom_: float) -> void:
	_focus = focus
	_zoom = zoom_
	var rel := maxf(zoom_ / CutsceneMarkers3D.BASE_ZOOM.get(kind, 1.0), 0.05)
	if _camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		_camera.size = _base_size / rel
		_camera.global_position = focus + _offset
	else:
		_camera.global_position = focus + _offset / rel
	_camera.look_at(focus + Vector3.UP * 0.7)


func _move_camera(target: Vector3, seconds: float, to_zoom: float, instant: bool) -> void:
	if instant or seconds <= 0.0:
		_apply_camera(target, to_zoom)
		return
	var from_focus := _focus
	var from_zoom := _zoom
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(func(t: float) -> void:
		_apply_camera(from_focus.lerp(target, t), lerpf(from_zoom, to_zoom, t)), 0.0, 1.0, seconds)
	await tween.finished


func _walk(actor_: Node3D, target: Vector3, seconds: float) -> void:
	var delta := target - actor_.global_position
	if delta.length() < WALK_UNITS_PER_SECOND_MIN:
		return
	var from := actor_.global_position
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(func(t: float) -> void:
		if not is_instance_valid(actor_):
			return
		var before := actor_.global_position
		actor_.global_position = from.lerp(target, t)
		var rig := actor_ as PersonRig3D
		if rig:
			rig.drive_ground_motion(actor_.global_position-before,get_process_delta_time()), 0.0, 1.0, maxf(seconds, 0.01))
	await tween.finished
	_idle(actor_)


func _emote(actor_: Node3D, text: String, seconds: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.02
	label.font_size = 48
	label.position = Vector3(0, 2.0, 0)
	label.process_mode = Node.PROCESS_MODE_ALWAYS
	actor_.add_child(label)
	# Tween lives on the label, so it dies quietly if the actor is removed first.
	var tween := label.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(maxf(seconds, 0.1))
	tween.tween_callback(label.queue_free)


func _idle(actor_: Node3D) -> void:
	var rig := actor_ as PersonRig3D
	if rig:
		rig.drive_ground_motion(Vector3.ZERO,maxf(get_process_delta_time(),.001),false)


## Hides the gameplay rig of the same character and copies its facing.
func _take_over(actor_: Node3D, actor_kind: String) -> void:
	if not actor_ is PersonRig3D or actor_kind == "guest" or _gameplay.has(actor_kind):
		return
	var real := get_tree().get_first_node_in_group("person_" + actor_kind) as Node3D
	if real == null or not real.visible:
		return
	real.visible = false
	_gameplay[actor_kind] = real
	_stand_in(actor_, real)


## Puts a cutscene actor where the gameplay one stands: facing, height (a boat
## deck) and scale.
func _stand_in(actor_: Node3D, real: Node3D) -> void:
	actor_.global_rotation.y = real.global_rotation.y
	actor_.global_position.y = real.global_position.y
	actor_.scale *= real.global_basis.get_scale().x


func _make_actor(actor_kind: String, skipping := false) -> Node3D:
	if actor_kind == "rin_faint":
		# Rin's own model collapsing (Faint clip), not a stand-in shape.
		var fainting := PersonRig3D.build(_rig, "rin")
		fainting.remove_from_group("person_rin")
		fainting.process_mode = Node.PROCESS_MODE_ALWAYS
		fainting.play_clip("Faint", skipping)
		return fainting
	if actor_kind in PersonRig3D.LOOKS or actor_kind == "cat":
		var rig := PersonRig3D.build(_rig, actor_kind)
		rig.remove_from_group("person_" + actor_kind)
		rig.process_mode = Node.PROCESS_MODE_ALWAYS
		return rig
	var root := Node3D.new()
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	var mesh := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = KIND_COLORS.get(actor_kind, Color(0.8, 0.8, 0.8))
	var shape: Mesh
	match actor_kind:
		"crate":
			shape = BoxMesh.new()
			(shape as BoxMesh).size = Vector3(0.7, 0.5, 0.7)
			mesh.position.y = 0.25
		"glow":
			shape = SphereMesh.new()
			(shape as SphereMesh).radius = 0.3
			(shape as SphereMesh).height = 0.6
			material.emission_enabled = true
			material.emission = material.albedo_color
			material.emission_energy_multiplier = 3.0
			mesh.position.y = 0.6
			var light := OmniLight3D.new()
			light.light_color = material.albedo_color
			light.position.y = 0.6
			root.add_child(light)
		"cat":
			shape = CapsuleMesh.new()
			(shape as CapsuleMesh).radius = 0.15
			(shape as CapsuleMesh).height = 0.45
			mesh.position.y = 0.25
		_:
			shape = CapsuleMesh.new()
			(shape as CapsuleMesh).radius = 0.3
			(shape as CapsuleMesh).height = 1.4
			mesh.position.y = 0.7
	if actor_kind == "rin_bed":
		material.albedo_color = KIND_COLORS["rin"]
		mesh.rotation_degrees.x = 90.0
		mesh.position.y = 0.3
	mesh.mesh = shape
	mesh.material_override = material
	root.add_child(mesh)
	return root


func _num(args: PackedStringArray, index: int, fallback: float) -> float:
	return float(args[index]) if index < args.size() and args[index].is_valid_float() else fallback
