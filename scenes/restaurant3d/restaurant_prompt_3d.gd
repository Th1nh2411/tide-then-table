class_name RestaurantPrompt3D
extends RefCounted
## Decides which "[E] ..." hint to show for where Rin stands. Pure: reads the host, returns data.

const L = preload("res://scenes/restaurant3d/restaurant_layout_3d.gd")

## {} when nothing to show, else {"at": world position, "words": text}.
static func describe(host: Node3D) -> Dictionary:
	var pos: Vector3 = host.player.position
	var at: Vector3 = pos + Vector3(0, 2.3, 0)
	var words: String = ""
	var carrying: int = host.carrying_table
	if not host.shift_running:
		if pos.distance_to(L.COUNTER_POSITION) < 2.1:
			at = L.COUNTER_POSITION + Vector3(0, 2.0, 0)
			words = "[E] Mua rau / bia · Cô Năm"
		elif pos.distance_to(L.BOARD_POSITION) < 2.2 and not host.shift_over:
			at = L.BOARD_POSITION + Vector3(0, 2.0, 0)
			words = "[E] Lên thực đơn"
	elif carrying >= 0:
		at = L.TABLES[carrying] + Vector3(0, 1.9, 0)
		words = "Bàn %d · mang món tới đây" % (carrying + 1)
		if pos.distance_to(L.TABLES[carrying]) < 2.0:
			words = "[E] Phục vụ bàn %d" % (carrying + 1)
	elif pos.distance_to(L.COUNTER_POSITION) < 2.1:
		at = L.COUNTER_POSITION + Vector3(0, 2.0, 0)
		words = "[E] Mua rau / bia · Cô Năm"
	else:
		var dirty: Array[bool] = host.dirty_tables
		var cleaning: bool = false
		for i: int in range(dirty.size()):
			if dirty[i] and pos.distance_to(L.TABLES[i]) < 2.0:
				at = L.TABLES[i] + Vector3(0, 1.5, 0)
				words = "[E] Dọn bàn %d" % (i + 1)
				cleaning = true
				break
		if not cleaning:
			if pos.distance_to(L.PASS_POSITION) < 1.35:
				at = L.PASS_POSITION + Vector3(0, 1.5, 0)
				words = "[E] Nhận món Bảo đã nấu"
			elif pos.distance_to(L.BEER_POSITION) < 1.7:
				at = L.BEER_POSITION + Vector3(0, 1.9, 0)
				words = "[E] Rót bia cho khách"
			elif pos.distance_to(L.GRILL_POSITION) < 2.4:
				at = L.GRILL_POSITION + Vector3(0, 1.9, 0)
				words = "[E] Nướng món đang chờ"
	if words.is_empty():
		return {}
	return {"at": at, "words": words}
