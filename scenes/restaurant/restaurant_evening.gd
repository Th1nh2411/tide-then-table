class_name RestaurantEvening
extends Node
## The restaurant's pinned buttons and what they do: "Sửa quán" (whenever
## the shop isn't serving: hides people / panels and hands over to
## RenovationMode) and "Ra khơi" (after the summary: storage ages overnight,
## maybe a new fish order, then the next night at sea).

signal message_requested(text: String)
## Renovation applied: upgrades may have changed.
signal renovated

const SEA_SCENE_PATH: String = "res://scenes/sea/sea_scene.tscn"

var hud: Control
var renovation: RenovationMode
## Hidden while renovating (people, bikes, markers, the HUD).
var world_layers: Array[CanvasItem] = []
var menu_panel: Control
var fridge_upgrade: UpgradeData
var fish_catalog: FishCatalog
## () -> bool: the summary was closed (sailing is possible).
var shift_over: Callable

var renovate_button: Button
var sail_button: Button


func _ready() -> void:
	renovate_button = _pin_button("Sửa quán", Rect2(292, 42, 85, 18))
	renovate_button.pressed.connect(_open_renovation)
	renovation.finished.connect(_on_renovation_finished)
	sail_button = _pin_button("Ra khơi  →", Rect2(520, 318, 114, 32))
	sail_button.pressed.connect(_start_next_day)
	sail_button.hide()


## Summary closed: the evening is free — upgrade, repair, then sail.
func show_evening() -> void:
	renovate_button.show()
	sail_button.show()


func _open_renovation() -> void:
	_set_room_ui_visible(false)
	renovation.open()


func _on_renovation_finished(applied: bool) -> void:
	_set_room_ui_visible(true)
	if applied:
		renovated.emit()
		message_requested.emit("Đã sửa quán!")


func _set_room_ui_visible(on: bool) -> void:
	for node in world_layers:
		node.visible = on
	menu_panel.visible = false
	sail_button.visible = on and shift_over.call()
	renovate_button.visible = on


func _pin_button(text: String, rect: Rect2) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 10)
	button.focus_mode = Control.FOCUS_NONE
	hud.add_child(button)
	# Sized once in the tree: before that the minimum size uses the default font.
	button.position = rect.position
	button.size = rect.size
	return button


func _start_next_day() -> void:
	var loss: float = float(GameState.get_upgrade_value(fridge_upgrade)) if fridge_upgrade else 35.0
	GameState.advance_day(loss)
	# Morning messages: maybe a new fish order (shown at sea and in the phone).
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	FishOrders.roll_new_order(rng, fish_catalog)
	SceneRouter.go_to(SEA_SCENE_PATH)
