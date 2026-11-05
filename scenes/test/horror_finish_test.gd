extends Node3D
## Material/UV and geometry contracts of the brief-6 asset pass.
var failures := 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	SaveSystem.autosave_off = true
	GameState.reset()
	for id: String in ["tube_house_a", "tube_house_b", "tube_house_c"]:
		var model := ConceptModel3D.spawn(self, id, Vector3.ZERO, 1.0)
		var roles: Dictionary = {}
		var tiled := true
		for instance: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			for surface: int in range(instance.mesh.get_surface_count()):
				var mat := instance.mesh.surface_get_material(surface)
				roles[mat.resource_name] = true
				var uv: PackedVector2Array = instance.mesh.surface_get_arrays(surface)[Mesh.ARRAY_TEX_UV]
				tiled = tiled and not uv.is_empty()
		_check(tiled and roles.has("HorrorUV_ConceptFront") and roles.has("HorrorUV_roof_tin_rusty") and roles.size() >= 3, id + " keeps facade art and real UV wall/roof materials")
		model.free()
	var cart := ConceptModel3D.spawn(self, "food_cart_glass", Vector3.ZERO, 1.0)
	var front_only := false
	for instance: MeshInstance3D in cart.find_children("*", "MeshInstance3D", true, false):
		if instance.material_override is ShaderMaterial:
			front_only = bool((instance.material_override as ShaderMaterial).get_shader_parameter("front_face_only"))
	_check(front_only, "cart lettering cannot render through the back of its front panel")
	cart.free()
	var holder := Node3D.new()
	add_child(holder)
	VillageProps3D.place(holder, "planter_tree_street", Vector3.ZERO, Vector3(2.4, 4.2, 2.4))
	var tree_box := _bounds(holder)
	_check(tree_box.size.y >= 3.5 and tree_box.size.y <= 4.5, "street tree stays 3.5–4.5 m in the existing placement box")
	_check(tree_box.size.x <= 2.41 and tree_box.size.z <= 2.41, "tree canopy fits the unchanged pavement slot")
	holder.free()
	var hull := ConceptModel3D.spawn(self, "thung_boat", Vector3.ZERO, 1.0)
	var hull_box := _bounds(hull)
	var inner_top := 0.0
	for instance: MeshInstance3D in hull.find_children("*", "MeshInstance3D", true, false):
		for surface: int in range(instance.mesh.get_surface_count()):
			var vertices: PackedVector3Array = instance.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for vertex: Vector3 in vertices:
				var p := instance.global_transform * vertex
				if Vector2(p.x, p.z).length() < hull_box.size.x * .2:
					inner_top = maxf(inner_top, p.y)
	_check(absf(inner_top - ThungHull3D.FLOOR_FRACTION) < .006, "paddle-free interior keeps the existing inner-floor calibration")
	hull.free()
	var rod := ConceptModel3D.spawn(self, "fishing_rod", Vector3.ZERO, 1.0)
	var rod_mesh := rod.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var bend := rod_mesh.material_override as ShaderMaterial
	_check(bend != null and bool(bend.get_shader_parameter("use_baked_uv")) and bend.get_shader_parameter("baked_albedo") is Texture2D, "rod uses actual wood UVs while retaining its bend shader")
	rod.free()
	print("HORROR FINISH TEST ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(1 if failures else 0)

func _bounds(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for instance: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = instance.global_transform * instance.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result

func _check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1
