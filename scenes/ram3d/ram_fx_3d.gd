class_name RamFx3D
extends RefCounted
## Shared pieces of the đêm rằm sequences (PLAN §10 H7): ghost bodies, hoa
## đăng lanterns, full-screen veils, timed waits (scaled by RamNight.speed)
## and lines shown one after another as on-screen text.

const LINES: RamLinesData = preload("res://data/story/ram_lines.tres")
## How solid the rằm visions are (GhostLook3D dithered opacity).
const GHOST_OPACITY := 0.42


static func wait(node: Node, seconds: float) -> void:
	await node.get_tree().create_timer(RamNight.secs(seconds), true).timeout


## A person drawn as a see-through ghost in the dead's look (GhostLook3D;
## default: one of the drowned, `PersonRig3D` "drowned" alternates the two
## pack models). Returns its own material: fade it with
## `set_ghost_alpha` / a tween of "shader_parameter/opacity".
static func ghost(parent: Node3D, pos: Vector3, variant: String = "drowned") -> ShaderMaterial:
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.position = pos
	var rig := PersonRig3D.build(holder, variant)
	var material := GhostLook3D.apply(rig, true, GHOST_OPACITY)
	for node in rig.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for node in rig.find_children("*", "CollisionShape3D", true, false):
		(node as CollisionShape3D).disabled = true
	holder.set_meta("rig", rig)
	material.set_meta("holder", holder)
	return material


static func ghost_holder(material: ShaderMaterial) -> Node3D:
	return material.get_meta("holder") as Node3D


static func ghost_alpha(material: ShaderMaterial) -> float:
	return GhostLook3D.opacity(material)


static func set_ghost_alpha(material: ShaderMaterial, alpha: float) -> void:
	GhostLook3D.set_opacity(material, alpha)


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
