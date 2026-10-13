class_name OldManHut
extends PointOfInterest
## Ông Tám's hut on Gò Vỏ Ốc: an old fisherman who patches hulls at sea (the
## only repair away from the dock, and pricier) and shares rumors/tips.

@export var hull: HullController
@export var patch_hp: float = 25.0
@export var patch_cost: int = 40
## Tips heard any night.
@export_multiline var rumors: Array[String] = [
	"\"Ra tuốt ngoài xa đêm nào cũng có bóng cá lớn lượn. Mà đèn yếu thì đừng ham, con.\"",
	"\"Bọt màu nâu đục là cá mú núp dưới đó. Rạn đá với ngoài khơi mới có.\"",
	"\"Câu được con to thì để dành giao khách quen, họ trả gấp mấy lần chợ.\"",
	"\"Chạy chậm mà đụng đá thì không sao. Chạy hết ga mà đụng là thủng thuyền liền.\"",
	"\"Bè tôm hùm của thằng Năm ở rạn đá, khoang đầy thì ghé bán đỡ cho nó.\"",
]
## Extra rumors once the omen happened / the fog is open (Story.stage() 1, 2).
@export_multiline var omen_rumors: Array[String] = [
	"\"Đêm qua tui thấy ánh xanh dưới nước phía đông bắc. Ba chục năm đi biển chưa thấy bao giờ.\"",
]
@export_multiline var fog_rumors: Array[String] = [
	"\"Cái la bàn của tui cứ quay mòng mòng mỗi lần tới gần đám sương. Con cẩn thận.\"",
	"\"Mấy đêm nay có tàu lạ sơn xanh đen chạy ra vùng sương, không treo cờ, đèn đỏ nhấp nháy. Không phải dân mình.\"",
]

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	super()
	_rng.randomize()


func _interact() -> void:
	var patch_label := "Nhờ vá thuyền (+%d bền, %dk)" % [roundi(patch_hp), patch_cost]
	if not BoatCondition.is_damaged():
		patch_label = "Nhờ vá thuyền (thuyền còn lành)"
	var choice := await dialog.ask(title, "Ông Tám ngồi vá lưới dưới ngọn đèn dầu.\n\"Ra trễ vậy con?\"",
		PackedStringArray([patch_label, "Hỏi chuyện", "Đi tiếp"]))
	match choice:
		0:
			if not BoatCondition.is_damaged():
				hud.flash_message("Thuyền còn lành mà, khỏi vá.")
			elif hull.patch(patch_hp, patch_cost):
				hud.flash_message("Ông Tám: Xong rồi đó con. (+%d bền, -%dk)" % [roundi(patch_hp), patch_cost], 2.0)
			else:
				hud.flash_message("Không đủ tiền nhờ ông Tám vá...")
		1:
			var line := pick_rumor(Story.stage(), _rng)
			if WaveMark.has_power() and not GameState.has_flag("tam_mark"):
				GameState.set_flag("tam_mark")
				line = "(nhìn tay con) Cá Ông đánh dấu con rồi đó. Biển nhường con một nhịp thở, " \
					+ "lúc nguy thì gọi nó. Mà gọi hoài là nó đòi lại đó nghe."
			await dialog.ask(title, "Ông Tám: " + line, PackedStringArray(["Đi tiếp"]))


## Random rumor from those unlocked at `stage`; story ones come up more.
func pick_rumor(stage: int, rng: RandomNumberGenerator) -> String:
	var pool: Array[String] = rumors.duplicate()
	if stage >= 1:
		for i in 3:
			pool.append_array(omen_rumors)
	if stage >= 2:
		for i in 3:
			pool.append_array(fog_rumors)
	return pool[rng.randi() % pool.size()]


func _draw() -> void:
	# Thatched hut on the island shore.
	draw_rect(Rect2(-12, -8, 24, 14), Color(0.55, 0.4, 0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(-16, -8), Vector2(16, -8), Vector2(0, -20)]),
		Color(0.75, 0.65, 0.35))
	draw_rect(Rect2(-3, -1, 6, 7), Color(0.95, 0.75, 0.35))  # lit doorway
	super()
