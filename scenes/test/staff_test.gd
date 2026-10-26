extends Control
## Standalone test for restaurant staff (run with F6): StaffRoster (job ads,
## hiring limit, Vy coming by herself, wages, tips) and the shipped catalog.

var _failures: int = 0


func _ready() -> void:
	var catalog: StaffCatalog = load("res://data/staff/staff_catalog.tres")
	_check("catalog: 3 ads, people for every tier", catalog.ad_costs.size() == 3
		and [1, 2, 3].all(func(t: int) -> bool: return catalog.staff.any(func(p: StaffData) -> bool:
			return p.tier == t and p.arrives_on_day == 0)))
	var better := func(tier: int) -> float:
		var people := catalog.staff.filter(func(p: StaffData) -> bool: return p.tier == tier and p.arrives_on_day == 0)
		var sum := 0.0
		for p: StaffData in people:
			sum += p.walk_speed
		return sum / people.size()
	_check("better ads bring faster people", better.call(3) > better.call(2) and better.call(2) > better.call(1))
	var data: Dictionary = {}
	var roster := StaffRoster.new(catalog, data)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_check("nobody yet", roster.hired().is_empty() and roster.candidates().is_empty())
	_check("Vy not before day 4", roster.arrivals(3).is_empty())
	var vy := roster.arrivals(4)
	_check("Vy comes on day 4, once", vy.size() == 1 and vy[0].id == "vy" and roster.arrivals(5).is_empty())
	_check("Vy walks slower than Rin", vy[0].walk_speed == 80.0 and vy[0].walk_speed < 95.0)
	_check("one ad a day", roster.can_post(3))
	var flyer := roster.post_ad(1, 3, rng)
	_check("flyer brings tier-1 people", flyer.size() == catalog.applicants_per_ad
		and flyer.all(func(p: StaffData) -> bool: return p.tier == 1))
	_check("then no more ads today", not roster.can_post(3) and roster.can_post(4))
	_check("candidates: Vy + flyer", roster.candidates().size() == 3)
	_check("hire Vy", roster.hire(vy[0]) and roster.hired().size() == 1 and roster.candidates().size() == 2)
	_check("hire a second", roster.hire(roster.candidates()[0]))
	_check("max 2 hired", not roster.can_hire() and not roster.hire(roster.candidates()[0]))
	var wages := 0
	for person in roster.hired():
		wages += person.wage
	_check("wages = sum of hired", roster.wages() == wages and roster.tip_bonus() >= vy[0].tip_bonus)
	roster.dismiss(vy[0])
	_check("dismissed is gone for good", roster.hired().size() == 1 and roster.arrivals(9).is_empty()
		and not roster.candidates().has(vy[0]))
	roster.post_ad(1, 4, rng)
	_check("a flyer never brings someone met before", roster.post_ad(1, 5, rng).size()
		<= catalog.staff.filter(func(p: StaffData) -> bool: return p.tier == 1).size() - 2)
	print("Staff: %s" % ("TẤT CẢ PASS" if _failures == 0 else "%d FAIL" % _failures))


func _check(label: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", label])
