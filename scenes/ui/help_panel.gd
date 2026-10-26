class_name HelpPanel
extends CanvasLayer
## "Hướng dẫn" screen: every control and rule in one place (sea, restaurant,
## phone, tips), opened from the pause menu and the main menu. In-game hint
## texts only show on day 1; after that this is where the player looks.
## Works while paused. Built in code.

signal closed

const SECTIONS: Array[String] = ["Biển", "Quán", "Điện thoại", "Nhịp Sóng", "Mẹo"]
const TEXTS: Array[String] = [
	"""LÁI THUYỀN
  W / S: tiến / lùi      A / D: bẻ lái
  Dầu đèn = thời gian của đêm. Hết dầu ngoài khơi phải gọi cứu hộ.
  Đậu ở bến không tốn dầu.

CÂU CÁ
  Dừng thuyền ở đám bọt, bấm E để câu.
  Chờ phao CHÌM HẲN rồi bấm Space / chuột trái (phao nhấp là cá đang rỉa).
  Trong một lượt có cả đàn cá: A / D đưa thuyền và dây sang ngang, W / S nâng-hạ
    lưỡi. Đưa lưỡi chạm con muốn bắt rồi bấm Space / chuột trái để móc.
  Khi đã móc: A / D chạy theo cá để giữ dây thẳng, W kéo lên, S nhả dây khi căng.
  E giật tất tay: xanh = bắt ngay, vàng = kéo gần nhưng Rin choáng, đỏ = cá giật ngược.
    Cá gần mặt nước, dây thẳng, ít căng và ít choáng làm vùng xanh rộng hơn.
  Choáng giữ lại giữa các lượt câu trong đêm; đầy thanh thì Rin bất tỉnh và chuyến đi kết thúc.
  Câu tiếp cùng một đàn: cá cảnh giác và khó hơn, nhưng con cuối thường lớn hơn.

LƯỚI (tôm, cua, ốc)
  Q: thả lưới khi thuyền đứng yên. Để một lúc, quay lại phao bấm E để kéo.
  Gần bờ lưới ra nhiều tôm, vùng đá ra nhiều cua; ốc hương thì chỗ nào cũng có.

KHOANG
  Tab: mở khoang. Kéo-thả để xếp, R: xoay, thả vào "Bỏ" để vứt.

BẾN
  Nút "Dỡ cá vào kho" (E): khoang trống lại, đêm vẫn tiếp tục.
  Nút "Về nhà ngủ": hết đêm.
  Khoang gần đầy: về bến dỡ bớt rồi ra câu tiếp.

THUYỀN
  Va đá / sứa làm thuyền móp (ô "Thân thuyền"), móp nhiều thì chạy chậm, về 0 là phải gọi kéo về.
  Sửa ở bến: F, hoặc tab "Thuyền" trong điện thoại (J). Ngoài khơi: nhờ ông Tám vá (đắt hơn).

ĐIỂM GHÉ
  Lại gần chỗ có đèn (miếu, chòi, hải đăng, bè...) bấm E.
  Bè tôm hùm anh Út mua cá trong khoang (nửa giá): bán hết, hoặc "Chọn con để bán"
    rồi kéo cá vào ô "Bán" / chuột phải vào con cá.""",
	"""CHUẨN BỊ
  Bấm vào bảng hiệu LED (viền vàng nhấp nháy): chọn món và số phần, rồi "Mở quán" ("Đóng" để làm việc khác trước).
  Rau muống, tháp bia con mèo (từ ngày 2) luôn có trên menu: đứng trước quầy tạp hoá Cô Năm (bên phải)
    bấm E mở danh sách. Mua lẻ (nút trái / phím 1-9) hoặc mua sỉ rẻ hơn (nút xanh /
    Shift + số): rau 1 phần 10k / 10 phần 80k, bia 1 tháp 25k / 10 tháp 200k.
    Rau héo dần qua từng đêm nên đừng mua sỉ quá tay; bia để được.
  Đồ mua nằm trong túi trên tay Rin: mang về E ở tủ lạnh (sát tường, trên bàn kê) để cất,
    cất rồi Bảo mới nấu rau / Rin mới rót bia được. Tháp bia không cần nấu, chỉ cần rót.
  Hết rau / bia thì phải chạy sang mua (trước hoặc trong giờ bán).
  Hết hải sản thì khách chỉ gọi rau muống, bia. Menu dưới 3 món bị chê đơn điệu; nâng Bếp thì menu được 4, rồi 5 món (thêm món, giá cao hơn).
  Hải sản thừa trả về kho. Rau để qua ngày được nhưng héo dần như cá (tủ lạnh
    tốt thì lâu hơn), rau héo bán rẻ hơn, hết hạn thì bỏ. Bia để bao lâu cũng được.

PHỤC VỤ
  WASD: Rin đi. Shift: lướt nhanh. E: tác động vào ô Rin đang quay mặt vào (ô có viền trắng + phím E).
  Bảng LED nhỏ cạnh lề đường: hình các món hải sản hôm nay + số phần còn (X đỏ = hết).
  Trên cùng: phiếu order, cũ nhất bên trái (viền xanh = món đã có trên bàn kê).
  Bảo là đầu bếp: tự nấu món hấp, xào, rau muống rồi để lên bàn kê.
  Rin là phục vụ: bưng, dọn bàn, và tự làm món nướng + tháp bia.
  E ở lò than (dưới xe đẩy): Rin nướng món nướng của phiếu cũ nhất đang chờ
    (minigame nhỏ trên mặt đường, quán vẫn chạy), xong món nằm trên tay.
  E ở bình bia (đầu phải xe đẩy): rót tháp bia cho bàn gọi sớm nhất. Giữ Space /
    chuột trái để rót, nhả từng nhịp ngắn cho bọt xẹp, nhả hẳn khi mép bọt vào vạch
    xanh (ít bọt = tip thêm). Rót tràn mất 1 lít bia.
  Bàn kê món (nằm ngang cạnh xe đẩy): E đặt món xuống ô đó / cầm món ở ô đó lên.
  Thùng rác xanh cạnh xe đẩy: E vứt món đang cầm (món không ai gọi thì xô nhấp nháy đỏ).
  Nhân viên (từ ngày 3, điện thoại J → tab "Nhân viên"): tự bưng món Bảo nấu
    ra bàn và dọn bàn bẩn. Mỗi người kỹ năng, lương/ca riêng (trả cuối ca), tối đa 2.
    Đăng tin tuyển dụng (1 lần/ngày): tờ rơi 50k, hội nhóm 200k, trung tâm 500k:
    đăng chỗ xịn hơn thì người tới giỏi hơn (lương cũng cao hơn).
  Nhiệm vụ: ô nhỏ góc trên trái (rê chuột vào để xem đủ nhiệm vụ chính + đơn đặt cá).
  E cạnh người khác: nói chuyện (dấu "!" = có chuyện mới).

NƯỚNG
  Bấm khi kim vào vùng xanh.

BÀN
  Cầm món: bàn gọi món đó nhấp nháy xanh. Quay mặt vào bàn bấm E: đặt món, hoặc dọn bàn bẩn.
  Khách phần lớn đi xe máy tới, đỗ sát lề. Mỗi bàn 1-2 khách, gọi 1-3 món
    (bong bóng / phiếu có 1 chấm mỗi món còn chờ); món nào ra trước ăn trước,
    ăn hết có khi gọi thêm (hay là bia). Ăn xong hết mới trả tiền cả bàn.
  Khách quen (bóng thoại vàng) tới ăn món đã đặt trước.

HẾT CA
  Đóng quán (sớm / hết giờ): không có khách mới, phục vụ nốt khách trong quán.
  Bảng tổng kết -> "Đóng" -> "Ra khơi".

SỬA QUÁN (trước giờ mở / sau khi bán xong)
  Bấm "Sửa quán": đồ sửa được có viền xanh (bàn ghế, trang trí, bếp, thùng đá).
  Bấm vào đồ để chọn cấp, xem trước ngay. "Xác nhận" trả tiền, "Hủy" để bỏ.""",
	"""ĐIỆN THOẠI (J)
  A / D: đổi tab.   J / Esc: đóng.   Game tạm dừng khi mở.

  Kho: cá trong kho, độ tươi, còn mấy đêm.
  Menu: món nấu được bao nhiêu phần, thiếu gì.
  Bản đồ (hoặc phím M = bản đồ lớn): click để ghim / bỏ ghim (ghim hiện mũi tên khi ra khơi).
  Dex: các loài đã bắt, kỷ lục cân nặng.
  Thuyền: tình trạng thuyền + nút sửa (ngoài biển chỉ sửa ở bến).
  NEO, trợ lí trong app (góc dưới trái): nhắc dầu đèn, khoang, sửa thuyền, đơn đặt cá,
    báo món đang hot hôm nay (bán giá x1.5) và thưởng sưu tầm (loài mới, mốc Dex, kỷ lục).
  Sổ sách: lãi từng ngày.
  Nâng cấp: đồ nghề đi biển (thuyền, cần câu, đèn), có hiệu lực từ chuyến sau.
  (Đồ trong quán thì sửa bằng nút "Sửa quán".)""",
	"""NHỊP SÓNG (C, sau đêm điềm báo)
  Vệt sóng trên tay Rin: bấm C để làm chậm mọi thứ vài giây.
  Ngoài biển: lúc đang câu / kéo lưới. Ở quán: cả phố chậm lại, Rin vẫn chạy nhanh.
  Mỗi đêm và mỗi ca được vài lần (chấm xanh góc dưới trái); câu cá dị biến để có thêm.""",
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
