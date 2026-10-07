class_name PhoneReports
extends RefCounted
## Text for each tab of Rin's phone app ("Rin's Catch" — Rin used to be a
## developer and wrote it). Pure functions of GameState + data resources, so
## the UI only displays them and tests can check them directly.

const ZONE_NAMES: Array[String] = ["Gần bờ", "Rạn đá", "Xa bờ", "Sương mù"]
const METHOD_NAMES: Array[String] = ["câu", "lưới"]
const GLITCH_CHARS: String = "#%@?!&$"


## Storage grouped by fish + freshness, with sell multiplier and nights left.
static func storage_report(fridge_loss: float) -> String:
	if GameState.storage.is_empty():
		return "KHO: trống\n\n> Câu thêm đêm nay để có món bán."
	var groups: Dictionary = {}  # "name|freshness" -> count
	for item: InventoryItem in GameState.storage:
		var key := "%s|%d" % [item.fish.display_name, roundi(item.freshness)]
		groups[key] = int(groups.get(key, 0)) + 1
	var lines: PackedStringArray = ["KHO (%d món)" % GameState.storage.size(), ""]
	for key: String in groups:
		var parts := key.split("|")
		var freshness := float(parts[1])
		var nights := ceili(freshness / fridge_loss) if fridge_loss > 0.0 else 99
		var spoil := "hỏng đêm nay" if nights <= 1 else "còn %d đêm" % (nights - 1)
		lines.append("%-14s x%d  tươi %3d  giá x%.1f  %s" % [parts[0], groups[key], roundi(freshness),
			KitchenLogic.freshness_multiplier(freshness), spoil])
	return "\n".join(lines)


## What each dish needs and how many portions the storage can make now.
static func menu_report(menu: DishCatalog, fish_names: Dictionary) -> String:
	var counts := KitchenLogic.count_by_fish(GameState.storage)
	var lines: PackedStringArray = ["MENU", ""]
	for dish in menu.dishes:
		var head := "%-22s %3dk" % [dish.display_name, dish.base_price]
		if dish.always_available:
			lines.append("%s  luôn có" % head)
		elif dish.is_market_dish():
			lines.append("%s  mua chợ %.0fk/phần" % [head, dish.market_cost])
		else:
			var portions := MenuPlan.max_portions(dish, GameState.storage)
			if portions > 0:
				lines.append("%s  nấu được %d phần" % [head, portions])
			else:
				var missing: PackedStringArray = []
				for fish_id in dish.ingredients:
					var short := dish.ingredients[fish_id] - int(counts.get(fish_id, 0))
					if short > 0:
						missing.append("%d %s" % [short, fish_names.get(fish_id, fish_id)])
				lines.append("%s  thiếu: %s" % [head, ", ".join(missing)])
	return "\n".join(lines)


## Fish encyclopedia. Unknown species show as ???; aberrant ones glitch.
static func dex_report(catalog: FishCatalog, glitch_seed: int) -> String:
	var known := 0
	var lines: PackedStringArray = []
	for fish in catalog.fish:
		var caught := int(GameState.caught_species.get(fish.id, 0))
		var zones: PackedStringArray = []
		for zone in fish.zones:
			zones.append("???" if zone == FishData.Zone.FOG and not Story.is_fog_open() else ZONE_NAMES[zone])
		if caught == 0:
			lines.append("[ ] %-16s vùng: %s" % ["???", ", ".join(zones)])
			continue
		known += 1
		var fish_name := glitch(fish.display_name, glitch_seed) if fish.is_aberrant else fish.display_name
		lines.append("[x] %-16s x%-3d %s · %s · %dk" % [fish_name, caught, ", ".join(zones),
			METHOD_NAMES[fish.catch_method], fish.base_price])
		if fish.catch_method == FishData.CatchMethod.ROD and GameState.best_size(fish) > 0.0:
			lines.append("    kỷ lục: %s" % fish.weight_text(GameState.best_size(fish)))
		if fish.is_aberrant:
			lines.append("    [WARN] species_id \"%s\" không có trong database" % fish.id)
	lines.insert(0, "DEX  %d/%d loài\n" % [known, catalog.fish.size()])
	return "\n".join(lines)


