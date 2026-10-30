class_name PhoneAchievements
extends ScrollContainer
## "Thành tựu" tab of the phone: a grid of badge tiles. Unlocked = gold
## border and full-colour icon; locked = greyed icon, a lock and a progress
## bar (GameState.stats via Achievements). Name under the icon, the rest
## (description, n/target, reward) in the tooltip.

const GOLD := Color("f2d98a")
const DIM := Color(0.55, 0.6, 0.64)
const COLUMNS := 5
const TILE := Vector2(70, 58)

@export var font_size: int = 7
@export var catalog: AchievementCatalog = preload("res://data/achievements/achievement_catalog.tres")

var _box: VBoxContainer
var _count: Label
var _grid: GridContainer


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box.add_theme_constant_override("separation", 4)
	add_child(_box)
	var head := HBoxContainer.new()
	head.add_child(GoalIcons.rect("trophy", 16))
	_count = _label("", 9, GOLD)
	head.add_child(_count)
	_box.add_child(head)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	_box.add_child(_grid)


func tile_count() -> int:
	return _grid.get_child_count() if _grid else 0


func refresh() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_count.text = "%d/%d" % [Achievements.unlocked_count(catalog), catalog.achievements.size()]
	for achievement in catalog.achievements:
		_grid.add_child(_tile(achievement))
	UiFx.stagger(_grid, 0.025)


func _tile(achievement: AchievementData) -> Control:
	var unlocked := Achievements.is_unlocked(achievement)
	var value := Achievements.progress(achievement, GameState.stats)
	var tile := PanelContainer.new()
	tile.custom_minimum_size = TILE
	tile.tooltip_text = "%s\n%s\n%d/%d · +%dk" % [achievement.title, achievement.desc, value, achievement.target,
		achievement.reward_k]
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.16, 0.08) if unlocked else Color(0.1, 0.12, 0.14)
	style.border_color = GOLD if unlocked else Color(0.25, 0.3, 0.34)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(2)
	tile.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(column)
	var art := Control.new()
	art.custom_minimum_size = Vector2(24, 24)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(art)
	var icon := GoalIcons.show(GoalIcons.badge(achievement.id, achievement.icon), 24)
	icon.modulate = Color.WHITE if unlocked else Color(0.35, 0.38, 0.42)
	art.add_child(icon)
	if not unlocked:
		var lock := GoalIcons.rect("lock", 8)
		lock.position = Vector2(16, 16)
		art.add_child(lock)
	var name_label := _label(achievement.title, font_size, GOLD if unlocked else DIM)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.x = TILE.x - 6
	name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_constant_override("line_spacing", -3)
	column.add_child(name_label)
	if not unlocked:
		var bar := ProgressBar.new()
		bar.max_value = achievement.target
		bar.value = value
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(TILE.x - 10, 3)
		bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color(0.45, 0.75, 0.83)
		var back := StyleBoxFlat.new()
		back.bg_color = Color(0.2, 0.24, 0.28)
		bar.add_theme_stylebox_override("fill", fill)
		bar.add_theme_stylebox_override("background", back)
		column.add_child(bar)
	return tile


func _label(text: String, px: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"NeoLabel"
	label.add_theme_font_size_override("font_size", roundi(px * PhoneApp.NEO_FONT_SCALE))
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
