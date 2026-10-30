class_name HelpEntries
extends RefCounted
## Content of the "Hướng dẫn" screen (HelpPanel). Each tab has groups (icon +
## short title) of rows [keys, caption]: keys are space-separated key caps
## ("W S", "Shift"), or "@<icon id>" for a picture instead of a key. Captions
## stay 2-4 words. Add new controls here.

const TABS: Array[Dictionary] = [
	{"tab": "Biển", "icon": "boat", "groups": [
		{"icon": "boat", "title": "Lái thuyền", "rows": [
			["W S", "Tiến / lùi"], ["A D", "Bẻ lái"],
			["@lamp", "Dầu đèn = thời gian"], ["@anchor", "Ở bến không tốn dầu"]]},
		{"icon": "rod", "title": "Câu cá", "rows": [
			["E", "Câu ở đám bọt"], ["A D", "Theo cá"], ["W S", "Nâng / hạ lưỡi"],
			["Space", "Móc cá"], ["W", "Kéo lên"], ["S", "Nhả dây"], ["E", "Giật tất tay"]]},
		{"icon": "shrimp", "title": "Lưới", "rows": [
			["Q", "Thả lưới"], ["E", "Kéo lưới (ở phao)"]]},
		{"icon": "fish", "title": "Khoang", "rows": [
			["Tab", "Mở khoang"], ["R", "Xoay cá"], ["@trash", "Kéo vào để bỏ"]]},
		{"icon": "anchor", "title": "Bến", "rows": [
			["E", "Dỡ cá vào kho"], ["R", "Về nhà ngủ"], ["F", "Sửa thuyền"]]},
		{"icon": "phone", "title": "Điện thoại", "rows": [
			["J", "Mở điện thoại"], ["M", "Bản đồ"]]},
	]},
	{"tab": "Quán", "icon": "shop", "groups": [
		{"icon": "menu", "title": "Lên món", "rows": [
			["E", "Bảng thực đơn"], ["1-9", "Chọn ô / món"], ["Q", "Tự xếp"], ["Esc", "Quay lại"]]},
		{"icon": "cart", "title": "Cô Năm", "rows": [
			["E", "Mở tạp hoá"], ["@leaf", "Rau, bia luôn có"], ["@money", "Mua lô rẻ hơn"]]},
		{"icon": "meal", "title": "Phục vụ", "rows": [
			["W A S D", "Đi"], ["Shift", "Lướt"], ["E", "Lấy / đưa món"], ["E", "Dọn bàn bẩn"]]},
		{"icon": "grill", "title": "Nướng, bia", "rows": [
			["E", "Lò nướng"], ["Space", "Bấm đúng lúc"], ["E", "Rót bia"], ["Space", "Giữ để rót"]]},
		{"icon": "house", "title": "Hết ca", "rows": [
			["T", "Đóng sớm (2 lần)"], ["@hammer", "Sửa quán"], ["@boat", "Ra khơi"]]},
		{"icon": "people", "title": "Nhân viên", "rows": [
			["J", "Thuê người"], ["@guest", "Tự bưng, dọn bàn"]]},
		{"icon": "trophy", "title": "Thử thách", "rows": [
			["@check", "3 việc mỗi ca"], ["@money", "Xong: thưởng tiền"], ["@trophy", "Thành tựu: tab J"]]},
		{"icon": "star", "title": "Review", "rows": [
			["@people", "Khách đăng bài"], ["@growth", "Nhiều follower: đông khách"], ["@chart", "Xếp hạng tuần"]]},
	]},
	{"tab": "Điện thoại", "icon": "phone", "groups": [
		{"icon": "phone", "title": "Rin's Catch", "rows": [
			["J", "Mở / đóng"], ["A D", "Đổi tab"], ["M", "Bản đồ lớn"]]},
		{"icon": "chart", "title": "Các tab", "rows": [
			["@fish", "Kho, Dex"], ["@menu", "Món nấu được"], ["@chart", "Sổ sách"],
			["@upgrade", "Nâng cấp đồ"], ["@wrench", "Sửa thuyền"]]},
	]},
	{"tab": "Nhịp Sóng", "icon": "wave", "groups": [
		{"icon": "wave", "title": "Nhịp Sóng", "rows": [
			["C", "Làm chậm thời gian"], ["@moon", "Vài lần mỗi đêm"], ["@fish", "Cá dị biến: thêm lượt"]]},
	]},
	{"tab": "Mẹo", "icon": "sparkles", "groups": [
		{"icon": "sparkles", "title": "Mẹo", "rows": [
			["@sparkles", "Bọt nhiều = nhiều cá"], ["@boat", "Xa bờ = cá to"],
			["@lamp", "Đá ngầm: trong tầm đèn"], ["@hot", "Món HOT: giá x1.5"]]},
		{"icon": "settings", "title": "Phím chung", "rows": [
			["Esc", "Tạm dừng"], ["F11", "Toàn màn hình"], ["@save", "Tự lưu khi ra khơi"]]},
	]},
]
