class_name PhoneApp
extends CanvasLayer
## Rin's phone with "Rin's Catch", the app left over from the startup Rin
## and Bảo built (Rin is an IT graduate). `open_phone` (J) toggles it anywhere at sea or in the restaurant;
## the game pauses while it's open. Tabs: storage, menu, map (PhoneMap),
## dex, boat, ledger, upgrades (PhoneShop, the only place to buy upgrades),
## staff (PhoneStaff: hire / dismiss / job ads, from the staff unlock day),
## plus a console log where story clues appear. Content comes from PhoneReports.
## The boat tab has the repair button (at sea: only at the dock). `open_map`
## (M) opens the big map (MapOverlay) instead of the phone.
## Put it LAST in the scene tree so it gets J/Esc before other overlays.

const APP_TITLE: String = "Rin's Catch v0.3.1"
const TAB_NAMES: Array[String] = ["Kho", "Menu", "Bản đồ", "Dex", "Thuyền", "Sổ sách", "Nâng cấp", "Nhân viên"]
const MAP_TAB: int = 2
const SHOP_TAB: int = 6
## Hidden until StaffCatalog.unlock_day (fish orders live in the QuestTracker).
const STAFF_TAB: int = 7
const BOAT_TAB: int = 4
## VT323 glyphs are small for their size; multiply sizes by this.
const NEO_FONT_SCALE: float = 1.5

@export var fish_catalog: FishCatalog
@export var menu: DishCatalog
@export var boat_upgrade: UpgradeData
@export var lamp_upgrade: UpgradeData
@export var fridge_upgrade: UpgradeData
## Upgrades listed in the boat tab and sold in the upgrades tab.
@export var upgrades: Array[UpgradeData] = []
@export var font_size: int = 9
## For the forecast log line.
@export var weather_catalog: WeatherCatalog
@export var staff_catalog: StaffCatalog = preload("res://data/staff/staff_catalog.tres")

var _tab: int = 0
var _opened_pause: bool = false
var _tab_buttons: Array[Button] = []
var _staff: PhoneStaff
var _repair: RepairButton
var _big_map: MapOverlay
## Set by the sea scene: () -> bool (at the dock) and () -> int (repair).
var repair_allowed: Callable
var repair_action: Callable

@onready var _title_label: Label = %AppTitle
@onready var _tabs_row: HBoxContainer = %TabsRow
@onready var _content_label: Label = %ContentLabel
@onready var _scroll: ScrollContainer = %Scroll
@onready var _map: PhoneMap = %Map
@onready var _shop: PhoneShop = %Shop
@onready var _log_label: Label = %LogLabel


func _ready() -> void:
	hide()
	# Pixel terminal look (VT323, "NeoLabel"): an app a developer made for himself.
	# VT323 runs small, so its sizes are scaled up from the scene's.
	for label: Label in [_content_label, _log_label, _title_label]:
		label.theme_type_variation = &"NeoLabel"
		label.add_theme_font_size_override("font_size", roundi(label.get_theme_font_size("font_size") * NEO_FONT_SCALE))
	for i in TAB_NAMES.size():
		var button := Button.new()
		button.text = TAB_NAMES[i]
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", font_size)
		button.pressed.connect(_show_tab.bind(i))
		_tabs_row.add_child(button)
		_tab_buttons.append(button)
	_shop.setup(upgrades)
	_staff = PhoneStaff.new()
	_staff.size_flags_vertical = _shop.size_flags_vertical
	_staff.custom_minimum_size = _shop.custom_minimum_size
	_shop.add_sibling(_staff)
	_staff.setup(staff_catalog)
	_repair = RepairButton.new()
	_repair.boat_upgrade = boat_upgrade
	_repair.focus_mode = Control.FOCUS_NONE
	_repair.add_theme_font_size_override("font_size", font_size)
	_repair.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var style := StyleBoxFlat.new()  # stands out from the console text
	style.bg_color = Color(0.25, 0.18, 0.08)
	style.border_color = Color(1.0, 0.75, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(4)
	_repair.add_theme_stylebox_override("normal", style)
	_repair.add_theme_stylebox_override("hover", style)
	_repair.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	_scroll.add_sibling(_repair)
	_repair.repaired.connect(func(_spent: int, _fully: bool) -> void: _show_tab(_tab))
	_big_map = MapOverlay.new()
	add_child(_big_map)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_map"):
		get_viewport().set_input_as_handled()
		if _big_map.visible:
			_big_map.close()
		elif not get_tree().paused or visible:
			close()
			_big_map.open()
		return
	if _big_map.visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_big_map.close()
		return
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
		_step_tab(-1)
	elif visible and event.is_action_pressed("turn_right"):
		get_viewport().set_input_as_handled()
		_step_tab(1)


## Next / previous visible tab (A / D).
func _step_tab(direction: int) -> void:
	var index := _tab
	for i in TAB_NAMES.size():
		index = posmod(index + direction, TAB_NAMES.size())
		if _tab_buttons[index].visible:
			break
	_show_tab(index)


func open() -> void:
	_opened_pause = not get_tree().paused
	get_tree().paused = true
	$Phone/Margin/VBox/Hint.visible = GameState.is_first_day()
	_tab_buttons[STAFF_TAB].visible = GameState.day >= staff_catalog.unlock_day
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
	_map.visible = index == MAP_TAB
	_shop.visible = index == SHOP_TAB
	_staff.visible = index == STAFF_TAB
	_scroll.visible = index not in [MAP_TAB, SHOP_TAB, STAFF_TAB]
	if index == SHOP_TAB:
		_shop.refresh()
	if index == STAFF_TAB:
		_staff.refresh()
	_repair.allowed = repair_allowed
	_repair.action = repair_action
	_repair.refresh()
	_repair.visible = _repair.visible and index == BOAT_TAB
	_content_label.text = _tab_text(index)
	var weather: WeatherData = weather_catalog.find(GameState.weather_id) if weather_catalog else null
	_log_label.text = "\n".join(PhoneReports.log_lines(_fridge_loss(), weather))


func _tab_text(index: int) -> String:
	match index:
		0:
			return PhoneReports.storage_report(_fridge_loss())
		1:
			return PhoneReports.menu_report(menu, _fish_names())
		MAP_TAB, SHOP_TAB, STAFF_TAB:
			return ""
		3:
			# Seed changes with the day so the glitch "moves" between visits.
			return PhoneReports.dex_report(fish_catalog, GameState.day)
		4:
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
