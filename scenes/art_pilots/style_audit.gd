class_name StyleAudit
extends RefCounted
## The per-model table of the style review: one row per material in a built
## scene (mean colour, HSV saturation / value, material type, roughness,
## metallic, texel density), flagged OUT when the colour is outside the
## StyleGuide range. Rows sorted worst first.


## Rows for every MeshInstance3D under `root`; `area` maps a world position to a name.
static func rows(root: Node, area: Callable) -> Array[Dictionary]:
	var seen: Dictionary = {}
	var out: Array[Dictionary] = []
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null or not mesh.is_visible_in_tree():
			continue
		var count := 1 if mesh.material_override else mesh.mesh.get_surface_count()
		for i in count:
			var material := source_material(mesh, i)
			if material == null:
				continue
			var row := describe(material, mesh)
			row["where"] = str(area.call(mesh.global_position))
			row["model"] = model_name(mesh)
			# One row per look: same model / colour / type / place.
			var id := "%s|%s|%s|%s" % [row["model"], row.get("color", "?"), row["type"], row["where"]]
			if seen.has(id):
				(seen[id] as Dictionary)["n"] = int((seen[id] as Dictionary)["n"]) + 1
				continue
			seen[id] = row
			out.append(row)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) > float(b["score"]))
	return out


## The material before PsxLook3D swapped it (that copy only keeps a few settings).
static func source_material(mesh: MeshInstance3D, surface: int) -> Material:
	if not mesh.has_meta(PsxLook3D.META):
		return mesh.material_override if mesh.material_override else mesh.get_active_material(surface)
	var saved: Array = mesh.get_meta(PsxLook3D.META)
	if saved[0] != null:
		return saved[0] as Material
	if saved.size() > surface + 1 and saved[surface + 1] != null:
		return saved[surface + 1] as Material
	return mesh.mesh.surface_get_material(surface)


## The node's model: the nearest ancestor that is a builder piece.
static func model_name(mesh: Node) -> String:
	var node := mesh
	while node and node.get_parent():
		var n := String(node.name)
		if n.begins_with("Model_") or n.begins_with("Batch_") or n.begins_with("Psx") or n.begins_with("DiningTable") or n.begins_with("PilotStool"):
			return n
		node = node.get_parent()
	var shape := (mesh as MeshInstance3D).mesh
	var kind := shape.get_class() if shape else "?"
	var box := shape as BoxMesh
	if box:
		kind = "Box%.1fx%.1fx%.1f" % [box.size.x, box.size.y, box.size.z]
	return "%s/%s" % [mesh.get_parent().name, kind]


static func describe(material: Material, mesh: MeshInstance3D) -> Dictionary:
	var guide := StylePass3D.get_guide()
	var mean := StyleColors.material_mean(material)
	var row := {"n": 1, "type": material.get_class(), "rough": -1.0, "metal": -1.0, "texels": 0.0, "score": -1.0}
	var base := material as BaseMaterial3D
	if base:
		row["type"] = "unshaded" if base.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED else "lit"
		if StyleMaterials.glows(base):
			row["type"] = str(row["type"]) + "+glow"
		if base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			row["type"] = str(row["type"]) + "+alpha"
		row["rough"] = base.roughness
		row["metal"] = base.metallic
		row["texels"] = StyleMaterials.texel_density(base, mesh)
	var shader := material as ShaderMaterial
	if shader and shader.shader:
		row["type"] = shader.shader.resource_path.get_file().get_basename()
		var r: Variant = shader.get_shader_parameter("roughness")
		row["rough"] = float(r) if r != null else -1.0
		if bool(mean.get("graded", false)):
			row["type"] = str(row["type"]) + "+graded"
	if bool(mean.get("ok", false)):
		var c: Color = mean["color"]
		var s := StyleColors.saturation(c)
		var v := StyleColors.value(c)
		row["color"] = c.to_html(false)
		row["sat"] = s
		row["val"] = v
		row["out"] = s > guide.max_saturation + 0.02 or v > guide.max_value + 0.02
		row["score"] = maxf(s - guide.max_saturation, v - guide.max_value)
	return row


static func format(rows_: Array[Dictionary]) -> String:
	var lines: Array[String] = ["%-4s %-28s %-10s %-22s %-7s %5s %5s %5s %5s %6s %3s" % ["OUT", "model", "where", "type", "color", "sat", "val", "rough", "metal", "tex/m", "n"]]
	for r in rows_:
		lines.append("%-4s %-28s %-10s %-22s %-7s %5.2f %5.2f %5.2f %5.2f %6.0f %3d" % [
			"OUT" if bool(r.get("out", false)) else "", str(r["model"]).left(28), str(r["where"]), str(r["type"]).left(22),
			str(r.get("color", "?")), float(r.get("sat", -1.0)), float(r.get("val", -1.0)), float(r["rough"]), float(r["metal"]),
			float(r["texels"]), int(r["n"])])
	return "\n".join(lines)
