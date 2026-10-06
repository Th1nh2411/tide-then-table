extends Control
## Standalone test for the hold (run with F6).
## 1. Runs GridInventory logic checks and prints PASS/FAIL.
## 2. Opens an interactive hold: Space adds a random fish (overflow mode when
##    full), Tab opens/closes the hold.

@export var catalog: FishCatalog
@export var demo_hold_size: Vector2i = Vector2i(4, 3)

var _failures: int = 0
var _log: PackedStringArray = []
var _demo_hold: GridInventory
var _rng := RandomNumberGenerator.new()

@onready var _hold_ui: HoldUI = $HoldUI
@onready var _result_label: Label = %ResultLabel


func _ready() -> void:
	_rng.randomize()
	_run_logic_tests()
	_demo_hold = GridInventory.new(demo_hold_size)
	_hold_ui.setup(_demo_hold)
	_hold_ui.open_browse()
	_log.append("Space: thêm cá ngẫu nhiên · Tab: mở/đóng khoang")
	_result_label.text = "\n".join(_log)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cast"):
		var item := InventoryItem.new(catalog.fish[_rng.randi() % catalog.fish.size()], 1.0)
		if not _demo_hold.auto_place(item):
			_hold_ui.open_overflow(item)
	elif event.is_action_pressed("open_hold") and not _hold_ui.visible:
		_hold_ui.open_browse()


func _run_logic_tests() -> void:
	var oc := _fish("oc_huong")      # 1x1
	var cua := _fish("cua")          # 2x2
	var ca_thu := _fish("ca_thu")    # 3 wide, 1 tall

	var grid := GridInventory.new(Vector2i(4, 3))
	var a := InventoryItem.new(oc)
	var b := InventoryItem.new(cua)
	_check("place fits", grid.place(a, Vector2i(0, 0)))
	_check("overlap rejected", not grid.place(b, Vector2i(0, 0)))
	_check("place next to it", grid.place(b, Vector2i(1, 0)))
	_check("cells registered", grid.get_item_at(Vector2i(2, 1)) == b)

	var c := InventoryItem.new(ca_thu)
	_check("out of bounds right", not grid.can_place(c, Vector2i(2, 2)))
	_check("out of bounds negative", not grid.can_place(c, Vector2i(-1, 2)))
	_check("fits on bottom row", grid.place(c, Vector2i(1, 2)))

	# Rotation: 3x1 becomes 1x3.
	var d := InventoryItem.new(ca_thu)
	_check("rotated size", d.get_size(true) == Vector2i(1, 3))
	_check("rotated fits in last column", GridInventory.new(Vector2i(4, 3)).can_place(d, Vector2i(3, 0), true))
	_check("rotated too tall", not GridInventory.new(Vector2i(4, 2)).can_place(d, Vector2i(0, 0), true))

	# Moving an item so it overlaps its own old cells is allowed.
	_check("move over own cells", grid.place(b, Vector2i(2, 0)))
	_check("old cell freed after move", grid.get_item_at(Vector2i(1, 0)) == null)
	_check("can't move onto another item", not grid.place(a, Vector2i(3, 0)))

	# Remove frees cells.
	grid.remove(c)
	_check("remove frees cells", grid.get_item_at(Vector2i(1, 2)) == null and not grid.items.has(c))

	# Free spot search + auto rotate.
	var narrow := GridInventory.new(Vector2i(1, 3))
	var e := InventoryItem.new(ca_thu)
	_check("no spot unrotated", narrow.find_free_spot(e, false) == GridInventory.NO_SPOT)
	_check("auto_place rotates to fit", narrow.auto_place(e) and e.rotated)
	_check("full grid rejects", not narrow.auto_place(InventoryItem.new(oc)))

	_log.insert(0, "GridInventory: %s" % ("TẤT CẢ PASS" if _failures == 0 else "%d FAIL" % _failures))


func _check(label: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	var line := "%s  %s" % ["PASS" if ok else "FAIL", label]
	print(line)
	_log.append(line)


func _fish(id: String) -> FishData:
	for f in catalog.fish:
		if f.id == id:
			return f
	push_error("Unknown fish id %s" % id)
	return null
