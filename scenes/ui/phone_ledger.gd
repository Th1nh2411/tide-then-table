class_name PhoneLedger
extends RefCounted
## Ledger screen of the phone: money, then the last 7 days' profit as a bar
## chart (best day highlighted) with the last day's profit and rating.


## Money, then the last 7 days' profit as a bar chart and the last rating.
static func fill(box: VBoxContainer) -> void:
	PhoneCards.header(box, "ledger", "Sổ sách")
	var money := PhoneCards.card(box, 4)
	money.add_child(UiIcons.make("money", 16, Color("de9e41")))
	money.add_child(PhoneCards.neo("%dk" % GameState.money, 14))
	if GameState.day_history.is_empty():
		return
	var values: Array[float] = []
	var labels: Array[String] = []
	var best := 0
	var days := GameState.day_history.slice(-7)
	for i in days.size():
		var record: Dictionary = days[i]
		var profit := int(record.get("earned", 0)) - int(record.get("market", 0))
		values.append(float(maxi(profit, 0)))
		labels.append("N%d" % int(record.get("day", 0)))
		if values[i] > values[best]:
			best = i
	var chart_row := PhoneCards.card(box)
	var chart := MiniChart.new()
	chart.custom_minimum_size = Vector2(220, 64)
	chart.bar_color = Color("4f8fba")
	chart.label_color = Color(PhoneCards.INK, 0.7)
	chart.highlight = best
	chart_row.add_child(chart)
	chart.set_values(values, labels)
	var last: Dictionary = days[-1]
	var side := VBoxContainer.new()
	chart_row.add_child(side)
	side.add_child(PhoneCards.coin("%dk" % int(values[-1]), PhoneCards.GREEN))
	side.add_child(PhoneCards.icon_text("star", str(int(last.get("rating", 0))), Color("de9e41")))
