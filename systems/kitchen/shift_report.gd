class_name ShiftReport
extends RefCounted
## The end-of-shift summary text, short on purpose (the details are in the
## phone's ledger): reason + stars, money in / out / profit, tables served /
## left, a few notes, tomorrow's hint, then fish order news. Pure logic.


## `numbers`: reason, stars, earned, market, wages, served, left, variety,
## leftover (portions back to storage).
static func text(numbers: Dictionary, order_lines: PackedStringArray) -> String:
	var earned: int = numbers["earned"]
	var spent: int = int(numbers["market"]) + int(numbers["wages"])
	var stars: int = numbers["stars"]
	var lines: PackedStringArray = [
		"%s  ·  %d/5 sao" % [numbers["reason"], stars],
		"Thu %dk  ·  Chi %dk  ·  Lãi %dk" % [earned, spent, earned - spent],
		"Phục vụ %d bàn  ·  Bỏ đi %d" % [numbers["served"], numbers["left"]],
	]
	var notes: PackedStringArray = []
	var variety: float = numbers["variety"]
	if variety < 1.0:
		notes.append("menu đơn điệu x%.1f" % variety)
	if int(numbers["leftover"]) > 0:
		notes.append("%d phần hải sản về kho" % int(numbers["leftover"]))
	if not notes.is_empty():
		lines.append(" · ".join(notes))
	if not rating_hint(stars).is_empty():
		lines.append(rating_hint(stars))
	lines.append_array(order_lines)
	return "\n".join(lines)


static func rating_hint(stars: int) -> String:
	if stars >= 4:
		return "Mai đông khách hơn!"
	if stars <= 2:
		return "Mai vắng khách hơn..."
	return ""
