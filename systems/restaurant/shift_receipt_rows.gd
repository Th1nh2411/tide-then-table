class_name ShiftReceiptRows
extends RefCounted
## Pure: the lines of the end-of-shift receipt (ShiftReceipt3D) from the
## shift's figures and RestaurantGoals3D / RestaurantSocial3D results.
## Rows: {"kind": "head" | "line" | "pair" | "goals" | "rule" | "total"}.
## A line / item: {"icon": UiIcons id, "goal_icon" / "badge": GoalIcons ids
## (challenge / achievement art), "value_text", "red", "dim", "done", "tip"
## (tooltip words), counting ones "count", "value", "format"}. "pair" and
## "goals" hold "items". Few words on paper: the tooltips carry them.

const GOLD := Color("de9e41")
const RED := Color("cf573c")
const SEA := Color("4f8fba")
const GREEN := Color("468232")
const INK := Color("394a50")


## `figures`: {"day", "served", "lost", "earned", "market", "wages", "stars"}.
static func build(figures: Dictionary, results: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var day: int = int(figures.get("day", 1))
	rows.append({"kind": "head", "icon": "shop", "color": RED, "text": "XÓM ĐÈN",
		"value_text": "#%d" % day, "tip": "Hoá đơn ngày %d" % day})
	rows.append({"kind": "rule"})
	var lost: int = int(figures.get("lost", 0))
	var left := _line("leave", RED, str(lost), "Khách bỏ về")
	left["red"] = lost > 0
	left["dim"] = lost == 0
	rows.append(_pair([_line("guest", SEA, str(int(figures.get("served", 0))), "Khách đã phục vụ"), left]))
	var earned: int = int(figures.get("earned", 0))
	var take := _line("money", GOLD, "+%dk" % earned, "Thu")
	take.merge({"count": true, "value": earned, "format": "+%dk"})
	rows.append(take)
	var market: int = int(figures.get("market", 0))
	var wages: int = int(figures.get("wages", 0))
	var spends: Array[Dictionary] = []
	if market > 0:
		spends.append(_spend("cart", market, "Chợ Cô Năm"))
	if wages > 0:
		spends.append(_spend("wallet", wages, "Lương nhân viên"))
	if not spends.is_empty():
		rows.append(_pair(spends))
	var bonus := 0
	var goals: Array[Dictionary] = []
	for entry: Dictionary in results.get("challenges", []):
		var done: bool = bool(entry.get("done", false))
		var reward: int = int(entry.get("reward", 0))
		bonus += reward
		goals.append({"goal_icon": str(entry.get("icon", "star")), "done": done, "dim": not done,
			"value_text": ("+%dk" % reward) if done else "%d/%d" % [int(entry.get("progress", 0)), int(entry.get("target", 0))],
			"tip": "%s  +%dk" % [str(entry.get("text", "")), int(entry.get("reward", 0))]})
	if not goals.is_empty():
		rows.append({"kind": "goals", "items": goals})
	for entry: Dictionary in results.get("achievements", []):
		var reward: int = int(entry.get("reward", 0))
		bonus += reward
		rows.append({"kind": "line", "badge": str(entry.get("id", "")), "goal_icon": str(entry.get("icon", "trophy")),
			"value_text": "+%dk" % reward, "tip": str(entry.get("title", ""))})
	var social: Dictionary = results.get("social", {})
	var rank: Dictionary = results.get("rank", {})
	bonus += int(social.get("reward", 0)) + int(rank.get("reward", 0))
	rows.append({"kind": "rule"})
	var net := earned - market - wages + bonus
	var total := _line("money", GOLD, "%+dk" % net, "Lãi hôm nay (gồm thưởng)")
	total["kind"] = "total"
	total["red"] = net < 0
	rows.append(total)
	var reach: Array[Dictionary] = []
	if not social.is_empty():
		var gained: int = int(social.get("followers_after", 0)) - int(social.get("followers_before", 0))
		reach.append(_line("follower", SEA, "%+d" % gained, "Người theo dõi Xóm Đèn Review"))
	if not rank.is_empty():
		var up := int(rank.get("rank_after", 0)) < int(rank.get("rank_before", 0))
		reach.append(_line("upgrade" if up else "podium", GREEN if up else GOLD, "#%d" % int(rank.get("rank_after", 0)), "Hạng tuần này"))
	if not reach.is_empty():
		rows.append(_pair(reach))
	return rows


## Last `days` days' earnings from GameState.day_history-style records.
static func chart(history: Array, days: int = 7) -> Array[float]:
	var values: Array[float] = []
	for record in history.slice(maxi(history.size() - days, 0)):
		values.append(float((record as Dictionary).get("earned", 0)))
	return values


static func chart_days(history: Array, days: int = 7) -> Array[String]:
	var labels: Array[String] = []
	for record in history.slice(maxi(history.size() - days, 0)):
		labels.append(str(int((record as Dictionary).get("day", 0))))
	return labels


static func _line(icon: String, color: Color, value_text: String, tip: String) -> Dictionary:
	return {"kind": "line", "icon": icon, "color": color, "value_text": value_text, "tip": tip}


static func _pair(items: Array[Dictionary]) -> Dictionary:
	return {"kind": "pair", "items": items} if items.size() > 1 else items[0]


static func _spend(icon: String, amount: int, tip: String) -> Dictionary:
	var row := _line(icon, INK, "-%dk" % amount, tip)
	row["red"] = true
	return row
