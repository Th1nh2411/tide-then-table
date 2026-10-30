class_name SeaPlaces3D
extends RefCounted
## Places (shrine, lighthouse, Ông Tám's hut, lobster raft) and night events
## of the 3D sea. Host (SeaScene3D) fields written: night_events, poi_busy,
## shrine_blessed, blessed_damage_scale.

static func build_night_events(sea: SeaScene3D) -> void:
	if GameState.day <= 1:
		return
	var positions: Array[Vector3] = []
	for px: Vector2 in [Vector2(700, 950), Vector2(1250, 870), Vector2(450, 880), Vector2(1100, 820)]:
		positions.append(SeaLayout3D.to_world(px))
	var kinds := NightEvents.pick_kinds(sea.rng, sea.rng.randi_range(1, 2), [1.0, 1.2, 1.0, 1.0])
	for i in range(kinds.size()):
		var kind: int = kinds[i]
		var pos: Vector3 = positions[kind]
		var node := Node3D.new()
		sea.add_child(node)
		node.position = pos
		match kind:
			NightEvents.Kind.STRANDED:
				SeaWorldBuilder3D.batch_model(node, "ghe_cheo", Vector3(0, 0.06, 0), Vector3(0.72, 0.65, 0.65))
			NightEvents.Kind.BOTTLE:
				var bottle := SeaWorldBuilder3D.batch_model(node, "bottle", Vector3(0, 0.17, 0))
				bottle.rotation.z = PI / 2.0
			NightEvents.Kind.JELLYFISH:
				for n in range(7):
					SeaWorldBuilder3D.batch_model(node, "jellyfish", Vector3(float(n % 3) * 0.65 - 0.65, -0.32, float(n / 3) * 0.58 - 0.5), Vector3.ONE * 0.65)
			NightEvents.Kind.DOLPHINS:
				for n in range(3):
					SeaWorldBuilder3D.batch_model(node, "dolphin", Vector3(float(n) * 0.7 - 0.7, 0.08, 0), Vector3.ONE * 0.45)
		sea.night_events.append({"kind": kind, "pos": pos, "node": node, "done": false,
			"time": 0.0, "towing": false, "owner": "Chú Sáu"})

## Id of the place or event the boat can visit with E ("" = none).
static func nearest(sea: SeaScene3D) -> String:
	var boat := sea.boat
	if boat.velocity.length() > 2.0 or sea.poi_busy:
		return ""
	for entry in [
		["shrine", sea.SHRINE_POS, 4.0], ["lighthouse", sea.LIGHTHOUSE_POS, 4.0],
		["hut", sea.HUT_POS, 4.0], ["raft", sea.RAFT_POS, 5.3],
	]:
		if boat.position.distance_to(entry[1]) < float(entry[2]):
			return entry[0]
	for i in range(sea.night_events.size()):
		var event := sea.night_events[i]
		if not event["done"] and int(event["kind"]) in [NightEvents.Kind.STRANDED, NightEvents.Kind.BOTTLE] \
				and boat.position.distance_to(event["pos"]) < 3.4:
			return "event_%d" % i
	return ""

static func is_towing(sea: SeaScene3D) -> bool:
	for event in sea.night_events:
		if event["towing"]:
			return true
	return false

static func update_night_events(sea: SeaScene3D, delta: float) -> void:
	var boat := sea.boat
	for event in sea.night_events:
		var kind: int = event["kind"]
		if not is_instance_valid(event["node"]):
			continue
		var node: Node3D = event["node"]
		if event["towing"]:
			var behind := boat.position + Vector3.BACK.rotated(Vector3.UP, boat.rotation.y) * 4.0
			node.position = node.position.lerp(behind, minf(delta * 2.0, 1.0))
		elif kind == NightEvents.Kind.JELLYFISH:
			node.position += Vector3(0.12, 0, -0.06) * delta
			if boat.position.distance_to(node.position) < 2.5:
				event["time"] = float(event["time"]) - delta
				if float(event["time"]) <= 0.0:
					event["time"] = 1.5
					BoatCondition.damage(3.0 * sea.blessed_damage_scale)
					sea._say("Sứa quấn chân vịt rồi! Phải thoát khỏi đàn sứa.", 1.5)
		elif kind == NightEvents.Kind.DOLPHINS:
			if not event["done"] and boat.position.distance_to(node.position) < 8.0:
				event["done"] = true
				sea._say("Cá heo kìa! Đi theo tụi nó thử coi.", 2.5)
			if event["done"]:
				node.position = node.position.move_toward(dolphin_target(sea), delta * 3.0)

static func dolphin_target(sea: SeaScene3D) -> Vector3:
	var i := sea._nearest_school_index()
	return sea.shoals[i].pos if i >= 0 else sea.START

