class_name SocialMoment
extends CanvasLayer
## Shift-end "new posts" moment: on the right edge, a "+12" follower sticker
## with a heart, then 1-3 of the new posts slide in as phone notifications
## (small rotation settle + heart burst), hold, and slide away. Never takes
## input or blocks the summary. `play(social_result)` from RestaurantSocial3D.

const WIDTH := 196.0
const MAX_CARDS := 3
const STEP := 0.4
const HOLD := 4.5
const TOP := 64.0

var _items: Array[Control] = []


func _ready() -> void:
	layer = 19
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_showing() -> bool:
	return not _items.is_empty()


## `social` = XomDenReview.apply_shift's result.
func play(social: Dictionary) -> void:
	_clear()
	var width: float = get_viewport().get_visible_rect().size.x
	var x := width - WIDTH - 8.0
	var delta := int(social.get("followers_after", 0)) - int(social.get("followers_before", 0))
	var sticker := _follower_sticker(delta)
	sticker.position = Vector2(x + WIDTH - sticker.size.x, TOP)
	sticker.rotation_degrees = 4.0
	UiFx.pop_in(sticker)
	var y := TOP + sticker.size.y + 4.0
	var posts: Array = social.get("posts", [])
	for i in mini(posts.size(), MAX_CARDS):
		var card := ReviewPostCard.make(posts[i], true)
		_add(card)
		card.size = Vector2(WIDTH, 0)
		card.reset_size()
		card.size.x = WIDTH
		card.position = Vector2(x - (i % 2) * 6.0, y)  # a little uneven, like stacked notifications
		y += card.size.y + 3.0
		_slide(card, STEP * (i + 1), 1.5 if i % 2 == 0 else -1.2)
	var out := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	out.tween_interval(HOLD + STEP * mini(posts.size(), MAX_CARDS))
	out.tween_callback(_leave)


func _follower_sticker(delta: int) -> PanelContainer:
	var sticker := PanelContainer.new()
	sticker.add_theme_stylebox_override("panel", SocialStyle.frame("rank_sticker" if delta >= 0 else "social_card", 3))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sticker.add_child(row)
	row.add_child(GoalIcons.rect("follower", 16))
	var number := SocialStyle.number("%+d" % delta, 15, SocialStyle.LIGHT if delta >= 0 else SocialStyle.INK_RED)
	row.add_child(number)
	_add(sticker)
	sticker.reset_size()
	return sticker


func _add(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(control)
	_items.append(control)


## Slides in from the right, overshoots its tilt and settles; hearts burst.
func _slide(card: ReviewPostCard, delay: float, settle: float) -> void:
	var home := card.position
	card.pivot_offset = Vector2(WIDTH * 0.5, card.size.y * 0.5)
	card.position = home + Vector2(WIDTH + 20.0, 0)
	card.rotation_degrees = 10.0
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
	# Each new post lands with a camera click.
	tween.tween_callback(Sfx.play.bind("shutter")).set_delay(delay)
	tween.tween_property(card, "position", home, 0.3).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation_degrees", -settle * 2.0, 0.22).set_delay(delay)
	tween.chain().tween_property(card, "rotation_degrees", settle * 0.5, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(_burst.bind(card))


func _burst(card: ReviewPostCard) -> void:
	if not is_instance_valid(card) or card.heart == null:
		return
	Sfx.play("ok")
	UiFx.bounce(card.heart, 0.35)
	var origin := card.position + card.heart.get_global_rect().get_center() - card.get_global_rect().position
	for i in 5:
		var heart := GoalIcons.rect("heart", 8)
		_add(heart)
		heart.position = origin - Vector2(4, 4)
		var angle := -PI * 0.5 + (i - 2) * 0.5
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
		tween.tween_property(heart, "position", heart.position + Vector2(cos(angle), sin(angle)) * 18.0, 0.45) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(heart, "modulate:a", 0.0, 0.45).set_delay(0.15)
		tween.chain().tween_callback(heart.queue_free)


func _leave() -> void:
	for item in _items:
		if is_instance_valid(item):
			var tween := item.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
			tween.tween_property(item, "position:x", item.position.x + WIDTH + 30.0, 0.3).set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(item, "modulate:a", 0.0, 0.3)
	var done := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	done.tween_interval(0.35)
	done.tween_callback(_clear)


func _clear() -> void:
	for item in _items:
		if is_instance_valid(item):
			item.queue_free()
	_items.clear()
