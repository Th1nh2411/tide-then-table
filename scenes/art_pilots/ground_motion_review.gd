extends Node3D
## F6: actual distance-driven gaits, starts/stops/turns and carry walking.
var actors: Array[PersonRig3D] = []
var frame := 0
var capture := false
var capture_busy := false

func _ready() -> void:
	capture = OS.get_cmdline_user_args().has("--capture-ground-motion")
	get_window().content_scale_size = Vector2i(1280,720)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("263440")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("9aa8b4")
	env.environment.ambient_light_energy = .45
	add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48,-32,0)
	key.light_energy = .9
	key.shadow_enabled = true
	add_child(key)
	var floor_ := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(12,12)
	floor_.mesh = plane
	floor_.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("797e73")
	floor_.material_override = mat
	add_child(floor_)
	for i in range(-5,6):
		for axis in 2:
			var line := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(.012,.002,10) if axis == 0 else Vector3(10,.002,.012)
			line.mesh = box
			var ink := StandardMaterial3D.new()
			ink.albedo_color = Color("577277")
			line.material_override = ink
			line.position = Vector3(float(i),.002,0) if axis == 0 else Vector3(0,.002,float(i))
			line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(line)
	for i in 4:
		var actor := PersonRig3D.build(self,["rin","vy","staff","guest_1"][i])
		actor.position = Vector3(-3.0+float(i)*2,-.001,-1.8)
		actor.set_carrying(i in [1,2])
		actors.append(actor)
		var label := Label3D.new()
		label.text = ["Rin","Vy · bưng món","Nhân viên · bưng món","Khách"][i]
		label.position = Vector3(0,2.2,0)
		label.pixel_size = .003
		label.font_size = 32
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		actor.add_child(label)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 6.5
	camera.position = Vector3(7,4.8,8)
	add_child(camera)
	camera.look_at(Vector3(0,.8,0))
	camera.current = true
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := Label.new()
	title.text = "DI CHUYỂN · TĂNG TỐC / DỪNG / RẼ / BƯNG MÓN\nChân tiếp đất theo quãng đường thực; lưới sàn để đối chiếu bước chân."
	title.position = Vector2(18,14)
	title.add_theme_font_size_override("font_size",20)
	layer.add_child(title)

func _physics_process(delta: float) -> void:
	frame += 1
	var seconds := float(frame)/60.0
	var leg := int(seconds/3.0)%2
	var waiting := fmod(seconds,3.0)<.45
	for i in actors.size():
		var actor := actors[i]
		var x := -3.0+float(i)*2.0
		var target := Vector3(x,actor.position.y,1.8 if leg == 0 else -1.8)
		if waiting:
			actor.drive_ground_motion(Vector3.ZERO,delta,false)
			actor.set_meta("ground_speed",0.0)
			continue
		var route: Array[Vector3] = [actor.position,target]
		StaffPathing3D.follow(actor,route,2.8 if i == 0 else 1.8,delta)
	if capture and frame in [70,95,120,145,210,235,260,285] and not capture_busy:
		_save.call_deferred(frame)
	if capture and frame > 305 and not capture_busy:
		print("PASS grounded motion review captured")
		get_tree().quit()

func _save(number: int) -> void:
	capture_busy = true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/ground_motion/review_%03d.png" % number)
	capture_busy = false