static func visit(sea: SeaScene3D, id: String) -> void:
	if id.begins_with("event_"):
		await visit_night_event(sea, int(id.substr(6)))
		sea.poi_busy = false
		sea._update_hud()
		return
	var dialog := sea.poi_dialog
	match id:
		"shrine":
			var shrine := WhaleShrine.new()
			var line := shrine.keeper_lines[clampi(Story.stage(), 0, shrine.keeper_lines.size() - 1)]
			shrine.free()
			if sea.shrine_blessed:
				await dialog.ask("Miếu Cá Ông", line + "\n\nNhang còn cháy. Đêm nay Ông phù hộ.", PackedStringArray(["Đi tiếp"]))
			else:
				var choice := await dialog.ask("Miếu Cá Ông", line, PackedStringArray([
					"Thắp nhang (10k): đêm nay thuyền đỡ hư hại khi va đá", "Đi tiếp"]))
				if choice == 0:
					if GameState.spend_money(10):
						sea.shrine_blessed = true
						sea.blessed_damage_scale = 0.5
						sea._say("Thắp nhang xong. Đêm nay va đá chắc cũng đỡ.", 2.0)
					else:
						sea._say("Không đủ tiền mua nhang...", 2.0)
		"lighthouse":
			var tower := Lighthouse.new()
			var read := Lighthouse.pages_read()
			var available := mini(tower.pages_by_stage[clampi(Story.stage(), 0, tower.pages_by_stage.size() - 1)], tower.pages.size())
			var body := "Trang cuối dừng giữa câu. Người gác đèn chưa bao giờ quay về."
			if read < available:
				body = "Nhật ký người gác đèn, trang %d:\n\n%s" % [read + 1, tower.pages[read]]
				GameState.set_flag(Lighthouse.PAGE_FLAG, read + 1)
			elif available < tower.pages.size():
				body = "Đã đọc hết các trang còn đọc được. Mấy trang sau bị nước biển làm nhòe, để hôm khác thử lại."
			tower.free()
			await dialog.ask("Hải đăng Đá Canh Đêm", body, PackedStringArray(["Đi tiếp"]))
		"hut":
			var patch_label := "Nhờ vá thuyền (+25 bền, 40k)" if BoatCondition.is_damaged() else "Nhờ vá thuyền (thuyền còn lành)"
			var choice := await dialog.ask("Chòi ông Tám — Gò Vỏ Ốc", "Ông Tám ngồi vá lưới dưới ngọn đèn dầu.\n\"Ra trễ vậy con?\"",
				PackedStringArray([patch_label, "Hỏi chuyện", "Đi tiếp"]), "ong_tam")
			if choice == 0:
				if not BoatCondition.is_damaged():
					sea._say("Thuyền còn lành mà, khỏi vá.", 2.0)
				elif GameState.spend_money(40):
					GameState.boat_hp = minf(100.0, GameState.boat_hp + 25.0)
					sea._say("Ông Tám: Xong rồi đó con. (+25 bền, -40k)", 2.0)
				else:
					sea._say("Không đủ tiền nhờ ông Tám vá...", 2.0)
			elif choice == 1:
				var hut := OldManHut.new()
				var rumor := hut.pick_rumor(Story.stage(), sea.rng)
				hut.free()
				await dialog.ask("Chòi ông Tám — Gò Vỏ Ốc", "Ông Tám: " + rumor, PackedStringArray(["Đi tiếp"]), "ong_tam")
		"raft":
			var hold := sea.hold
			var items := hold.items.duplicate()
			if items.is_empty():
				await dialog.ask("Bè tôm hùm anh Út", "Anh Út: \"Khoang trống trơn mà ghé chi? Đi câu đi em.\"", PackedStringArray(["Đi tiếp"]))
			else:
				var value := LobsterRaft.sale_value(items, 0.5)
				var choice := await dialog.ask("Bè tôm hùm anh Út", "Anh Út: \"Khoang đầy hả? Để anh mua đỡ, giá chợ đêm thôi nghen.\"\n(%d con trong khoang)" % items.size(),
					PackedStringArray(["Chọn con để bán", "Bán hết khoang: %dk" % value, "Thôi, để đem về quán"]))
				if choice == 0 and sea.hold_ui:
					sea.hold_ui.open_sell("bè tôm hùm anh Út (giá chợ đêm)", func(item: InventoryItem) -> int:
						return LobsterRaft.sale_value([item], 0.5))
					await sea.hold_ui.closed
				elif choice == 1:
					for item in items:
						hold.remove(item)
					GameState.add_money(value)
					sea._say("Bán cho anh Út %d con, được %dk." % [items.size(), value], 2.0)
	sea.poi_busy = false
	sea._update_hud()

static func visit_night_event(sea: SeaScene3D, index: int) -> void:
	if index < 0 or index >= sea.night_events.size():
		return
	var event := sea.night_events[index]
	match int(event["kind"]):
		NightEvents.Kind.STRANDED:
			var owner: String = event["owner"]
			var choice := await sea.poi_dialog.ask("Ghe %s chết máy" % owner,
				"%s: \"Máy chết rồi con ơi. Kéo giùm chú về bến, chú gửi 80k.\"" % owner,
				PackedStringArray(["Kéo về bến (thuyền chạy chậm lại)", "Thôi, con đang bận"]))
			if choice == 0:
				event["towing"] = true
				event["done"] = true
				sea._say("Kéo ghe %s về bến là có 80k." % owner, 2.5)
		NightEvents.Kind.BOTTLE:
			var bottle := MessageBottle.new()
			var read := MessageBottle.pages_read()
			if read < bottle.pages.size():
				GameState.set_flag(MessageBottle.READ_FLAG, read + 1)
				await sea.poi_dialog.ask("Chai thư", "Mẩu giấy ướt nhòe, nét chữ run run (%d/%d):\n\n%s" % [read + 1, bottle.pages.size(), bottle.pages[read]],
					PackedStringArray(["Cất vào túi"]))
			else:
				GameState.add_money(5)
				await sea.poi_dialog.ask("Chai thư", "Chai rỗng. Đem bán ve chai được 5k.", PackedStringArray(["Ừ"]))
			bottle.free()
			event["done"] = true
			(event["node"] as Node3D).queue_free()
