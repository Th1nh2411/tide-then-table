class_name HelpEntries
extends RefCounted
## Content of the "Hướng dẫn" screen (HelpPanel). Each tab has groups (icon +
## short title) of rows [keys, caption]: keys are space-separated key caps
## ("W S", "Shift"), or "@<icon id>" for a picture instead of a key. Captions
## stay 2-4 words. Add new controls here.

const TABS: Array[Dictionary] = [
	{"tab": "Biển", "icon": "boat", "groups": [
		{"icon": "boat", "title": "Lái thúng", "rows": [
			["W S", "Tiến / lùi"], ["A D", "Bẻ lái"],
			["@lamp", "Dầu đèn = thời gian"], ["@anchor", "Ở bến không tốn dầu"]]},
		{"icon": "rod", "title": "Câu cá", "rows": [
			["E", "Câu ở đám bọt"], ["A D", "Theo cá"], ["W S", "Nâng / hạ lưỡi"],
			["Space", "Móc cá"], ["W", "Kéo lên"], ["S", "Nhả dây"], ["E", "Giật tất tay"]]},
		{"icon": "fish", "title": "Khoang", "rows": [
			["Tab", "Mở khoang"], ["R", "Xoay cá"], ["@trash", "Kéo vào để bỏ"]]},
		{"icon": "anchor", "title": "Bến", "rows": [
			["E", "Dỡ cá"], ["R", "Về nhà ngủ"], ["F", "Vá thúng"]]},
	]},
	{"tab": "Quán", "icon": "shop", "groups": [
		{"icon": "meal", "title": "Phục vụ", "rows": [
			["W A S D", "Đi theo hướng nhìn"], ["Shift", "Chạy"], ["Space", "Lộn"], ["E", "Lấy, đưa món, dọn bàn"]]},
		{"icon": "cart", "title": "Bia, Cô Năm", "rows": [
			["E", "Lấy bia ở thùng"], ["E", "Nói chuyện Cô Năm"]]},
		{"icon": "house", "title": "Hết ca", "rows": [
			["T", "Đóng sớm (2 lần)"], ["E", "Về xóm (cuối phố)"]]},
	]},
	{"tab": "Mẹo", "icon": "sparkles", "groups": [
		{"icon": "sparkles", "title": "Mẹo", "rows": [
			["@sparkles", "Gần bọt khí cá cắn nhanh"], ["@boat", "Xa bờ = cá to"],
			["@lamp", "Đá ngầm: trong tầm đèn"], ["@rod", "Dây đỏ là sắp đứt"]]},
		{"icon": "settings", "title": "Phím chung", "rows": [
			["Chuột", "Nhìn quanh"], ["Alt", "Hiện con trỏ"],
			["Esc", "Tạm dừng"], ["N", "Sổ tay"],["F11", "Toàn màn hình"], ["@save", "Tự lưu khi ngủ dậy"]]},
	]},
]