## Active fish orders from regulars (messages).
static func orders_report(catalog: FishCatalog) -> String:
	if GameState.orders.is_empty():
		return "TIN NHẮN: chưa có đơn nào\n\n> Khách quen sẽ nhắn đặt cá vào buổi sáng."
	var lines: PackedStringArray = ["ĐƠN ĐẶT CÁ (%d)" % GameState.orders.size(), ""]
	for order: Dictionary in GameState.orders:
		lines.append("[MSG] " + FishOrders.describe(order, catalog))
	lines.append("")
	lines.append("> Câu được con đủ ký, sáng ra tự giao và nhận tiền.")
	return "\n".join(lines)


static func boat_report(boat: BoatData, lamp_capacity: float, upgrades: Array[UpgradeData]) -> String:
	var lines: PackedStringArray = [
		"THUYỀN: %s" % boat.display_name,
		"",
		"Thân thuyền   %d%%%s" % [roundi(GameState.boat_hp), "  (HƯ!)" if BoatCondition.is_broken() else ""],
		"Sửa           %.1fk / %%  (sửa đầy: %dk)" % [boat.repair_cost_per_hp, BoatCondition.full_repair_cost(boat)],
		"Khoang        %dx%d ô" % [boat.hold_size.x, boat.hold_size.y],
		"Dầu đèn       %d (đổ đầy mỗi đêm)" % roundi(lamp_capacity),
		"Đi được       %s" % boat.range_label,
		"",
		"NÂNG CẤP",
	]
	for upgrade in upgrades:
		var level := GameState.get_upgrade_level(upgrade.id)
		lines.append("%-14s cấp %d/%d  %s" % [upgrade.display_name, level, upgrade.max_level(), upgrade.label_at(level)])
	return "\n".join(lines)


## Money and recent days, with a little ASCII bar chart of profit.
static func ledger_report(bar_width: int = 16) -> String:
	var lines: PackedStringArray = ["SỔ SÁCH", "", "Tiền hiện có: %dk" % GameState.money, ""]
	if GameState.day_history.is_empty():
		lines.append("Chưa có ngày nào. Mở quán để có số liệu.")
		return "\n".join(lines)
	var best := 1
	for record: Dictionary in GameState.day_history:
		best = maxi(best, _profit(record))
	for record: Dictionary in GameState.day_history.slice(-7):
		var profit := _profit(record)
		var bar := "#".repeat(clampi(roundi(float(maxi(profit, 0)) / best * bar_width), 0, bar_width))
		lines.append("Ngày %-3d |%-*s| %4dk  %d sao" % [int(record.get("day", 0)), bar_width, bar, profit,
			int(record.get("rating", 0))])
	return "\n".join(lines)


## Console lines at the bottom of the app. Story clues show up here.
static func log_lines(fridge_loss: float, weather: WeatherData = null) -> PackedStringArray:
	var lines: PackedStringArray = ["[INFO] sync kho... OK (%d món)" % GameState.storage.size()]
	if weather:
		lines.append("[INFO] forecast: %s" % weather.forecast)
	var spoiling := GameState.storage.filter(func(item: InventoryItem) -> bool: return item.freshness <= fridge_loss).size()
	if spoiling > 0:
		lines.append("[WARN] %d món sẽ hỏng qua đêm nay" % spoiling)
	if not GameState.orders.is_empty():
		lines.append("[MSG] %d đơn đặt cá đang chờ" % GameState.orders.size())
	if GameState.boat_hp < 30.0:
		lines.append("[WARN] thân thuyền %d%%, nên sửa" % roundi(GameState.boat_hp))
	if int(GameState.caught_species.get(Story.OMEN_FISH_ID, 0)) > 0:
		lines.append("[WARN] species_id \"%s\" không có trong database" % Story.OMEN_FISH_ID)
	if Story.is_fog_open():
		lines.append("[ERR] GPS: tọa độ NaN ở góc đông bắc")
	elif GameState.story_flags.has(Story.OMEN_DAY_FLAG):
		lines.append("[ERR] GPS: nhiễu tín hiệu ở góc đông bắc")
	return lines


## Replaces some characters with symbols, deterministically for a given seed.
static func glitch(text: String, glitch_seed: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = glitch_seed
	var chars := text.split("")
	for i in chars.size():
		if chars[i] != " " and rng.randf() < 0.3:
			chars[i] = GLITCH_CHARS[rng.randi() % GLITCH_CHARS.length()]
	return "".join(chars)


static func _profit(record: Dictionary) -> int:
	return int(record.get("earned", 0)) - int(record.get("market", 0))
