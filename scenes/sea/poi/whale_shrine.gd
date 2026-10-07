class_name WhaleShrine
extends PointOfInterest
## Miếu Cá Ông in Xóm Đèn: shrine of the whale god (cá Ông) that fishermen believe
## guides people lost at sea back to shore. Lighting incense blesses tonight's
## trip (less hull damage). The keeper's words follow the story stage.

@export var hull: HullController
@export var incense_cost: int = 10
## Hull damage multiplier for the rest of the night once blessed.
@export var blessed_damage_scale: float = 0.5
## Keeper's line per Story.stage() (0 before omen, 1 omen, 2 fog open).
@export_multiline var keeper_lines: Array[String] = [
	"Ông từ: \"Cá Ông là thần hộ mạng dân biển. Ai gặp nạn ngoài khơi, Ông dìu vô bờ. Thắp nhang rồi hẵng ra con.\"",
	"Ông từ: \"Mấy đêm nay ngư dân thấy cá Ông bơi ra hướng đông bắc rồi lặn mất, không trồi lên thở. Lạ lắm con.\"",
	"Ông từ: \"Hồi xưa ông nội con cũng chèo vô đám sương đó... Con đi thì nhớ đường về.\"",
]

var _blessed: bool = false


func _interact() -> void:
	var body := keeper_lines[clampi(Story.stage(), 0, keeper_lines.size() - 1)]
	if _blessed:
		await dialog.ask(title, body + "\n\nNhang còn cháy. Đêm nay Ông phù hộ.", PackedStringArray(["Đi tiếp"]))
		return
	var choice := await dialog.ask(title, body, PackedStringArray([
		"Thắp nhang (%dk): đêm nay thuyền đỡ hư hại khi va đá" % incense_cost, "Đi tiếp"]))
	if choice != 0:
		return
	if not GameState.spend_money(incense_cost):
		hud.flash_message("Không đủ tiền mua nhang")
		return
	_blessed = true
	hull.damage_scale = blessed_damage_scale
	hud.flash_message("Đã thắp nhang. Đêm nay va đá chỉ hư một nửa.", 2.0)


func _draw() -> void:
	# Small shrine on the sand: base, red pillars, curved tiled roof.
	var base := Vector2(0, 32)
	draw_rect(Rect2(base + Vector2(-18, -14), Vector2(36, 14)), Color(0.85, 0.8, 0.65))
	draw_rect(Rect2(base + Vector2(-14, -14), Vector2(4, 14)), Color(0.7, 0.2, 0.15))
	draw_rect(Rect2(base + Vector2(10, -14), Vector2(4, 14)), Color(0.7, 0.2, 0.15))
	draw_colored_polygon(PackedVector2Array([base + Vector2(-24, -14), base + Vector2(24, -14),
		base + Vector2(14, -24), base + Vector2(-14, -24)]), Color(0.45, 0.3, 0.2))
	if _blessed:
		# Incense smoke.
		for i in 3:
			var y := fmod(_time * 8.0 + i * 6.0, 18.0)
			draw_circle(base + Vector2(sin(_time + i) * 2.0, -26 - y), 1.5, Color(0.9, 0.9, 0.9, 0.6 - y / 30.0))
	super()
