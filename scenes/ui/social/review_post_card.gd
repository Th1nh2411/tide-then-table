class_name ReviewPostCard
extends PanelContainer
## One "Xóm Đèn Review" post (XomDenReview post Dictionary) as a flat paper
## card: avatar, nickname, star row, short caption, the dish's picture and a
## chunky heart + likes counter. `compact` = the shift-end notification.

const DISH_PX := 26.0

var post: Dictionary = {}
var likes_label: Label
var heart: TextureRect


static func make(entry: Dictionary, compact: bool = false) -> ReviewPostCard:
	var card := ReviewPostCard.new()
	card.post = entry
	card._build(compact)
	return card


func _build(compact: bool) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", SocialStyle.frame("social_notif" if compact else "social_card", 3))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	var avatar := ReviewAvatar.new(str(post.get("author", "")), 18.0 if compact else 22.0)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(avatar)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", -2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 3)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(head)
	head.add_child(SocialStyle.label(str(post.get("name", "")), 6, SocialStyle.MUTED))
	head.add_child(_stars(int(post.get("stars", 3))))
	if bool(post.get("hot", false)):
		head.add_child(GoalIcons.rect("chili", 8))
	var caption := SocialStyle.label(str(post.get("caption", "")), 8,
		SocialStyle.INK_RED if str(post.get("mood", "")) == "angry" else SocialStyle.INK)
	text.add_child(caption)
	row.add_child(_dish_picture(str(post.get("dish", "")), 20.0 if compact else DISH_PX))
	var like_box := HBoxContainer.new()
	like_box.add_theme_constant_override("separation", 1)
	like_box.custom_minimum_size.x = 34
	like_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(like_box)
	heart = GoalIcons.rect("heart", 12)
	heart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	like_box.add_child(heart)
	likes_label = SocialStyle.number(str(int(post.get("likes", 0))), 11, SocialStyle.SIGN_RED)
	likes_label.add_theme_constant_override("outline_size", 0)
	likes_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	like_box.add_child(likes_label)


func _stars(count: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 5:
		var star := GoalIcons.rect("star", 7)
		star.modulate = Color.WHITE if i < count else Color(0.3, 0.3, 0.32, 0.45)
		row.add_child(star)
	return row


## The dish sprite on a small plate (placeholder plate when no art).
func _dish_picture(dish_id: String, px: float) -> Control:
	var plate := Panel.new()
	plate.custom_minimum_size = Vector2(px, px)
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_theme_stylebox_override("panel", SocialStyle.frame("avatar_frame", 0))
	var art := Art.texture("dishes/" + dish_id) if dish_id != "" else null
	var view := GoalIcons.show(art if art else GoalIcons.icon("fish"), px - 4.0)
	view.position = Vector2(2, 2)
	view.size = Vector2(px - 4.0, px - 4.0)
	plate.add_child(view)
	return plate
