class_name RestaurantStringLights3D
extends RefCounted
## One supported festoon cable from the wall over the tables to a curb-side pole.
const START := Vector3(-7.5,4.0,-7.65)
const END := Vector3(-7.5,4.2,RestaurantLayout3D.CURB_PROP_Z)
const SAG := .65

static func cable_point(t: float) -> Vector3:
	return START.lerp(END,t)-Vector3.UP*(4.0*SAG*t*(1.0-t))

static func _material(hex: String) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	mat.roughness = .85
	return mat

static func _rod(parent: Node3D, a: Vector3, b: Vector3, radius: float, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = a.distance_to(b)
	shape.radial_segments = 8
	mesh.mesh = shape
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.position = (a+b)*.5
	mesh.basis = Basis(Quaternion(Vector3.UP,(b-a).normalized()))
	return mesh

static func build(host: Node3D) -> void:
	var root := Node3D.new()
	root.name = "DiningStringLights"
	host.add_child(root)
	var metal := _material("394a50")
	var wire := _material("202e37")
	# Cheap old bulbs: yellowed, dim (no clean white festoon).
	var warm := _material("d9b27a")
	warm.emission_enabled = true
	warm.emission = Color("e0a05a")
	warm.emission_energy_multiplier = 1.2
	# Visible wall bracket, full-height pole, and concrete foot.
	_rod(root,START+Vector3(0,0,-.18),START,.045,metal).name = "WallAnchor"
	_rod(root,Vector3(END.x,0,END.z),END,.065,metal).name = "CurbPole"
	_rod(root,Vector3(END.x,0,END.z),Vector3(END.x,.18,END.z),.16,_material("797e73"))
	RestaurantRoomBuilder3D.solid_block(root,Vector3(END.x,1.0,END.z),Vector3(.3,2.0,.3))
	for i in 24:
		_rod(root,cable_point(float(i)/24),cable_point(float(i+1)/24),.014,wire)
	# Bulbs end before the pole (last at z 6.5).
	for i in 8:
		var z := -5.4+float(i)*1.7
		var t := (z-START.z)/(END.z-START.z)
		var at := cable_point(t)
		var bulb := at-Vector3.UP*.22
		_rod(root,at,bulb+Vector3.UP*.06,.012,wire)
		_rod(root,bulb+Vector3.UP*.03,bulb+Vector3.UP*.11,.045,metal)
		var glow := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = .08
		sphere.height = .16
		sphere.radial_segments = 8
		sphere.rings = 4
		glow.mesh = sphere
		glow.material_override = warm
		root.add_child(glow)
		glow.position = bulb
		glow.name = "Bulb_%d" % i
		# Four real shadow lights cover both table columns and all upgrade rows.
		if i in [0,2,4,6]:
			var light := SpotLight3D.new()
			light.name = "WarmShopLight_String_%d" % i
			root.add_child(light)
			light.position = bulb-Vector3.UP*.1
			light.rotation_degrees.x = -90
			light.light_color = Color("ffc285")
			light.light_energy = 1.6 if RenderingServer.get_current_rendering_method() == "gl_compatibility" else 3.8
			light.spot_range = 7.0
			light.spot_angle = 59.0
			light.spot_angle_attenuation = .6
			light.shadow_enabled = true
			light.shadow_bias = .1
			light.shadow_normal_bias = 1.5
			light.shadow_blur = 2.0
