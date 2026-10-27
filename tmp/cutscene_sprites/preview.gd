extends Node

func _ready() -> void:
	get_tree().root.size = Vector2i(640, 360)
	var bg := ColorRect.new()
	bg.size = Vector2(640, 360)
	bg.color = Color("253a5e")
	add_child(bg)
	var kinds: Array[String] = ["crate", "rin_bed", "rin_faint"]
	for i in 3:
		var actor := CutsceneActor.new()
		actor.kind = kinds[i]
		actor.position = Vector2(105 + i * 210, 95)
		actor.scale = Vector2(3,3)
		add_child(actor)
		_label(kinds[i], Vector2(45 + i*210, 20))
	for frame in 4:
		for night in 2:
			var actor := CutsceneActor.new()
			actor.kind = "glow"
			actor.position = Vector2(110 + frame*140, 170 + night*115)
			if night:
				actor.modulate = Color(0.13,0.15,0.27)
			add_child(actor)
			actor.set_process(false)
			actor._time = float(frame)/3.0 + 0.01
			actor.queue_redraw()
	_label("4 glow frames: normal / night tint", Vector2(45,110))
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tmp/cutscene_sprites/consumer_preview.png")
	get_tree().quit()

func _label(text: String, at: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	add_child(label)
