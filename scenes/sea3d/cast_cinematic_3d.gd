class_name CastCinematic3D
extends Node
## Short cast scene at a shoal: Rin swings the rod, the bobber splashes, the
## camera dips toward the water and a ripple wipe hands over to the 2D
## underwater minigame. `play_return` is the reverse. Runs while the tree is
## unpaused (the overlay pauses it afterwards); tweens are bound to this node,
## which is PROCESS_MODE_ALWAYS. Any key skips ahead (speed-up, never a jump).

const DURATION: float = 1.5
const RETURN_DURATION: float = 0.5
const WIPE_SHADER := """
shader_type canvas_item;
uniform float progress = 0.0;
void fragment() {
	vec2 c = UV - vec2(0.5);
	c.x *= 1.78;
	float d = length(c) + 0.03 * sin(length(c) * 50.0 - progress * 16.0);
	COLOR = vec4(0.04, 0.1, 0.19, step(d, progress * 1.2));
}
"""

signal wipe_covered
signal finished

var sea: Node3D
var camera: Camera3D
var boat_visual: Node3D
var hidden_figure: Array[Node3D] = []
var playing: bool = false
var wipe_progress: float = 0.0

var _rig: PersonRig3D
var _rod: Node3D
var _tip: Node3D
var _bobber: MeshInstance3D
var _line: MeshInstance3D
var _ring: MeshInstance3D
var _target: Vector3
var _cam_from: Transform3D
var _cam_to: Transform3D
var _cam_home: Transform3D
var _tween: Tween
var _cover: ColorRect
var _mat: ShaderMaterial
var _released: bool = false
var _splashed: bool = false
var _tip_at_release: Vector3


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	_cover = ColorRect.new()
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = WIPE_SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_cover.material = _mat
	_cover.visible = false
	layer.add_child(_cover)


func _set_wipe(value: float) -> void:
	wipe_progress = value
	_mat.set_shader_parameter("progress", value)
	_cover.visible = value > 0.0


func _input(event: InputEvent) -> void:
	if playing and _tween and event is InputEventKey and event.is_pressed() and not event.is_echo():
		_tween.set_speed_scale(6.0)


## Awaitable. `target` is the shoal's world position.
func play(target: Vector3) -> void:
	if playing:
		return
	playing = true
	_target = target
	_released = false
	_splashed = false
	_build_props()
	_cam_home = camera.global_transform
	# Cut close enough to read Rin's cast before following the bobber underwater.
	var actor_focus := _rig.global_position + Vector3.UP * 1.0
	var actor_view := _rig.global_position + _rig.global_basis.orthonormalized() * Vector3(3.0, 1.8, 4.0)
	_cam_from = Transform3D(Basis.IDENTITY, actor_view).looking_at(actor_focus, Vector3.UP)
	camera.global_transform = _cam_from
	var look_from: Vector3 = target + Vector3(0, 3.2, 3.8)
	_cam_to = Transform3D(Basis.IDENTITY, look_from).looking_at(target, Vector3.UP)
	_tween = create_tween()
	_tween.tween_method(_apply, 0.0, 1.0, DURATION)
	await _tween.finished
	if not is_instance_valid(sea):
		return
	_apply(1.0)
	_clear_props()
	playing = false
	wipe_covered.emit()
	finished.emit()


## Shrinks the wipe once the minigame is on screen.
func reveal() -> void:
	var tw := create_tween()
	tw.tween_method(_set_wipe, 1.0, 0.0, 0.3)


## Camera dips back up from the water while the wipe clears. Awaitable.
func play_return() -> void:
	_set_wipe(1.0)
	playing = true
	var from: Transform3D = camera.global_transform
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_method(func(v: float) -> void: camera.global_transform = from.interpolate_with(_cam_home, v), 0.0, 1.0, RETURN_DURATION)
	_tween.tween_method(_set_wipe, 1.0, 0.0, RETURN_DURATION)
	await _tween.finished
	if not is_instance_valid(sea):
		return
	camera.global_transform = _cam_home
	_set_wipe(0.0)
	playing = false


