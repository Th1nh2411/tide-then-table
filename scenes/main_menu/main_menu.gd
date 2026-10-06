extends Control
## Placeholder main menu: New Game / Quit.

const SEA_SCENE_PATH: String = "res://scenes/sea/sea_scene.tscn"

@onready var _new_game_button: Button = %NewGameButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_new_game_button.grab_focus()


func _on_new_game_pressed() -> void:
	GameState.reset()
	SceneRouter.go_to(SEA_SCENE_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()
