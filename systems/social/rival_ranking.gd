class_name RivalRanking
extends RefCounted
## Weekly revenue ranking of Rin's restaurant against the rival eateries
## (RivalCatalog): each rival's day revenue is a fixed curve (RivalData),
## Rin's is `earned` from GameState.day_history. The board sums the last
## `week_days` days (day 1 at the earliest). The first time Rin's week beats a
## rival: story flag "rival_beat_<id>", its reward, a NEO line (caller).
## Pure logic, no nodes.

const CATALOG: RivalCatalog = preload("res://data/social/rival_catalog.tres")
const PLAYER_ID := "player"
const PLAYER_NAME := "Quán Rin"
## Do bien hieu (sign red): the player's bar.
const PLAYER_COLOR := Color("e0302b")
const FLAG_PREFIX := "rival_beat_"


## Rin's earned per day over the window ending at `day` (oldest first).
static func player_daily(day: int, history: Array, days: int) -> Array[int]:
	var values: Array[int] = []
	for d in range(day - days + 1, day + 1):
		var total := 0
		for record: Variant in history:
			if record is Dictionary and int(record.get("day", 0)) == d:
				total += int(record.get("earned", 0))
		values.append(total if d >= 1 else 0)
	return values


## Board entries, best week first: {"id", "name", "total", "player": bool,
## "color": Color, "daily": [k per day, oldest first]}. Ties: rival first.
static func week_board(day: int, history: Array, catalog: RivalCatalog = CATALOG) -> Array[Dictionary]:
	var board: Array[Dictionary] = []
	var mine := player_daily(day, history, catalog.week_days)
	board.append({"id": PLAYER_ID, "name": PLAYER_NAME, "total": _sum(mine), "player": true,
		"color": PLAYER_COLOR, "daily": mine})
	for rival in catalog.rivals:
		var daily: Array[int] = []
		for d in range(day - catalog.week_days + 1, day + 1):
			daily.append(rival.revenue(d))
		board.append({"id": rival.id, "name": rival.display_name, "total": _sum(daily), "player": false,
			"color": rival.color, "daily": daily})
	board.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["total"]) != int(b["total"]):
			return int(a["total"]) > int(b["total"])
		return not bool(a["player"]) and bool(b["player"]))
	return board


## 1-based place of Rin's restaurant on the board.
static func player_rank(board: Array[Dictionary]) -> int:
	for i in board.size():
		if bool(board[i]["player"]):
			return i + 1
	return board.size()


static func is_beaten(rival_id: String) -> bool:
	return GameState.has_flag(FLAG_PREFIX + rival_id)


## Rivals whose week is below Rin's for the first time: sets their flags and
## pays their rewards. Board order.
static func check_beaten(board: Array[Dictionary], catalog: RivalCatalog = CATALOG) -> Array[RivalData]:
	var mine := 0
	for entry in board:
		if bool(entry["player"]):
			mine = int(entry["total"])
	var fresh: Array[RivalData] = []
	for entry in board:
		var rival := catalog.find(str(entry["id"]))
		if rival == null or is_beaten(rival.id) or mine <= int(entry["total"]):
			continue
		GameState.set_flag(FLAG_PREFIX + rival.id)
		GameState.add_money(rival.beat_reward_k)
		fresh.append(rival)
	return fresh


## Closing: rank before (history without today) and after, rivals beaten.
## Returns {"rank_before", "rank_after", "beaten": [ids], "reward", "board"}
## (= host.shift_results["rank"]).
static func close_day(day: int, history: Array, catalog: RivalCatalog = CATALOG) -> Dictionary:
	var without_today := history.filter(func(r: Variant) -> bool: return not (r is Dictionary and int(r.get("day", 0)) == day))
	var before := week_board(day, without_today, catalog)
	var after := week_board(day, history, catalog)
	var beaten: Array[String] = []
	var reward := 0
	for rival in check_beaten(after, catalog):
		beaten.append(rival.id)
		reward += rival.beat_reward_k
	return {"rank_before": player_rank(before), "rank_after": player_rank(after), "beaten": beaten,
		"reward": reward, "board": after}


static func _sum(values: Array[int]) -> int:
	var total := 0
	for value in values:
		total += value
	return total
