class_name PhoneApp
extends CanvasLayer
## Rin's phone with "Rin's Catch", the app Rin wrote back when Rin was a
## developer. `open_phone` (J) toggles it anywhere at sea or in the restaurant;
## the game pauses while it's open. Tabs: storage, menu, dex, boat, ledger,
## plus a console log where story clues appear. Content comes from PhoneReports.
## Put it LAST in the scene tree so it gets J/Esc before other overlays.

const APP_TITLE: String = "Rin's Catch v0.3.1"
const TAB_NAMES: Array[String] = ["Kho", "Menu", "Dex", "Thuyền", "Sổ sách"]

@export var fish_catalog: FishCatalog
@export var menu: DishCatalog
@export var boat_upgrade: UpgradeData
@export var lamp_upgrade: UpgradeData
@export var fridge_upgrade: UpgradeData
## Upgrades listed in the boat tab.
@export var upgrades: Array[UpgradeData] = []
@export var font_size: int = 9

var _tab: int = 0
var _opened_pause: bool = false
var _tab_buttons: Array[Button] = []
var _mono: SystemFont

@onready var _title_label: Label = %AppTitle
@onready var _tabs_row: HBoxContainer = %TabsRow
@onready var _content_label: Label = %ContentLabel
@onready var _log_label: Label = %LogLabel


func _ready() -> void:
	hide()
	# Monospace look: "an app a developer made for themselves".
	_mono = SystemFont.new()
	_mono.font_names = PackedStringArray(["Menlo", "Consolas", "DejaVu Sans Mono", "Courier New", "monospace"])
	for label: Label in [_content_label, _log_label, _title_label]:
		label.add_theme_font_override("font", _mono)
	for i in TAB_NAMES.size():
		var button := Button.new()
		button.text = TAB_NAMES[i]
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", font_size)
		button.pressed.connect(_show_tab.bind(i))
		_tabs_row.add_child(button)
		_tab_buttons.append(button)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_phone"):
		get_viewport().set_input_as_handled()
		if visible:
			close()
		elif not get_tree().paused:
			open()
	elif visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
	elif visible and event.is_action_pressed("turn_left"):
		get_viewport().set_input_as_handled()
		_show_tab(posmod(_tab - 1, TAB_NAMES.size()))
	elif visible and event.is_action_pressed("turn_right"):
		get_viewport().set_input_as_handled()
		_show_tab(posmod(_tab + 1, TAB_NAMES.size()))


func open() -> void:
	_opened_pause = not get_tree().paused
	get_tree().paused = true
	show()
	_show_tab(_tab)


func close() -> void:
	hide()
	if _opened_pause:
		get_tree().paused = false
		_opened_pause = false


func _show_tab(index: int) -> void:
	_tab = index
	for i in _tab_buttons.size():
		_tab_buttons[i].button_pressed = i == index
	_title_label.text = "%s   %s" % [APP_TITLE, DayClock.get_time_text()]
	_content_label.text = _tab_text(index)
	_log_label.text = "\n".join(PhoneReports.log_lines(_fridge_loss()))


func _tab_text(index: int) -> String:
	match index:
		0:
			return PhoneReports.storage_report(_fridge_loss())
		1:
			return PhoneReports.menu_report(menu, _fish_names())
		2:
			# Seed changes with the day so the glitch "moves" between visits.
			return PhoneReports.dex_report(fish_catalog, GameState.day)
		3:
			var boat: BoatData = GameState.get_upgrade_value(boat_upgrade)
			return PhoneReports.boat_report(boat, float(GameState.get_upgrade_value(lamp_upgrade)), upgrades)
		_:
			return PhoneReports.ledger_report()


func _fridge_loss() -> float:
	return float(GameState.get_upgrade_value(fridge_upgrade)) if fridge_upgrade else 35.0


func _fish_names() -> Dictionary:
	var names: Dictionary = {}
	for fish in fish_catalog.fish:
		names[fish.id] = fish.display_name
	return names
