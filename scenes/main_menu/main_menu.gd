extends Control
## Main menu: Continue (only if a save exists) / New Game / Quit.

const SEA_SCENE_PATH: String = "res://scenes/sea3d/sea_scene_3d.tscn"
const RESTAURANT_SCENE_PATH: String = "res://scenes/restaurant3d/restaurant_scene_3d.tscn"
const INTRO_SCENE_PATH: String = "res://scenes/intro/intro_scene.tscn"

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _quit_button: Button = %QuitButton
@onready var _status_label: Label = %StatusLabel

## Set after the first "New Game" press when a save exists.
var _confirm_new_game: bool = false


func _ready() -> void:
	Sfx.ambience("sea")
	_continue_button.pressed.connect(_on_continue_pressed)
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	var help := HelpPanel.new()
	add_child(help)
	var help_button := Button.new()
	help_button.text = "Hướng dẫn"
	help_button.pressed.connect(help.open)
	_new_game_button.add_sibling(help_button)
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
	SceneRouter.go_to(RESTAURANT_SCENE_PATH if GameState.resume_at == "restaurant" else SEA_SCENE_PATH)


func _on_new_game_pressed() -> void:
	# The old save is overwritten when day 1 starts, so ask once first.
	if SaveSystem.has_save() and not _confirm_new_game:
		_confirm_new_game = true
		_new_game_button.text = "Chắc chắn? Bấm lần nữa"
		_status_label.text = "Chơi mới sẽ xóa tiến độ đã lưu (ngày %d)." % _saved_day()
		return
	GameState.reset()
	SceneRouter.go_to(INTRO_SCENE_PATH)  # Rin calls Bảo, then the first night at sea


func _saved_day() -> int:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(SaveSystem.SAVE_PATH)) == OK and json.data is Dictionary:
		var day: Variant = json.data.get("day")
		if day is float or day is int:
			return int(day)
	return 0


func _on_quit_pressed() -> void:
	SceneRouter.quit_game()
