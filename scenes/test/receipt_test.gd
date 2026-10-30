extends Node
## Standalone test (F6) for the HUD pieces: the shift receipt's rows
## (ShiftReceiptRows, pure), the receipt printing + stamp (ShiftReceipt3D),
## the speech strip's speaker parsing (SpeechStrip) and the meter (MeterBar).

var _failures: int = 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_rows()
	await _test_receipt()
	_test_strip()
	var bar := MeterBar.new()
	bar.set_value(1.7)
	_check("meter clamps to 0..1", is_equal_approx(bar.value, 1.0))
	bar.free()
	print("receipt_test: ALL PASS" if _failures == 0 else "receipt_test: %d FAIL" % _failures)
	get_tree().quit()


func _test_rows() -> void:
	var figures := {"day": 3, "served": 5, "lost": 1, "earned": 200, "market": 30, "wages": 20, "stars": 4}
	var results := {"challenges": [
		{"icon": "fire", "text": "Nướng 3 món", "progress": 3, "target": 3, "done": true, "reward": 40},
		{"icon": "beer", "text": "Bán 2 tháp bia", "progress": 1, "target": 2, "done": false, "reward": 0}],
		"achievements": [{"id": "first_guest", "title": "Khách đầu tiên", "icon": "guest", "reward": 50}],
		"social": {"followers_before": 10, "followers_after": 16, "reward": 0},
		"rank": {"rank_before": 4, "rank_after": 3, "reward": 0}}
	var rows := ShiftReceiptRows.build(figures, results)
	var kinds: Array[String] = []
	for row in rows:
		kinds.append(str(row["kind"]))
	_check("receipt starts with the shop heading", kinds[0] == "head" and str(rows[0]["value_text"]) == "#3")
	_check("guests served / left share a line", kinds.has("pair") and str((rows[2]["items"] as Array)[0]["value_text"]) == "5")
	_check("challenges print as stickers", kinds.has("goals"))
	var total: Dictionary = rows[kinds.find("total")]
	_check("total = takings - market - wages + rewards", str(total["value_text"]) == "+%dk" % (200 - 30 - 20 + 40 + 50))
	var last: Dictionary = rows[rows.size() - 1]
	_check("followers + rank on the last line", str(last["kind"]) == "pair"
		and str((last["items"] as Array)[0]["value_text"]) == "+6" and str((last["items"] as Array)[1]["value_text"]) == "#3")
	var history: Array = []
	for day in range(1, 10):
		history.append({"day": day, "earned": day * 10})
	var chart := ShiftReceiptRows.chart(history)
	_check("chart keeps the last 7 days", chart.size() == 7 and is_equal_approx(chart[6], 90.0)
		and ShiftReceiptRows.chart_days(history)[0] == "3")


func _test_receipt() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var receipt := ShiftReceipt3D.new()
	layer.add_child(receipt)
	var rows := ShiftReceiptRows.build({"day": 1, "served": 2, "earned": 80}, {})
	var values: Array[float] = [80.0]
	var days: Array[String] = ["1"]
	receipt.open("HẾT CA • XÓM ĐÈN\nPhục vụ: 2", rows, values, days, 3)
	_check("receipt keeps the summary text", receipt.summary_text.text.begins_with("HẾT CA"))
	_check("receipt prints line by line", receipt.visible and receipt.printing)
	await get_tree().create_timer(0.5).timeout
	receipt.finish_now()
	await get_tree().process_frame
	_check("printing ends with the star stamp", not receipt.printing and receipt._stamp.visible and receipt._stamp.stars == 3)
	receipt.close()
	_check("close hides it", not receipt.visible)


func _test_strip() -> void:
	var strip := SpeechStrip.new()
	strip.default_speaker = "Rin"
	add_child(strip)
	strip.say("NEO: Dầu đèn còn 25%.", 1.0)
	_check("NEO line: hologram, no name", strip._screen.visible and not strip._speaker.visible
		and strip._text.text == "Dầu đèn còn 25%.")
	strip.say("Bảo: Hết rau rồi!", 1.0)
	_check("named line: speaker in red ink", strip._speaker.text == "Bảo" and not strip._screen.visible)
	strip.say("Sóng to quá...", 1.0)
	_check("plain line: default speaker", strip._speaker.text == "Rin")
	strip.say("[WARN] khoang 90%", 1.0)
	_check("[WARN] is NEO's, in red", strip._screen.visible and strip._neo.alarm)


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
