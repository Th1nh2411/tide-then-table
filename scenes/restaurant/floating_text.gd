class_name FloatingText
## Short text that floats up and fades over someone ("+50k", "Bỏ đi!").


static func spawn(layer: Node, at: Vector2, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.z_index = 30
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.position = at + Vector2(-10, -50)
	layer.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 20, 1.2)
	tween.tween_property(label, "modulate:a", 0.0, 1.2)
	tween.chain().tween_callback(label.queue_free)
