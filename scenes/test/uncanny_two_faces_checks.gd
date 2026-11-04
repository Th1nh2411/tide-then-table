extends RefCounted
## uncanny_test's part for the two faces (TwoFace3D): dosed from mùng 12, at
## most once a night, never on anh Út; on a real PSX rig the face copy is
## built from the model, sits on the back of the head, and only appears /
## goes while Rin is behind and not looking.


static func run(host: Node3D, check: Callable) -> int:
	var failures := 0
	var early := true
	var once := true
	var seen := false
	for loop in 120:
		for day in range(1, LoopCalendar.NIGHTS + 1):
			var light: Array = UncannyDirector.plan(loop, day, false)["light"]
			early = early and (day >= 4 or not light.has("two_faces"))
			once = once and light.count("two_faces") <= 1
			seen = seen or light.has("two_faces")
	failures += int(check.call("two faces: none before mùng 12", early))
	failures += int(check.call("two faces: at most once a night", once))
	failures += int(check.call("two faces: do show up from mùng 12", seen))
	var ut_holder := Node3D.new()
	ut_holder.name = "AnhUt"
	host.add_child(ut_holder)
	var ut := PersonRig3D.build(ut_holder, "guest_rich")
	failures += int(check.call("two faces: never on anh Út", not UncannyDirector.two_faces_ok(ut)))
	ut_holder.queue_free()
	var rig := PersonRig3D.build(host, "bao")
	failures += int(check.call("two faces: fine on Bảo", UncannyDirector.two_faces_ok(rig)))
	var camera := Camera3D.new()
	host.add_child(camera)
	camera.make_current()
	await host.get_tree().process_frame
	var faces := UncannyActor3D.attach(rig).two_faces(true)
	faces._process(0.0)
	var vertex_count := 0
	if faces.face:
		vertex_count = (faces.face.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	failures += int(check.call("two faces: the copy is the model's own face (%d verts)" % vertex_count, vertex_count > 20))
	var head := UncannyActor3D.attach(rig).head_position()
	var back := (faces.face_position() - head).dot(rig.global_basis.z)
	failures += int(check.call("two faces: it sits on the back of the head", back < -0.05))
	# Rin in front, looking at him: nothing.
	_place(camera, head + Vector3(0, 0, 2.0), head)
	faces._process(0.1)
	failures += int(check.call("two faces: not from the front", not faces.is_shown()))
	# Behind, looking right at the head: still nothing (never pops in view).
	_place(camera, head + Vector3(0, 0, -2.0), head)
	faces._process(0.1)
	failures += int(check.call("two faces: never appears while looked at", not faces.is_shown()))
	# Behind, looking away: there when he turns back.
	_place(camera, head + Vector3(0, 0, -2.0), head + Vector3(0, 0, -6.0))
	faces._process(0.1)
	failures += int(check.call("two faces: appears while Rin is behind and looking away", faces.is_shown()))
	_place(camera, head + Vector3(0, 0, -2.0), head)
	for i in 10:
		faces._process(0.1)
	failures += int(check.call("two faces: stays while he looks", faces.is_shown()))
	for i in 30:
		faces._process(0.1)
	_place(camera, head + Vector3(0, 0, -2.0), head + Vector3(0, 0, -6.0))
	faces._process(0.1)
	failures += int(check.call("two faces: gone at the next look away, once", not faces.is_shown() and not faces.wanted))
	rig.queue_free()
	camera.queue_free()
	return failures


static func _place(camera: Camera3D, at: Vector3, look: Vector3) -> void:
	camera.global_position = at
	camera.look_at(look)
