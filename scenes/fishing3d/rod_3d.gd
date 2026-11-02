class_name Rod3D
extends Node3D
## What the first-person rod looks like (Fishing3D drives it): the rod held
## low right of the view (follows the current camera), bending with line
## tension; the bobber and the line (ImmediateMesh, sagging when slack, pale
## -> red with tension) out on the water; the "!" over the bobber at a bite;
## the landed fish held in front of the camera. Placeholder geometry.

const HOLD := Vector3(0.26, -0.3, -0.42)
const ROD_LENGTH := 1.25
const LINE_POINTS := 12
const LINE_PALE := Color("e7e2cf")
const LINE_RED := Color("e0402f")
const FISH_IN_HAND := Vector3(-0.14, -0.16, -0.5)

## 0..1: bends the rod and tints the line.
var tension := 0.0
## Tip shake (bite), decays by itself.
var shake := 0.0
var bobber: MeshInstance3D
var mark: Label3D
var line_out := false
var _pivot := Node3D.new()
var _base: MeshInstance3D
var _tip_segment := Node3D.new()
var _tip := Node3D.new()
var _line := MeshInstance3D.new()
var _line_mesh := ImmediateMesh.new()
var _line_mat := StandardMaterial3D.new()
var _hand := Node3D.new()
var _clock := 0.0
var _holding := false


func _ready() -> void:
	process_priority = 950  # after FirstPersonView3D moved the camera
	add_child(_pivot)
	_pivot.position = HOLD
	_pivot.rotation = Vector3(0.55, 0.12, 0.0)
	_base = _box(_pivot, Vector3(0, 0, -ROD_LENGTH * 0.3), Vector3(0.024, 0.024, ROD_LENGTH * 0.6), "6b4a2e")
	_box(_pivot, Vector3(0, -0.03, 0.02), Vector3(0.05, 0.05, 0.12), "2a2230")  # reel
	_pivot.add_child(_tip_segment)
	_tip_segment.position = Vector3(0, 0, -ROD_LENGTH * 0.6)
	_box(_tip_segment, Vector3(0, 0, -ROD_LENGTH * 0.2), Vector3(0.014, 0.014, ROD_LENGTH * 0.4), "a37a52")
	_tip_segment.add_child(_tip)
	_tip.position = Vector3(0, 0, -ROD_LENGTH * 0.4)
	add_child(_hand)
	_hand.position = FISH_IN_HAND
	# World-space pieces: the bobber, the line and the bite mark.
	bobber = _box(self, Vector3.ZERO, Vector3(0.16, 0.2, 0.16), "e0402f")
	bobber.top_level = true
	_box(bobber, Vector3(0, 0.1, 0), Vector3(0.05, 0.08, 0.05), "efe6d2")
	bobber.visible = false
	_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line_mat.vertex_color_use_as_albedo = true
	_line.mesh = _line_mesh
	_line.material_override = _line_mat
	_line.top_level = true
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_line)
	mark = Label3D.new()
	mark.text = "!"
	mark.font_size = 128
	mark.pixel_size = 0.012
	mark.outline_size = 18
	mark.modulate = Color("ffd84a")
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark.no_depth_test = true
	mark.top_level = true
	mark.visible = false
	add_child(mark)


func _process(delta: float) -> void:
	_clock += delta
	var camera := get_viewport().get_camera_3d()
	if camera:
		global_transform = camera.global_transform
	shake = maxf(shake - delta * 1.5, 0.0)
	var jitter := sin(_clock * 55.0) * 0.06 * shake
	_pivot.rotation.x = 0.55 - tension * 0.25 + jitter
	_tip_segment.rotation.x = -tension * 0.55 - shake * 0.2
	mark.global_position = bobber.global_position + Vector3(0, 1.0 + sin(_clock * 9.0) * 0.06, 0)
	_draw_line()


func tip_position() -> Vector3:
	return _tip.global_position


## Where the bobber sits; `dip` pulls it under (bite / fight).
func place_bobber(at: Vector3) -> void:
	bobber.visible = true
	bobber.global_position = at
	line_out = true


func reel_in() -> void:
	bobber.visible = false
	mark.visible = false
	line_out = false
	tension = 0.0


func show_fish(fish: FishData, size: float) -> void:
	hide_fish()
	_holding = true
	var model := FishBasket3D.fish_mesh(fish, size)
	_hand.add_child(model)
	# Side on across the view, head down-left, tail up-right.
	model.rotation = Vector3(0.15, 0.25, 0.45)


func hide_fish() -> void:
	_holding = false
	for child in _hand.get_children():
		child.queue_free()


func holding_fish() -> bool:
	return _holding


func _draw_line() -> void:
	_line_mesh.clear_surfaces()
	if not line_out or not bobber.visible:
		return
	var a := tip_position()
	var b := bobber.global_position + Vector3(0, 0.08, 0)
	var sag := lerpf(0.45, 0.02, clampf(tension * 1.6, 0.0, 1.0))
	var color := LINE_PALE.lerp(LINE_RED, clampf(tension, 0.0, 1.0))
	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(LINE_POINTS + 1):
		var t := float(i) / LINE_POINTS
		var p := a.lerp(b, t)
		p.y -= sin(t * PI) * sag * (1.0 - t * 0.4)
		_line_mesh.surface_set_color(color)
		_line_mesh.surface_add_vertex(p)
	_line_mesh.surface_end()


static func _box(parent: Node3D, pos: Vector3, size: Vector3, hex: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	mat.roughness = 0.8
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	node.position = pos
	return node
