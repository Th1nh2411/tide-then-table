class_name StaffRoster
extends RefCounted
## Who works at the restaurant and who is asking for the job. Works on a
## shared dictionary (GameState.staff, saved): "hired" / "candidates" / "seen"
## (staff ids) and "ad_day" (the day an ad was last posted: one a day).
## Posting the tier-N ad (StaffCatalog) brings up to `applicants_per_ad`
## people of that tier not met yet; some people come by themselves on their
## `arrives_on_day` (Vy). Dismissed staff are gone (met already).
## Pure logic, no nodes.

signal changed

var catalog: StaffCatalog
var _data: Dictionary


func _init(p_catalog: StaffCatalog, data: Dictionary) -> void:
	catalog = p_catalog
	_data = data
	for key: String in ["hired", "candidates", "seen"]:
		if not _data.get(key) is Array:
			_data[key] = []


func hired() -> Array[StaffData]:
	return _people("hired")


func candidates() -> Array[StaffData]:
	return _people("candidates")


func can_hire() -> bool:
	return _ids("hired").size() < catalog.max_hired


func hire(person: StaffData) -> bool:
	if not can_hire() or not _ids("candidates").has(person.id):
		return false
	_ids("candidates").erase(person.id)
	_ids("hired").append(person.id)
	changed.emit()
	return true


## Lets them go (they won't come back).
func dismiss(person: StaffData) -> void:
	_ids("hired").erase(person.id)
	changed.emit()


func can_post(day: int) -> bool:
	return int(_data.get("ad_day", 0)) != day


## Posts the ad of `tier` (cost paid by the caller). Returns the newcomers.
func post_ad(tier: int, day: int, rng: RandomNumberGenerator) -> Array[StaffData]:
	_data["ad_day"] = day
	var pool := catalog.staff.filter(func(p: StaffData) -> bool:
		return p.tier == tier and p.arrives_on_day == 0 and not _ids("seen").has(p.id))
	var result: Array[StaffData] = []
	while not pool.is_empty() and result.size() < catalog.applicants_per_ad:
		var person: StaffData = pool.pop_at(rng.randi() % pool.size())
		_meet(person)
		result.append(person)
	changed.emit()
	return result


## People who come by themselves today or earlier and haven't been met.
func arrivals(day: int) -> Array[StaffData]:
	var result: Array[StaffData] = []
	for person in catalog.staff:
		if person.arrives_on_day > 0 and person.arrives_on_day <= day and not _ids("seen").has(person.id):
			_meet(person)
			result.append(person)
	if not result.is_empty():
		changed.emit()
	return result


## Everyone hired, per shift.
func wages() -> int:
	var sum := 0
	for person in hired():
		sum += person.wage
	return sum


func tip_bonus() -> float:
	var sum := 0.0
	for person in hired():
		sum += person.tip_bonus
	return sum


func _meet(person: StaffData) -> void:
	_ids("seen").append(person.id)
	var waiting := _ids("candidates")
	waiting.append(person.id)
	while waiting.size() > catalog.max_candidates:
		waiting.remove_at(0)


func _ids(key: String) -> Array:
	var list: Array = _data[key]
	return list


func _people(key: String) -> Array[StaffData]:
	var result: Array[StaffData] = []
	for id: Variant in _ids(key):
		var person := catalog.find(str(id))
		if person:
			result.append(person)
	return result
