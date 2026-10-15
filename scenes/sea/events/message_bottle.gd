class_name MessageBottle
extends PointOfInterest
## Night event: a bottle drifting with a note. Each one reads the next page
## of a story from someone who went "below the sea" (count saved in
## story_flags); once all are read, bottles are just sold as scrap.

const READ_FLAG: String = "bottles_read"

@export var scrap_value: int = 5
@export_multiline var pages: Array[String] = [
	"\"Gửi ai nhặt được: đêm qua tôi thấy đèn dưới đáy biển, sáng như một xóm chài.\"",
	"\"Biển ở đây có hai lớp. Lớp mình chèo thuyền, và một lớp nữa nằm ngay bên dưới.\"",
	"\"Cá Ông dẫn tôi tới mép sương rồi lặn xuống. Nó muốn tôi đi theo.\"",
	"\"Có tàu lạ sơn xanh đen, không treo cờ, thả máy móc xuống chỗ sương. Cá Ông nổi lên húc tàu đi. Chúng không ác, chúng đang giữ nhà.\"",
	"\"Nếu thằng cháu tôi đọc được: đừng tìm ông. Hay là... cứ tìm đi.\"",
	"\"La bàn chỉ thẳng xuống dưới. Tôi đi đây.\"",
]


func _interact() -> void:
	var read := pages_read()
	if read < pages.size():
		GameState.set_flag(READ_FLAG, read + 1)
		await dialog.ask(title, "Mẩu giấy ướt nhòe, nét chữ run run (%d/%d):\n\n%s" % [read + 1, pages.size(), pages[read]],
			PackedStringArray(["Cất vào túi"]))
	else:
		GameState.add_money(scrap_value)
		await dialog.ask(title, "Chai rỗng. Đem bán ve chai được %dk." % scrap_value, PackedStringArray(["Ừ"]))
	queue_free()


static func pages_read() -> int:
	var value: Variant = GameState.story_flags.get(READ_FLAG, 0)
	return int(value) if value is int or value is float else 0


func _draw() -> void:
	var bob := sin(_time * 2.0) * 1.5
	draw_set_transform(Vector2(0, bob), 0.4)
	draw_rect(Rect2(-5, -2.5, 10, 5), Color(0.4, 0.75, 0.55, 0.9))
	draw_rect(Rect2(5, -1.2, 3, 2.4), Color(0.6, 0.45, 0.3))
	draw_set_transform(Vector2.ZERO)
	super()
