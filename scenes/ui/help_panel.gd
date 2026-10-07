class_name HelpPanel
extends CanvasLayer
## "Hướng dẫn" screen: every control and rule in one place (sea, restaurant,
## phone, tips), opened from the pause menu and the main menu. In-game hint
## texts only show on day 1; after that this is where the player looks.
## Works while paused. Built in code.

signal closed

const SECTIONS: Array[String] = ["Biển", "Quán", "Điện thoại", "Mẹo"]
const TEXTS: Array[String] = [
	"""LÁI THUYỀN
  W / S: tiến / lùi      A / D: bẻ lái
  Dầu đèn = thời gian của đêm. Hết dầu ngoài khơi phải gọi cứu hộ.
  Đậu ở bến không tốn dầu.

CÂU CÁ
  Dừng thuyền ở đám bọt, bấm E để câu.
  Chờ phao CHÌM HẲN rồi bấm Space / chuột trái (phao nhấp là cá đang rỉa).
  Cá kéo dây: giữ Space để kim nằm trong vùng xanh (vùng chớp cam = cá sắp lao).
  Cá bấm nhịp: bấm khi kim đi qua vùng xanh.

LƯỚI ỐC
  Q: thả lưới ở vùng nước nông. Để một lúc, quay lại phao bấm E để kéo.

KHOANG
  Tab: mở khoang. Kéo-thả để xếp, R: xoay, thả vào "Bỏ" để vứt.

BẾN
  Nút "Dỡ cá vào kho" (E): khoang trống lại, đêm vẫn tiếp tục.
  Nút "Về nhà ngủ": hết đêm.   F: sửa thuyền.

ĐIỂM GHÉ
  Lại gần chỗ có đèn (miếu, chòi, hải đăng, bè...) bấm E.""",
	"""CHUẨN BỊ
  Chọn món và số phần cho menu, rồi bấm "Mở quán".
  Hết món thì khách chỉ gọi đậu phộng (rẻ). Menu dưới 3 món bị chê đơn điệu.
  Hải sản thừa trả về kho; rau mua chợ thừa thì bỏ.

PHỤC VỤ
  A / D: Rin đi.   E ở cửa BẾP: vào bếp (thời gian vẫn chạy).
  Trong bếp: bấm khay (hoặc phím số) để nấu, món xong đặt lên kệ.
  Chọn món trên kệ để vứt vào sọt rác, hoặc để Rin cầm ra.
  E / Esc: ra khỏi bếp.

NẤU
  Nướng: bấm khi kim vào vùng xanh.   Hấp: giữ rồi thả đúng lúc.
  Xào: bấm liên tục cho đầy thanh.

BẢO VÀ BÀN
  Bảo tự bưng món cho khách vào trước, rảnh thì dọn bàn bẩn.
  E cạnh bàn: đặt món Rin đang cầm, hoặc dọn bàn bẩn.
  Khách quen (bóng thoại vàng) tới ăn món đã đặt trước.

HẾT CA
  Bảng tổng kết -> "Đóng" -> "Ra khơi". Nút "Nâng cấp" để mua đồ.""",
	"""ĐIỆN THOẠI (J)
  A / D: đổi tab.   J / Esc: đóng.   Game tạm dừng khi mở.

  Kho: cá trong kho, độ tươi, còn mấy đêm.
  Menu: món nấu được bao nhiêu phần, thiếu gì.
  Đơn: khách quen đặt cá.
  Bản đồ: click để ghim / bỏ ghim (ghim hiện mũi tên khi ra khơi).
  Dex: các loài đã bắt, kỷ lục cân nặng.
  Thuyền / Sổ sách: tình trạng thuyền, lãi từng ngày.
  Nâng cấp: mua đồ, có hiệu lực cho chuyến / ca sau.""",
	"""MẸO
  Màu bọt cho biết loài cá. Càng ra xa bờ cá càng xịn và to.
  Bóng cá lớn dưới bọt = cá to, giá cao.
  Sóng lớn chặn thuyền nhỏ: nâng cấp thuyền để đi xa hơn.
  Đá ngầm chỉ thấy trong vòng đèn, đi chậm qua rạn đá.
  Dự báo thời tiết có ở màn sáng và trong điện thoại.
  Câu được con đủ ký cho đơn đặt, khách quen sẽ ghé quán.
  Esc: tạm dừng. Game tự lưu lúc ra khơi và khi về bến.""",
]

var _content: Label
var _buttons: Array[Button] = []


func _ready() -> void:
	layer = 31
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	hide()


func open() -> void:
	show()
	_show_section(0)


func close() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("pause") or event.is_action_pressed("interact")):
		get_viewport().set_input_as_handled()
		close()


func _show_section(index: int) -> void:
	_content.text = TEXTS[index]
	for i in _buttons.size():
		_buttons[i].button_pressed = i == index


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 30
	panel.offset_top = 16
	panel.offset_right = -30
	panel.offset_bottom = -16
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "HƯỚNG DẪN"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	header.add_child(title)
	for i in SECTIONS.size():
		var button := Button.new()
		button.text = SECTIONS[i]
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 10)
		button.pressed.connect(_show_section.bind(i))
		header.add_child(button)
		_buttons.append(button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close_button := Button.new()
	close_button.text = "Đóng (Esc)"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_size_override("font_size", 10)
	close_button.pressed.connect(close)
	header.add_child(close_button)
	box.add_child(header)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_content = Label.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_theme_font_size_override("font_size", 9)
	scroll.add_child(_content)
