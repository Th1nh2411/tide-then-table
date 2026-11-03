extends Node3D
## The shared look (StylePass3D + StyleGuide, GhostLook3D): idempotent pass,
## opt-outs untouched, materials shared by look, worn recolours, every graded
## material of a built village inside the guide's ranges, the ghost look.

var failures := 0


func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_pass_rules()
	await _village()
	await _ghosts()
	get_tree().quit(1 if failures else 0)


func _box(parent: Node, hex: String, name_: String = "Box") -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name_
	mesh.mesh = BoxMesh.new()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.metallic = 0.3
	m.roughness = 0.3
	mesh.material_override = m
	parent.add_child(mesh)
	return mesh


func _pass_rules() -> void:
	var guide := StylePass3D.get_guide()
	var a := _box(self, "c7cfcc")
	StylePass3D.apply_mesh(a)
	var styled := a.material_override
	StylePass3D.apply_mesh(a)
	StylePass3D.apply_tree(self)
	check(styled is ShaderMaterial and a.material_override == styled, "pass is idempotent (one graded material, kept on re-runs)")
	check(StylePass3D.style(styled, a) == styled, "styling a graded material returns it unchanged")
	var shader := styled as ShaderMaterial
	var rough: float = shader.get_shader_parameter("roughness")
	var metal: float = shader.get_shader_parameter("metallic")
	check(rough >= guide.roughness_min and metal == 0.0, "no shine: roughness %.2f, metallic %.2f" % [rough, metal])
	var b := _box(self, "c7cfcc")
	StylePass3D.apply_mesh(b)
	check(b.material_override == styled, "same look -> one shared ShaderMaterial")
	var holder := Node3D.new()
	holder.set_meta(StylePass3D.SKIP, true)
	add_child(holder)
	var skipped := _box(holder, "ff0000")
	var source := skipped.material_override
	StylePass3D.apply_mesh(skipped)
	check(skipped.material_override == source, "style_skip on a parent: mesh untouched")
	var glow := _box(self, "ffe3b0")
	var glow_mat := glow.material_override as StandardMaterial3D
	glow_mat.emission_enabled = true
	glow_mat.emission = Color("ffd39b")
	StylePass3D.apply_mesh(glow)
	check(glow.material_override == glow_mat, "glowing material (lamp) untouched")
	var see := _box(self, "ffffff")
	(see.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var see_mat := see.material_override
	StylePass3D.apply_mesh(see)
	check(see.material_override == see_mat, "see-through material untouched")
	var stool := Node3D.new()
	stool.name = "PilotStool_9_red"
	add_child(stool)
	var seat := _box(stool, "a53030")
	StylePass3D.apply_mesh(seat)
	var worn: Color = (seat.material_override as ShaderMaterial).get_shader_parameter("albedo_color")
	check(worn.to_html(false) == (guide.recolor["PilotStool|a53030"] as Color).to_html(false), "old red stool gets its worn colour")
	var graded := StyleColors.grade(Color("e0302b"), guide, guide.tint_night)
	check(StyleColors.saturation(graded) <= guide.max_saturation + 0.01 and StyleColors.value(graded) <= guide.max_value + 0.01, "grade caps a saturated red")


func _village() -> void:
	var guide := StylePass3D.get_guide()
	GameState.reset()
	var village := load(VillageLayout3D.SCENE).instantiate() as Node3D
	add_child(village)
	village.set_process(false)
	village.set_physics_process(false)
	for i in 3:
		await get_tree().process_frame
	var graded := 0
	var out: Array[String] = []
	var left: Array[String] = []
	var concepts := 0
	for node in village.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null or StylePass3D.skipped(mesh):
			continue
		for i in (1 if mesh.material_override else mesh.mesh.get_surface_count()):
			var material := mesh.material_override if mesh.material_override else mesh.get_active_material(i)
			var base := material as BaseMaterial3D
			if base and not StyleMaterials.keeps(base):
				left.append(StyleAudit.model_name(mesh))
			if material is ShaderMaterial and material.has_meta(StylePass3D.STYLED):
				var mean := StyleColors.material_mean(material)
				if (material as ShaderMaterial).shader.resource_path == StylePass3D.CONCEPT_SHADER:
					concepts += 1
				if not bool(mean.get("ok", false)):
					continue
				graded += 1
				var c: Color = mean["color"]
				var s := StyleColors.saturation(c)
				var v := StyleColors.value(c)
				if s > guide.max_saturation + 0.02 or v > guide.max_value + 0.02 or v < guide.black_lift - 0.01:
					out.append("%s %s s%.2f v%.2f" % [StyleAudit.model_name(mesh), c.to_html(false), s, v])
	check(left.is_empty(), "every opaque lit StandardMaterial3D in the village is graded (left: %s)" % [left.slice(0, 5)])
	check(graded > 50 and concepts > 5, "village has graded materials (%d, %d concept models)" % [graded, concepts])
	var looks := StyleMaterials.all().size()
	# BoxBatch3D merges many boxes into one surface per colour, so surfaces per look dropped; 2x still proves sharing.
	check(looks * 2 < graded,"graded materials shared by look (%d shaders for %d surfaces)" % [looks, graded])
	check(out.is_empty(), "every graded material inside the guide's saturation / value range (out: %s)" % [out.slice(0, 5)])
	village.queue_free()
	await get_tree().process_frame


func _ghosts() -> void:
	var rig := PersonRig3D.build(self, "drowned_m")
	await get_tree().process_frame
	var meshes := rig.get_node("PsxPilot").find_children("*", "MeshInstance3D", true, false)
	var all_ghost := not meshes.is_empty()
	for node in meshes:
		var mesh := node as MeshInstance3D
		if not mesh.name.begins_with("GhostDrop"):
			all_ghost = all_ghost and GhostLook3D.is_ghost(mesh.material_override)
	check(all_ghost, "a drowned rig's body wears the ghost material")
	check(rig.find_children(GhostLook3D.DRIPS, "CPUParticles3D", true, false).size() == 1, "the drowned drip water")
	var tu := RamFx3D.ghost(self, Vector3(3, 0, 0), "ong_tu")
	check(GhostLook3D.is_ghost(tu) and is_equal_approx(RamFx3D.ghost_alpha(tu), RamFx3D.GHOST_OPACITY), "ông Tư's rằm ghost: own ghost material, see-through")
	RamFx3D.set_ghost_alpha(tu, 0.1)
	var other := (meshes[0] as MeshInstance3D).material_override as ShaderMaterial
	check(is_equal_approx(RamFx3D.ghost_alpha(tu), 0.1) and is_equal_approx(GhostLook3D.opacity(other), 1.0), "fading one ghost leaves the others")
	var figure := ConceptModel3D.spawn(self, "drowned_figure", Vector3(6, 0, 0), 1.72)
	var before := (figure.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).material_override
	GhostLook3D.apply(figure)
	var after := (figure.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).material_override
	check(after != before and (after as ShaderMaterial).get_shader_parameter("tint") == GhostLook3D.CONCEPT_TINT, "concept drowned figure gets the cold ghost tint")
	await get_tree().process_frame
	check(after == (figure.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).material_override, "the style pass leaves ghosts alone")
