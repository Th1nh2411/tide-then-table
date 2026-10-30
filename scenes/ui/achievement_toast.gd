class_name AchievementToast
extends CanvasLayer
## New-achievement toast: a paper sticker slapped on at the top, between the
## HUD's left plank and its right buttons (`centre_x`) — the badge on a red
## plate, its short title (Paytone ink) and "+50k" in red ink with a coin.
## Queued, one at a time, hides by itself. `push()` from its owner.

const HOLD_SECONDS := 2.6

## Horizontal centre and top of the toast (clear of the top HUD).
@export var centre_x: float = 376.0
@export var top: float = 6.0

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
	_panel.theme_type_variation = &"PaperPanel"
	add_child(_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(row)
	row.add_child(UiIcons.make("trophy", 18, UiIcons.GOLD, Color("a53030")))
	_badge = GoalIcons.rect("star", 20)
	_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_badge)
	_name = HudChips.number(13, true)
	row.add_child(_name)
	_coin = UiIcons.make("money", 12, UiIcons.GOLD)
	row.add_child(_coin)
	_reward = Label.new()
	_reward.theme_type_variation = &"PriceLabel"
	_reward.add_theme_font_size_override("font_size", 13)
	_reward.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_reward)
	_panel.hide()


## Queue one toast.
func push(title: String, badge: Texture2D, reward_k: int) -> void:
	_queue.append({"title": title, "badge": badge, "reward": reward_k})
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
	_badge.texture = entry["badge"]
	var reward: int = int(entry["reward"])
	_reward.text = "+%dk" % reward
	_reward.visible = reward > 0
	_coin.visible = reward > 0
	_panel.modulate.a = 1.0
	_panel.show()
	_panel.reset_size()
	_panel.position = Vector2(roundf(centre_x - _panel.size.x * 0.5), top)
	UiFx.tilt(_panel, -2.0)
	UiFx.settle(_panel, Vector2(0, -30), 0.0, 9.0)
	UiFx.bounce(_badge, 0.3)
	Sfx.play("coins")
	var out := _panel.create_tween()
	out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	out.tween_interval(HOLD_SECONDS)
	out.tween_property(_panel, "modulate:a", 0.0, 0.3)
	out.tween_callback(_next)
