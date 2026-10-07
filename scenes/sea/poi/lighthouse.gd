class_name Lighthouse
extends PointOfInterest
## Hải đăng Hòn Khô: a sweeping beam (a light circling the tower) and the old
## keeper's logbook. Each visit reads the next page; later pages unlock with
## the story (they point at the fog). Pages read are saved in story_flags.

const PAGE_FLAG: String = "lighthouse_pages_read"

## Where the tower stands, relative to this node (the visit area is on the
## water's edge, the tower on the island).
@export var tower_offset: Vector2 = Vector2(0, -60)
@export var beam_distance: float = 110.0
@export var beam_radius: float = 70.0
@export var beam_turns_per_second: float = 0.12
@export var beam_color: Color = Color(1.0, 0.95, 0.8)
@export_multiline var pages: Array[String] = [
	"Ngày 3 tháng 4. Đêm lặng. Đếm được mười hai ngọn đèn thuyền chài dưới Cửa Đại.",
	"Ngày 9 tháng 4. Phía đông bắc có một vùng nước không phản chiếu đèn hải đăng. Như mặt biển bị khoét một lỗ.",
	"Ngày 17 tháng 4. La bàn quay ngược. Có con cá thu phát sáng xanh nổi lên rồi chìm thẳng xuống, không bơi.",
	"Ngày 18 tháng 4. Sương phủ góc đông bắc. Dưới sương có tiếng thở dài như cá Ông. Tôi sẽ chèo ra xem. Ai đọc được thì...",
]
## Pages readable at each Story.stage(): [before omen, omen, fog open].
@export var pages_by_stage: Array[int] = [2, 3, 4]

var _beam_pivot: Node2D


func _ready() -> void:
	super()
	_beam_pivot = Node2D.new()
	_beam_pivot.position = tower_offset
	add_child(_beam_pivot)
	var beam := make_lamp(beam_color, beam_radius, 1.2)
	beam.position = Vector2(beam_distance, 0)
	_beam_pivot.add_child(beam)


func _process(delta: float) -> void:
	super(delta)
	_beam_pivot.rotation += TAU * beam_turns_per_second * delta


func _interact() -> void:
	var read := pages_read()
	var available := mini(pages_by_stage[clampi(Story.stage(), 0, pages_by_stage.size() - 1)], pages.size())
	if read < available:
		GameState.set_flag(PAGE_FLAG, read + 1)
		await dialog.ask(title, "Nhật ký người gác đèn, trang %d:\n\n%s" % [read + 1, pages[read]],
			PackedStringArray(["Đi tiếp"]))
	elif available < pages.size():
		await dialog.ask(title, "Đã đọc hết các trang còn đọc được. Mấy trang sau bị nước biển làm nhòe, để hôm khác thử lại.",
			PackedStringArray(["Đi tiếp"]))
	else:
		await dialog.ask(title, "Trang cuối dừng giữa câu. Người gác đèn chưa bao giờ quay về.",
			PackedStringArray(["Đi tiếp"]))


static func pages_read() -> int:
	var value: Variant = GameState.story_flags.get(PAGE_FLAG, 0)
	return int(value) if value is int or value is float else 0


func _draw() -> void:
	# White tower with a red band and a lit lantern room.
	var top := tower_offset
	draw_colored_polygon(PackedVector2Array([top + Vector2(-7, 30), top + Vector2(7, 30),
		top + Vector2(4, 0), top + Vector2(-4, 0)]), Color(0.92, 0.9, 0.85))
	draw_rect(Rect2(top + Vector2(-6, 12), Vector2(12, 5)), Color(0.75, 0.2, 0.15))
	draw_circle(top + Vector2(0, -3), 4.0, beam_color)
	super()
