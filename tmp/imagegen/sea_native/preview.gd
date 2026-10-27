extends Node

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	get_tree().root.size = Vector2i(640, 360)
	var canvas := Node2D.new()
	add_child(canvas)
	var bg := ColorRect.new()
	bg.size = Vector2(640, 360)
	bg.color = Color("253a5e")
	canvas.add_child(bg)
	var ids: Array[String] = ["thuyen_thung", "ghe_cheo", "ghe_may"]
	for row in 3:
		for col in 3:
			var boat: Boat = load("res://scenes/sea/boat.tscn").instantiate()
			boat.boat_data = load("res://data/boats/" + ids[row] + ".tres")
			canvas.add_child(boat)
			boat.camera.enabled = false
			boat.set_physics_process(false)
			boat.position = Vector2(120 + col * 200, 78 + row * 110)
			boat.scale = Vector2(2, 2)
			boat.rotation = float(col) * PI * 0.5
			var label := Label.new()
			label.text = ids[row] + "  " + str(col * 90) + "°"
			label.position = Vector2(50 + col * 200, 16 + row * 110)
			canvas.add_child(label)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tmp/imagegen/sea_native/consumer_preview.png")
	get_tree().quit()
