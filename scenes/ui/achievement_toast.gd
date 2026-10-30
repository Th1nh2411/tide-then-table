class_name AchievementToast
extends CanvasLayer
## New-achievement toast: slides down at the top centre — trophy icon, the
## badge's icon, its short title (TitleLabel) and "+50k" with a coin.
## Queued, one at a time, hides by itself. `push()` from its owner.

const HOLD_SECONDS := 2.6

var _queue: Array[Dictionary] = []
var _panel: PanelContainer
var _badge: TextureRect
var _name: Label
var _reward: Label
var _coin: TextureRect
var _busy := false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.1, 0.08, 0.94)
	style.border_color = Color("f2d98a")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(5)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 4
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(row)
	row.add_child(GoalIcons.rect("trophy", 24))
	_badge = GoalIcons.rect("star", 16)
	_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_badge)
	_name = Label.new()
	_name.theme_type_variation = &"TitleLabel"
	_name.add_theme_font_size_override("font_size", 13)
	_name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_name)
	_coin = GoalIcons.rect("money", 10)
	_coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_coin)
	_reward = Label.new()
	_reward.add_theme_font_size_override("font_size", 10)
	_reward.add_theme_color_override("font_color", Color("f2d98a"))
	_reward.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_reward)
	_panel.hide()


## Queue one toast.
func push(title: String, icon_id: String, reward_k: int) -> void:
	_queue.append({"title": title, "icon": icon_id, "reward": reward_k})
	if not _busy:
		_next()


func is_showing() -> bool:
	return _busy


func _next() -> void:
	if _queue.is_empty():
		_busy = false
		_panel.hide()
		return
	_busy = true
	var entry: Dictionary = _queue.pop_front()
	_name.text = str(entry["title"])
	_badge.texture = GoalIcons.icon(str(entry["icon"]))
	var reward: int = int(entry["reward"])
	_reward.text = "+%dk" % reward
	_reward.visible = reward > 0
	_coin.visible = reward > 0
	_panel.modulate.a = 1.0
	_panel.show()
	_panel.reset_size()
	var width: float = get_viewport().get_visible_rect().size.x
	_panel.position = Vector2(roundf((width - _panel.size.x) * 0.5), 10.0)
	UiFx.slide_in(_panel, Vector2(0, -36))
	UiFx.bounce(_badge, 0.3)
	Sfx.play("coins")
	var out := _panel.create_tween()
	out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	out.tween_interval(HOLD_SECONDS)
	out.tween_property(_panel, "modulate:a", 0.0, 0.3)
	out.tween_callback(_next)
