class_name RamFx3D
extends RefCounted
## Shared pieces of the đêm rằm sequences (PLAN §10 H7): ghost bodies, hoa
## đăng lanterns, full-screen veils, timed waits (scaled by RamNight.speed)
## and lines shown one after another as on-screen text.

const LINES: RamLinesData = preload("res://data/story/ram_lines.tres")
const GHOST_HEX := "9fe6e0"


static func wait(node: Node, seconds: float) -> void:
	await node.get_tree().create_timer(RamNight.secs(seconds), true).timeout


## A person drawn as a pale, see-through, self-lit ghost. Returns the shared
## material (tween its albedo alpha to fade the ghost).
static func ghost(parent: Node3D, pos: Vector3, variant: String = "guest") -> StandardMaterial3D:
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.position = pos
	var rig := PersonRig3D.build(holder, variant)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(GHOST_HEX, 0.42)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for node in rig.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		mesh.material_override = material
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for node in rig.find_children("*", "CollisionShape3D", true, false):
		(node as CollisionShape3D).disabled = true
	holder.set_meta("rig", rig)
	material.set_meta("holder", holder)
	return material


static func ghost_holder(material: StandardMaterial3D) -> Node3D:
	return material.get_meta("holder") as Node3D


## A paper lotus lantern (same look as the dock's hoa đăng omen).
static func lantern(parent: Node3D, pos: Vector3, with_light: bool = true) -> Node3D:
	var node := Node3D.new()
	parent.add_child(node)
	node.position = pos
	ConceptModel3D.spawn(node, "hoa_dang_lantern", Vector3(0, -0.02, 0), 0.16)
	OmenProps3D.glow_box(node, Vector3(0, 0.07, 0), Vector3(0.05, 0.07, 0.05), "ffcf6a", 3.0)
	if with_light:
		OmenProps3D.light(node, Vector3(0, 0.3, 0), "ffb347", 0.5, 2.5)
	return node


## A full-screen colour rect over the game (alpha starts at `alpha`).
static func veil(parent: Node, hex: String, alpha: float, layer: int = 40) -> ColorRect:
	var canvas := CanvasLayer.new()
	canvas.layer = layer
	parent.add_child(canvas)
	var rect := ColorRect.new()
	rect.color = Color(hex, alpha)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(rect)
	return rect


## Shows each line in turn on `text`, `seconds` apiece.
static func say_lines(text: OnScreenText, lines: Array, seconds: float) -> void:
	for line: Variant in lines:
		text.say(str(line), RamNight.secs(seconds))
		await wait(text, seconds)
