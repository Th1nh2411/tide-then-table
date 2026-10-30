class_name PhoneReview
extends PanelContainer
## "Review" tab of the phone: the "Xóm Đèn Review" app. Header bar: follower
## count, tier badge + bar to the next tier, two icon tabs. Feed: post cards
## (XomDenReview posts, newest first). Ranking: rank sticker, weekly bars of
## the 4 eateries (RivalRanking) and Rin's earned per day. Icon-first.

var showing_rank: bool = false
var _followers: Label
var _tier_badge: TextureRect
var _tier_name: Label
var _tier_bar: ProgressBar
var _feed_button: Button
var _rank_button: Button
var _feed_scroll: ScrollContainer
var _feed: VBoxContainer
var _rank_view: MarginContainer
var _sticker: PanelContainer
var _rank_number: Label
var _chart: RankChart
var _sparkline: EarnSparkline
var _today: Label
var _shown_followers: int = 0


func _ready() -> void:
	var screen := StyleBoxFlat.new()
	screen.bg_color = Color("c7cfcc")  # Xam 7: the app's flat screen
	add_theme_stylebox_override("panel", screen)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	add_child(column)
	column.add_child(_header())
	_feed_scroll = ScrollContainer.new()
	_feed_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_feed_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_feed_scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: String in ["margin_left", "margin_right"]:
		pad.add_theme_constant_override(side, 5)
	_feed_scroll.add_child(pad)
	_feed = VBoxContainer.new()
	_feed.add_theme_constant_override("separation", 3)
	pad.add_child(_feed)
	column.add_child(_rank_section())


func _header() -> PanelContainer:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", SocialStyle.frame("social_header", 3))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	bar.add_child(row)
	var heart := GoalIcons.rect("follower", 16)
	heart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(heart)
	_followers = SocialStyle.number("0", 16)
	row.add_child(_followers)
	_tier_badge = GoalIcons.rect("tier_0", 16)
	_tier_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_tier_badge.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(_tier_badge)
	var tier_box := VBoxContainer.new()
	tier_box.add_theme_constant_override("separation", 0)
	tier_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tier_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tier_box)
	_tier_name = SocialStyle.label("", 7, SocialStyle.LIGHT)
	tier_box.add_child(_tier_name)
	_tier_bar = ProgressBar.new()
	_tier_bar.show_percentage = false
	_tier_bar.max_value = 1.0
	_tier_bar.custom_minimum_size = Vector2(70, 5)
	_tier_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_tier_bar.add_theme_stylebox_override("background", _flat(SocialStyle.APP_DARK))
	_tier_bar.add_theme_stylebox_override("fill", _flat(SocialStyle.GOLD))
	tier_box.add_child(_tier_bar)
	_feed_button = _tab_button("feed", false)
	_rank_button = _tab_button("podium", true)
	row.add_child(_feed_button)
	row.add_child(_rank_button)
	return bar


func _rank_section() -> MarginContainer:
	_rank_view = MarginContainer.new()
	for side: String in ["margin_left", "margin_right", "margin_top"]:
		_rank_view.add_theme_constant_override(side, 6)
	_rank_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_rank_view.add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	column.add_child(top)
	var holder := Control.new()  # the sticker is tilted and breaks out a bit
	holder.custom_minimum_size = Vector2(64, 44)
	top.add_child(holder)
	_sticker = PanelContainer.new()
	_sticker.add_theme_stylebox_override("panel", SocialStyle.frame("rank_sticker", 3))
	_sticker.position = Vector2(2, 2)
	_sticker.rotation_degrees = -7.0
	holder.add_child(_sticker)
	var sticker_row := HBoxContainer.new()
	sticker_row.add_theme_constant_override("separation", 2)
	_sticker.add_child(sticker_row)
	var podium := GoalIcons.rect("podium", 12)
	podium.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sticker_row.add_child(podium)
	_rank_number = SocialStyle.number("#1", 18)
	sticker_row.add_child(_rank_number)
	_chart = RankChart.new()
	_chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_chart)
	var widget := PanelContainer.new()  # Rin's days, as a small app widget
	widget.add_theme_stylebox_override("panel", SocialStyle.frame("social_card", 4))
	widget.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(widget)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	widget.add_child(row)
	var coin := GoalIcons.rect("money", 14)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(coin)
	_sparkline = EarnSparkline.new()
	_sparkline.custom_minimum_size = Vector2(150, 30)
	row.add_child(_sparkline)
	_today = SocialStyle.number("0k", 13, SocialStyle.SIGN_RED)
	_today.add_theme_constant_override("outline_size", 0)
	_today.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_today)
	return _rank_view


