extends Control
## Main menu: Continue (only if a save exists) / New Game / Quit.

const SEA_SCENE_PATH: String = "res://scenes/sea/sea_scene.tscn"

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _quit_button: Button = %QuitButton
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_status_label.text = ""
	_continue_button.visible = SaveSystem.has_save()
	if _continue_button.visible:
		_continue_button.grab_focus()
	else:
		_new_game_button.grab_focus()


func _on_continue_pressed() -> void:
	if not SaveSystem.load_game():
		_status_label.text = "File lưu bị lỗi, không thể tiếp tục. Hãy chơi mới."
		_continue_button.hide()
		_new_game_button.grab_focus()
		return
	SceneRouter.go_to(SEA_SCENE_PATH)


func _on_new_game_pressed() -> void:
	# The old save is overwritten when day 1 starts.
	GameState.reset()
	SceneRouter.go_to(SEA_SCENE_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()
