extends Node3D
## Regression checks for visible background leaks, live fish glow and sign isolation.
var failures := 0
const IDS := "charcoal_stove_clay boat_upturned boat_pulled_up coconut_palm fish_cua fish_tom fish_muc fish_oc_huong fish_ca_mu fish_glowing fishing_bobber hat_hook stone_steps wooden_bed ice_box_styrofoam motorbike_cub water_jar fish_basket wooden_wardrobe shed_tin banana_clump buoy_pile altar_ong_tu beer_tower beer_glass_ice dish_bowl_soup dish_plate_fish food_cart_glass roadside_shrine power_pole planter_tree_street tray_aluminium"

func _ready() -> void:
	SaveSystem.autosave_off = true
	GameState.reset()
	for id: String in IDS.split(" "):
		var model := ConceptModel3D.spawn(self, id, Vector3.ZERO, 1.0)
		var covered := true
		for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			if mesh.material_override is ShaderMaterial:
				covered = covered and mesh.material_override.get_shader_parameter("use_baked_uv") == true
			for i: int in range(mesh.mesh.get_surface_count()):
				var uv: PackedVector2Array = mesh.mesh.surface_get_arrays(i)[Mesh.ARRAY_TEX_UV]
				covered = covered and not uv.is_empty()
				var native := mesh.mesh.surface_get_material(i) as BaseMaterial3D
				if native and native.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
					covered = covered and native.metallic < StylePass3D.get_guide().metal_threshold
		_check(covered, id + " has full authored UV coverage, including ends/undersides")
		model.free()
	var aberrant := FishData.new()
	aberrant.id = "ca_thu"
	aberrant.is_aberrant = true
	var fish := FishBasket3D.fish_mesh(aberrant, 1.0)
	add_child(fish)
	var glow_mesh := fish.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var shader := glow_mesh.material_override as ShaderMaterial
	_check(shader != null and is_equal_approx(float(shader.get_shader_parameter("glow")), 0.5), "glowing catch keeps the live fish glow interface")
	fish.free()
	var cart := ConceptModel3D.spawn(self, "food_cart_glass", Vector3.ZERO, 1.0)
	var panes := false
	var food := false
	for mesh: MeshInstance3D in cart.find_children("*", "MeshInstance3D", true, false):
		for i: int in range(mesh.mesh.get_surface_count()):
			var mat := mesh.mesh.surface_get_material(i) as BaseMaterial3D
			if mat and mat.resource_name == "HorrorUV_TransparentGlass":
				panes = mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and mat.albedo_color.a < .35
		food = food or str(mesh.name).contains("FoodInside")
	_check(panes and food, "cart has actual translucent panes and food geometry inside")
	cart.free()
	var one := ConceptModel3D.spawn(self, "tube_house_b", Vector3.ZERO, 1.0)
	var two := ConceptModel3D.spawn(self, "tube_house_b", Vector3(5, 0, 0), 1.0)
	_check(ConceptModel3D.set_sign_variant(one, "tap_hoa") and ConceptModel3D.set_sign_variant(two, "sua_xe"), "placement can choose invented Vietnamese sign variants")
	_check(one.get_meta("sign_variant") == "tap_hoa" and two.get_meta("sign_variant") == "sua_xe", "sign choice stays local to each instance")
	_check(_facade_texture(one) != _facade_texture(two), "two instances actually bind different sign textures")
	_check(not ConceptModel3D.set_sign_variant(one, "unknown") and one.get_meta("sign_variant") == "tap_hoa", "invalid sign choice preserves the selected facade")
	one.free()
	two.free()
	print("HORROR COVERAGE TEST ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(1 if failures else 0)

func _check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func _facade_texture(root: Node3D) -> Texture2D:
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		for i: int in range(mesh.mesh.get_surface_count()):
			var source := mesh.mesh.surface_get_material(i)
			if source.resource_name != "HorrorUV_ConceptFront":
				continue
			var active := mesh.get_active_material(i)
			if active is ShaderMaterial:
				return active.get_shader_parameter("albedo_tex") as Texture2D
			return (active as BaseMaterial3D).albedo_texture
	return null
