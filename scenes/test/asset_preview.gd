extends Node2D
## F6: review the real boat and grill renderers with the new PNG masters.
## Optional --capture-asset-preview saves a rendered image under build/shots.

const BOATS: Array[String] = ["thuyen_thung", "ghe_cheo", "ghe_may"]
const FISH: Array[String] = ["ca_thu", "tom", "muc", "oc_huong"]
var _doneness: float = 0.0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("172038"))
	for column in BOATS.size():
		for row in 3:
			var boat := preload("res://scenes/sea/boat.tscn").instantiate() as Boat
			boat.boat_data = load("res://data/boats/%s.tres" % BOATS[column]) as BoatData
			boat.position = Vector2(110 + column * 210, 68 + row * 58)
			boat.scale = Vector2(2, 2)
			add_child(boat)
			boat.get_node("Camera2D").enabled = false
			boat.process_mode = Node.PROCESS_MODE_DISABLED
			boat.rotation = row * PI * 0.5
			boat.queue_redraw()
	if "--capture-asset-preview" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://build/shots")
		for index in 3:
			_doneness = [0.0, 0.6, 1.0][index]
			queue_redraw()
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var path := "res://build/shots/asset_preview_%d.png" % index
			var error := get_viewport().get_texture().get_image().save_png(path)
			print("Asset preview capture: ", path, " ", error_string(error))
		SceneRouter.quit_game()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		for index in 3:
			if event.as_text() == str(index + 1):
				_doneness = [0.0, 0.6, 1.0][index]
				queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for column in BOATS.size():
		draw_string(font, Vector2(35 + column * 210, 16), BOATS[column], HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	for column in FISH.size():
		var x := float(30 + column * 155)
		draw_string(font, Vector2(x, 260), FISH[column], HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		var color := GrillView.cooked_color(_doneness, Vector2(0.5, 0.7))
		GrillView.draw(self, Rect2(x, 270, 84, 60), FISH[column],
			color, color, 1.0, 0.0, 0.0, 0.0, _doneness > 0.0)
	draw_string(font, Vector2(30, 240), "1: Sống / 2: Chín / 3: Cháy", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
