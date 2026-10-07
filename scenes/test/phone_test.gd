extends Control
## Standalone test for the phone app (run with F6). Checks PhoneReports text
## for a prepared GameState, then leaves the phone open to browse (J / A / D).

@export var fish_catalog: FishCatalog
@export var menu: DishCatalog

var _failures: int = 0

@onready var _phone: PhoneApp = $PhoneApp


func _ready() -> void:
	GameState.reset()
	GameState.money = 420
	GameState.boat_hp = 20.0
	GameState.storage.append(_item("cua", 100.0))
	GameState.storage.append(_item("cua", 100.0))
	GameState.storage.append(_item("oc_huong", 30.0))
	GameState.record_catch(_fish("cua"), 2)
	GameState.add_day_record({"day": 1, "earned": 300, "market": 20, "rating": 4})
	GameState.add_day_record({"day": 2, "earned": 120, "market": 0, "rating": 2})

	var storage := PhoneReports.storage_report(35.0)
	_check("storage groups fish", storage.contains("Cua") and storage.contains("x2"))
	_check("storage warns spoiling", storage.contains("hỏng đêm nay"))
	var menu_text := PhoneReports.menu_report(menu, {"cua": "Cua", "oc_huong": "Ốc hương"})
	_check("menu: cua cookable", menu_text.contains("nấu được 2 phần"))
	_check("menu: missing ingredients", menu_text.contains("thiếu: 2 Ốc hương"))
	_check("menu: snack always", menu_text.contains("luôn có"))
	var dex := PhoneReports.dex_report(fish_catalog, 1)
	_check("dex counts known species", dex.contains("DEX  1/%d" % fish_catalog.fish.size()))
	_check("dex hides unknown", dex.contains("???"))
	GameState.record_catch(_fish("ca_thu_phat_sang"), 1)
	dex = PhoneReports.dex_report(fish_catalog, 1)
	_check("dex warns aberrant", dex.contains("[WARN] species_id"))
	_check("glitch is deterministic", PhoneReports.glitch("Cá thu", 3) == PhoneReports.glitch("Cá thu", 3))
	var ledger := PhoneReports.ledger_report()
	_check("ledger shows money + days", ledger.contains("420k") and ledger.contains("Ngày 1") and ledger.contains("280k"))
	var logs := "\n".join(PhoneReports.log_lines(35.0))
	_check("log: spoiling + hull + aberrant", logs.contains("sẽ hỏng") and logs.contains("thân thuyền 20%")
		and logs.contains("không có trong database"))

	_phone.open()
	_check("open pauses game", get_tree().paused and _phone.visible)
	for tab in PhoneApp.TAB_NAMES.size():
		_phone._show_tab(tab)
		_check("tab %d has content" % tab, _phone.get_node("%ContentLabel").text.length() > 10)
	_phone.close()
	_check("close unpauses", not get_tree().paused and not _phone.visible)
	print("PhoneReports: %s" % ("TẤT CẢ PASS" if _failures == 0 else "%d FAIL" % _failures))
	_phone.open()


func _check(label: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", label])


func _fish(id: String) -> FishData:
	for f in fish_catalog.fish:
		if f.id == id:
			return f
	return null


func _item(id: String, freshness: float) -> InventoryItem:
	var item := InventoryItem.new(_fish(id), 1.0)
	item.freshness = freshness
	return item
