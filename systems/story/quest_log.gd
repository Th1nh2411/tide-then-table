class_name QuestLog
extends RefCounted
## What the quest tracker shows (QuestTracker), from the saved state:
## the main quest by story stage (Story.stage) with its steps — the boat
## upgrades the ending needs, the fog opening, the whirlpool — and side
## quests (regulars' fish orders, FishOrders). Pure logic, no nodes.

const BOAT_UPGRADE_ID := "boat"


## {"title": String, "steps": [{"text": String, "done": bool}]}
static func main_quest() -> Dictionary:
	var boat := GameState.get_upgrade_level(BOAT_UPGRADE_ID)
	if GameState.story_flags.has(Story.ENDING_SEEN_FLAG):
		return {"title": "Bên kia sương mù", "steps": [_step("Còn tiếp...", false)]}
	match Story.stage():
		0:
			return {"title": "Quán Rin & Bảo", "steps": [
				_step("Bán ngày đầu tiên", not GameState.day_history.is_empty()),
				_step("Mua Ghe chèo", boat >= 1),
				_step("Mua Ghe máy", boat >= 2),
			]}
		1:
			var omen_day := int(GameState.story_flags.get(Story.OMEN_DAY_FLAG, GameState.day))
			return {"title": "Ánh sáng trong sương", "steps": [
				_step("Chờ sương mù mở (đêm %d)" % (omen_day + 1), false),
				_step("Có Ghe máy", boat >= 2),
			]}
	return {"title": "Vào sương mù", "steps": [
		_step("Có Ghe máy", boat >= 2),
		_step("Vào xoáy nước sáng (đông bắc)", false),
	]}


## One line per regular's fish order.
static func side_quests(catalog: FishCatalog) -> PackedStringArray:
	var lines: PackedStringArray = []
	for order: Dictionary in GameState.orders:
		lines.append(FishOrders.describe(order, catalog))
	return lines


static func _step(text: String, done: bool) -> Dictionary:
	return {"text": text, "done": done}
