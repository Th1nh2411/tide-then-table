class_name PauseMenu
extends CanvasLayer
## Esc menu for the sea and the restaurant: resume / main menu / quit, plus a
## controls cheat sheet. Runs while paused (PROCESS_MODE_ALWAYS in the scene).
## Put it BEFORE other overlays in the tree: later nodes get input first, so
## e.g. the hold window can use Esc to close itself before this opens.

const MAIN_MENU_PATH: String = "res://scenes/main_menu/main_menu.tscn"

var _confirm_menu: bool = false

@onready var _resume_button: Button = %ResumeButton
@onready var _menu_button: Button = %MenuButton
@onready var _quit_button: Button = %QuitButton
@onready var _note_label: Label = %NoteLabel


func _ready() -> void:
	hide()
	_resume_button.pressed.connect(_resume)
	_menu_button.pressed.connect(_on_menu_pressed)
	_quit_button.pressed.connect(func() -> void: get_tree().quit())


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if visible:
		get_viewport().set_input_as_handled()
		_resume()
	elif not get_tree().paused:
		# Something else (hold overflow, hold mid-fishing) owns the pause: leave it.
		get_viewport().set_input_as_handled()
		_open()


func _open() -> void:
	_confirm_menu = false
	_menu_button.text = "Về menu chính"
	_note_label.text = "Game tự lưu lúc ra khơi và lúc cập bến về."
	get_tree().paused = true
	show()
	_resume_button.grab_focus()


func _resume() -> void:
	hide()
	get_tree().paused = false


## Two presses: leaving loses everything since this morning's autosave.
func _on_menu_pressed() -> void:
	if not _confirm_menu:
		_confirm_menu = true
		_menu_button.text = "Chắc chắn? Bấm lần nữa"
		_note_label.text = "Về menu sẽ mất tiến độ từ lúc ra khơi đêm nay tới giờ."
		return
	get_tree().paused = false
	hide()
	SceneRouter.go_to(MAIN_MENU_PATH)
