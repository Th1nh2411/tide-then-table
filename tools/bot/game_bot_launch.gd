extends Node
## Starts GameBot (tools/run_bot.sh): fresh state, the bot on the root (it
## outlives scene changes), then the main menu.


func _ready() -> void:
	GameState.reset()
	get_tree().root.add_child.call_deferred(load("res://tools/bot/game_bot.gd").new())
	get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu/main_menu.tscn")
