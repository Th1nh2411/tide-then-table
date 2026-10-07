extends Control
## Standalone test for places on the map (run with F6): raft price, rumor
## pools by story stage, story stage and lighthouse page counter. Visiting
## needs the sea scene, which autosaves, so it isn't done here.

@export var fish_catalog: FishCatalog

var _failures: int = 0


func _ready() -> void:
	GameState.reset()
	var mu := InventoryItem.new(_fish("ca_mu"), 1.0, 1.5)
	var tom := InventoryItem.new(_fish("tom"), 0.7, 1.0)
	_check("raft price", LobsterRaft.sale_value([mu, tom], 0.5) == roundi(90 * 1.5 * 0.5 + 25 * 0.7 * 0.5))

	_check("story stage 0", Story.stage() == 0)
	var hut := OldManHut.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var seen_omen := false
	for i in 200:
		seen_omen = seen_omen or hut.pick_rumor(0, rng) in hut.omen_rumors
	_check("no omen rumors before omen", not seen_omen)
	GameState.day = 5
	Story.trigger_omen()
	_check("story stage 1", Story.stage() == 1)
	for i in 200:
		seen_omen = seen_omen or hut.pick_rumor(1, rng) in hut.omen_rumors
	_check("omen rumors after omen", seen_omen)
	GameState.day = 6
	_check("story stage 2", Story.stage() == 2)
	hut.free()

	_check("lighthouse pages default 0", Lighthouse.pages_read() == 0)
	GameState.set_flag(Lighthouse.PAGE_FLAG, 2.0)  # JSON float
	_check("lighthouse pages from save", Lighthouse.pages_read() == 2)
	GameState.reset()
	print("Places: %s" % ("TẤT CẢ PASS" if _failures == 0 else "%d FAIL" % _failures))


func _check(label: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", label])


func _fish(id: String) -> FishData:
	for f in fish_catalog.fish:
		if f.id == id:
			return f
	return null
