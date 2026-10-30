class_name RunClipping
extends Control
## The ending's run card as a newspaper clipping ("ClippingPanel"): masthead
## "TIN XÓM ĐÈN", a grainy "photo" of Rin's boat heading into the fog, the
## run's numbers as icon rows (EndingStats.values), the playtest thank-you
## in small ink, and a red "CÒN TIẾP" stamp that slams onto the corner.
## Taped to the white screen, a little crooked.

const INK := Color("090a14")
const RED := Color("a53030")

var _paper: PanelContainer
var _stamp: Label


func setup(stats: Dictionary, thanks: String) -> void:
	custom_minimum_size = Vector2(300, 196)
	_paper = PanelContainer.new()
	_paper.theme_type_variation = &"ClippingPanel"
	_paper.position = Vector2(6, 8)
	_paper.custom_minimum_size = Vector2(286, 0)
	add_child(_paper)
	_paper.draw.connect(func() -> void:
		UiStickers.draw(_paper, "tape", Vector2(22, 1))
		UiStickers.draw(_paper, "tape", Vector2(_paper.size.x - 24, 1)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_paper.add_child(box)
	var head := _label("TIN XÓM ĐÈN", 14, &"TitleLabel")
	head.add_theme_color_override("font_color", INK)
	head.add_theme_constant_override("outline_size", 0)
	box.add_child(head)
	var rule := ColorRect.new()
	rule.color = INK
	rule.custom_minimum_size.y = 2
	box.add_child(rule)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var photo := _Photo.new()
	photo.custom_minimum_size = Vector2(96, 72)
	row.add_child(photo)
	var facts := VBoxContainer.new()
	facts.add_theme_constant_override("separation", 1)
	row.add_child(facts)
	facts.add_child(_fact("calendar", "%d ngày" % int(stats["days"])))
	facts.add_child(_fact("clock", "%d phút" % int(stats["minutes"])))
	facts.add_child(_fact("fish", "%d · %d/%d" % [int(stats["fish"]), int(stats["species"]), int(stats["species_total"])]))
	facts.add_child(_fact("people", "%d bàn" % int(stats["served"])))
	facts.add_child(_fact("money", "%dk" % int(stats["earned"])))
	var note := _label(thanks, 8, &"InkLabel")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = 270
	box.add_child(note)
	_stamp = _label("CÒN TIẾP...", 13, &"BadgeLabel")
	_stamp.position = Vector2(190, 96)
	_stamp.visible = false
	add_child(_stamp)


## Slides the clipping in, then slams the stamp.
func reveal() -> void:
	UiFx.settle(_paper, Vector2(0, -30), 0.0, -8.0)
	UiFx.tilt(_paper, -1.0)
	Sfx.play("shutter")
	await get_tree().create_timer(0.7).timeout
	_stamp.visible = true
	UiFx.tilt(_stamp, -8.0)
	UiFx.stamp(_stamp, _paper)
	Sfx.play("stamp")


func _fact(icon: String, text: String) -> HBoxContainer:
	var fact := UiIcons.pair(icon, text, 12, RED, &"TitleLabel", 12)
	var label := fact.get_node("Text") as Label
	label.add_theme_color_override("font_color", INK)
	label.add_theme_constant_override("outline_size", 0)
	return fact


func _label(text: String, size: int, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.add_theme_font_size_override("font_size", size)
	return label


## Grainy newsprint "photo": night sea, fog, Rin's boat and its lamp.
class _Photo extends Control:
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color("090a14"))
		var inner := r.grow(-2.0)
		draw_rect(inner, Color("394a50"))
		draw_rect(Rect2(inner.position.x, inner.position.y + inner.size.y * 0.55, inner.size.x, inner.size.y * 0.45), Color("202e37"))
		for i in 4:  # fog bands
			draw_rect(Rect2(inner.position.x, inner.position.y + 8 + i * 9, inner.size.x, 3), Color("819796", 0.35))
		var hull := inner.position + Vector2(inner.size.x * 0.42, inner.size.y * 0.55)
		draw_rect(Rect2(hull + Vector2(-14, -2), Vector2(28, 5)), Color("090a14"))
		draw_rect(Rect2(hull + Vector2(-2, -14), Vector2(2, 12)), Color("090a14"))
		draw_rect(Rect2(hull + Vector2(1, -15), Vector2(3, 3)), Color("f2d98a"))
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 160:  # newsprint grain
			draw_rect(Rect2(inner.position + Vector2(rng.randf() * inner.size.x, rng.randf() * inner.size.y).floor(),
				Vector2.ONE), Color("c7cfcc", 0.18))
