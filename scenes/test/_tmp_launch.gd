extends Node

func _ready() -> void:
	GameState.reset()
	get_tree().root.add_child.call_deferred(load("res://scenes/test/_tmp_play.gd").new())
	get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu/main_menu.tscn")
