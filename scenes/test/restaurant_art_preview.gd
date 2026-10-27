extends Node
## F6: a fresh, unsaved restaurant for inspecting the active character art.


func _ready() -> void:
	SaveSystem.autosave_off = true
	GameState.reset()
	GameState.day = 4
	GameState.staff = {"hired": ["vy", "hung"], "applicants": [], "ad_day": 0}
	var restaurant := preload("res://scenes/restaurant/restaurant_scene.tscn").instantiate()
	restaurant.arrival_cutscenes.clear()
	add_child(restaurant)
	if "--capture-asset-preview" in OS.get_cmdline_user_args():
		await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://build/shots")
		var error := get_viewport().get_texture().get_image().save_png("res://build/shots/restaurant_art_preview.png")
		print("Restaurant art capture: ", error_string(error))
		SceneRouter.quit_game()