func _tab_button(icon_id: String, rank: bool) -> Button:
	var button := Button.new()
	button.icon = GoalIcons.icon(icon_id)
	button.expand_icon = true
	button.custom_minimum_size = Vector2(24, 20)
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "Xếp hạng" if rank else "Bài đăng"
	for state: String in ["normal", "hover", "disabled"]:
		button.add_theme_stylebox_override(state, SocialStyle.frame("social_tab_off", 2))
	for state: String in ["pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, SocialStyle.frame("social_tab_on", 2))
	button.pressed.connect(show_page.bind(rank))
	return button


func _flat(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = SocialStyle.INK
	box.set_border_width_all(1)
	return box


func refresh() -> void:
	var count := XomDenReview.followers()
	var level := XomDenReview.tier()
	UiFx.count_to(_followers, _shown_followers if _shown_followers <= count else 0, count, "%d")
	_shown_followers = count
	_tier_badge.texture = GoalIcons.icon("tier_%d" % level)
	_tier_badge.tooltip_text = XomDenReview.tier_name(level)
	_tier_name.text = XomDenReview.tier_name(level)
	_tier_bar.value = 0.0
	var fill := _tier_bar.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fill.tween_property(_tier_bar, "value", XomDenReview.tier_progress(count, level), 0.5)
	_fill_feed()
	var board := RivalRanking.week_board(GameState.day, GameState.day_history)
	_chart.set_board(board)
	_rank_number.text = "#%d" % RivalRanking.player_rank(board)
	# Only days the restaurant was open (day 1 on).
	var daily := RivalRanking.player_daily(GameState.day, GameState.day_history, mini(RivalRanking.CATALOG.week_days, GameState.day))
	_sparkline.set_values(daily)
	_today.text = SocialStyle.money(daily[-1] if not daily.is_empty() else 0)
	show_page(showing_rank)


func show_page(rank: bool) -> void:
	showing_rank = rank
	_feed_button.button_pressed = not rank
	_rank_button.button_pressed = rank
	_feed_scroll.visible = not rank
	_rank_view.visible = rank
	if rank:
		_chart.play(0.1)
		_sparkline.play(0.3)
		UiFx.pop_in(_sticker, 0.05)
	elif is_inside_tree():
		_slide_cards()


## Cards slide in one by one, after the list has laid them out.
func _slide_cards() -> void:
	for card in _feed.get_children():
		(card as Control).modulate.a = 0.0
	await get_tree().process_frame
	var i := 0
	for card in _feed.get_children():
		if card is Control and is_instance_valid(card):
			UiFx.slide_in(card, Vector2(24, 0), 0.05 * i)
			i += 1


func card_count() -> int:
	return _feed.get_child_count() if _feed else 0


func _fill_feed() -> void:
	for child in _feed.get_children():
		_feed.remove_child(child)
		child.queue_free()
	for post: Dictionary in XomDenReview.posts():
		_feed.add_child(ReviewPostCard.make(post))
	if _feed.get_child_count() == 0:
		var empty := HBoxContainer.new()
		empty.alignment = BoxContainer.ALIGNMENT_CENTER
		var icon := GoalIcons.rect("feed", 24)
		icon.modulate = Color(1, 1, 1, 0.4)
		empty.add_child(icon)
		empty.add_child(SocialStyle.label("Chưa có bài", 8, SocialStyle.MUTED))
		_feed.add_child(empty)