func _apply(t: float) -> void:
	if not is_instance_valid(_rig):
		return
	_rig.sample_cast(t * DURATION)
	if t >= 0.45 and not _released:
		_released = true
		_tip_at_release = _tip.global_position
	if _released:
		var u: float = clampf((t - 0.45) / 0.27, 0.0, 1.0)
		var p: Vector3 = _tip_at_release.lerp(_target + Vector3(0, 0.1, 0), u)
		p.y += sin(u * PI) * 2.0
		_bobber.global_position = p
		if u >= 1.0 and not _splashed:
			_splashed = true
			Sfx.play("splash")
		if _splashed:
			var s: float = clampf((t - 0.72) / 0.28, 0.0, 1.0)
			_ring.visible = true
			_ring.global_position = _target + Vector3(0, 0.14, 0)
			_ring.scale = Vector3(1.0 + s * 4.0, 1.0, 1.0 + s * 4.0)
			_bobber.global_position.y = 0.12 + sin(t * 30.0) * 0.03
	_bobber.visible = _released
	_update_line()
	# Camera dips toward the water, then the ripple wipe covers the screen.
	var c: float = clampf((t - 0.55) / 0.45, 0.0, 1.0)
	camera.global_transform = _cam_from.interpolate_with(_cam_to, ease(c, 2.0))
	_set_wipe(clampf((t - 0.8) / 0.2, 0.0, 1.0))


func _update_line() -> void:
	var a: Vector3 = _tip.global_position
	var b: Vector3 = _bobber.global_position if _released else a
	var length: float = a.distance_to(b)
	_line.visible = _released and length > 0.05
	if not _line.visible:
		return
	_line.global_position = (a + b) * 0.5
	_line.look_at(b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
	(_line.mesh as BoxMesh).size = Vector3(0.015, 0.015, length)


func _build_props() -> void:
	for node in hidden_figure:
		node.visible = false
	_rig = PersonRig3D.build(boat_visual, "rin")
	_rig.position = Vector3(0, 0.62, 0.3)
	if not hidden_figure.is_empty() and is_instance_valid(hidden_figure[0]):
		_rig.position = hidden_figure[0].position
		_rig.scale = hidden_figure[0].scale
	var local: Vector3 = boat_visual.to_local(_target)
	_rig.rotation.y = atan2(local.x, local.z)
	var arm: Node3D = _rig.arms[1]
	_rod = Node3D.new()
	arm.add_child(_rod)
	_rod.position = Vector3(0, -0.6, 0)
	_rod.rotation.x = -1.2
	_add_box(_rod, Vector3(0, 0, 0.7), Vector3(0.04, 0.04, 1.6), "884b2b")
	_tip = Node3D.new()
	_rod.add_child(_tip)
	_tip.position = Vector3(0, 0, 1.5)
	_rig.sample_cast(0.0)
	_bobber = _add_box(sea, Vector3.ZERO, Vector3(0.14, 0.14, 0.14), "cf573c")
	_bobber.visible = false
	_line = _add_box(sea, Vector3.ZERO, Vector3(0.015, 0.015, 0.1), "e7d5b3")
	_line.visible = false
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.35
	torus.outer_radius = 0.45
	torus.rings = 12
	torus.ring_segments = 4
	_ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("a4dddb")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring.material_override = mat
	_ring.visible = false
	sea.add_child(_ring)


func _add_box(parent: Node3D, pos: Vector3, size: Vector3, hex: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	node.material_override = mat
	parent.add_child(node)
	node.position = pos
	return node


func _clear_props() -> void:
	for node: Node in [_rig, _bobber, _line, _ring]:
		if is_instance_valid(node):
			node.queue_free()
	for node in hidden_figure:
		if is_instance_valid(node):
			node.visible = true
