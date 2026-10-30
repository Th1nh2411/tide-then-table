class_name MenuPanelHeader3D
extends VBoxContainer
## Top of MenuPanel3D: title, icon + number stats (slots, servings, fish in
## storage, price factor), today's HOT dish chip, and the expected takings
## as a small per-dish bar chart + a coin total that counts.

const GOLD := Color("f2d98a")
const CHALK := Color("ebede9")
const CHILI := Color("cf573c")
const CHALK_YELLOW := Color("e8c170")

var heading: Label
## HOT dish / picker slot / "no fish" line (tests read it for "HOT").
var title_label: Label
var revenue_label: Label
var chart: MiniChart
var _stats: HBoxContainer
var _hot_chip: HBoxContainer
var _revenue: int = 0


func _init() -> void:
	add_theme_constant_override("separation", 2)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	row.add_child(UiIcons.make("menu", 18, GOLD))
	heading = Label.new()
	heading.theme_type_variation = &"TitleLabel"
	heading.add_theme_font_size_override("font_size", 17)
	row.add_child(heading)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	chart = MiniChart.new()
	chart.label_color = Color(CHALK, 0.7)
	chart.custom_minimum_size = Vector2(70, 24)
	chart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chart.tooltip_text = "Dự thu theo món"
	row.add_child(chart)
	row.add_child(UiIcons.make("money", 16, GOLD))
	revenue_label = Label.new()
	revenue_label.theme_type_variation = &"TitleLabel"
	revenue_label.add_theme_font_size_override("font_size", 17)
	revenue_label.custom_minimum_size.x = 44
	revenue_label.tooltip_text = "Dự thu nếu bán hết"
	revenue_label.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(revenue_label)
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 10)
	add_child(info)
	_stats = HBoxContainer.new()
	_stats.add_theme_constant_override("separation", 10)
	info.add_child(_stats)
	_hot_chip = HBoxContainer.new()
	_hot_chip.add_theme_constant_override("separation", 3)
	_hot_chip.add_child(UiIcons.make("hot", 13, CHILI))
	info.add_child(_hot_chip)
	title_label = Label.new()
	title_label.theme_type_variation = &"ChalkLabel"
	title_label.add_theme_font_size_override("font_size", 10)
	title_label.add_theme_color_override("font_color", CHALK_YELLOW)
	_hot_chip.add_child(title_label)


## Planning view: stats as icon + number, HOT chip when today has one.
func show_plan(plan: MenuPlan, menu: DishCatalog, variety: float, cookable: bool) -> void:
	heading.text = "THỰC ĐƠN"
	_set_stats([["menu", "%d/%d" % [plan.used_slots(), plan.slots], "Món trên menu"],
		["meal", "%d" % plan.total_portions(), "Tổng phần"],
		["fish", "%d" % GameState.storage.size(), "Hải sản trong kho"]]
		+ ([["sparkles", "x%s" % str(snappedf(variety, 0.01)), "Giá theo số món"]] if variety != 1.0 else []))
	var text := ""
	var hot := DailyTrend.dish_id()
	if hot != "":
		for dish in menu.dishes:
			if dish.id == hot:
				text = "HOT: " + dish.display_name
	if not cookable:
		text = "Chưa có cá: ra khơi trước"
	title_label.text = text
	_hot_chip.visible = text != ""


## Picker view: which slot is being filled.
func show_picker(slot: int) -> void:
	heading.text = "CHỌN MÓN"
	_set_stats([["menu", "Ô %d" % (slot + 1), "Ô đang chọn"]])
	title_label.text = ""
	_hot_chip.hide()


## Expected takings: one bar per dish (HOT in red) and the total.
func set_revenue(values: Array[float], labels: Array[String], hot_index: int, total: int, animate: bool) -> void:
	chart.highlight = hot_index
	chart.set_values(values, labels)
	if animate and total != _revenue:
		UiFx.count_to(revenue_label, _revenue, total, "%dk", 0.4)
		UiFx.bounce(revenue_label, 0.1)
	else:
		revenue_label.text = "%dk" % total
	_revenue = total


func count_up() -> void:
	UiFx.count_to(revenue_label, 0, _revenue, "%dk", 0.7)


func _set_stats(items: Array) -> void:
	for child in _stats.get_children():
		_stats.remove_child(child)
		child.queue_free()
	for item: Array in items:
		var pair := UiIcons.pair(str(item[0]), str(item[1]), 12, CHALK, &"ChalkLabel", 10)
		pair.tooltip_text = str(item[2])
		pair.mouse_filter = Control.MOUSE_FILTER_PASS
		_stats.add_child(pair)
