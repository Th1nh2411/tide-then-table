extends Node
## Standalone test (run with F6): today's trending dish (DailyTrend: once a
## day, price and pick boost) and collection rewards (CollectionRewards: new
## species, milestones paid once, big size records, aberrant fish excluded).

var _failures: int = 0


func _ready() -> void:
	GameState.reset()
	_test_trend()
	GameState.reset()
	_test_rewards()
	GameState.reset()
	print("trend_test: %s" % ("ALL PASS" if _failures == 0 else "%d FAIL" % _failures))
	get_tree().quit()


func _test_trend() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	GameState.day = 1
	DailyTrend.ensure(rng)
	var first := DailyTrend.dish_id()
	_check("first night: a near-shore dish", first != "" and ["tom", "muc", "oc_huong"].any(
		func(id: String) -> bool: return first.begins_with(id)))
	GameState.caught_species = {"muc": 1}
	GameState.day = 2
	_check("rolled once a day", DailyTrend.ensure(rng) and not DailyTrend.ensure(rng))
	var menu: DishCatalog = load(DailyTrend.MENU_PATH)
	var hot: DishData = null
	var other: DishData = null
	for dish in menu.dishes:
		if DailyTrend.is_hot(dish):
			hot = dish
		elif other == null and not dish.ingredients.is_empty():
			other = dish
	_check("only a dish Rin can serve (caught + kitchen)", hot != null and DishBook.is_cookable(hot)
		and hot.id.begins_with("muc"))
	_check("hot dish sells x1.5, others x1", DailyTrend.price_scale(hot) == DailyTrend.PRICE_SCALE
		and DailyTrend.price_scale(other) == 1.0)
	_check("NEO announces it", DailyTrend.announcement(menu).begins_with("NEO: ")
		and DailyTrend.announcement(menu).contains(hot.display_name))
	GameState.day = 3
	_check("yesterday's dish is over", DailyTrend.dish_id() == "" and not DailyTrend.is_hot(hot))
	_check("new day rolls again", DailyTrend.ensure(rng) and DailyTrend.dish_id() != "")


func _test_rewards() -> void:
	var catalog: FishCatalog = load(CollectionRewards.FISH_CATALOG_PATH)
	var regular: Array[FishData] = []
	var glowing: FishData = null
	for fish in catalog.fish:
		if fish.is_aberrant:
			glowing = fish
		else:
			regular.append(fish)
	var money := GameState.money
	var lines := _catch(regular[0], 1.0)
	_check("new species pays", GameState.money > money and lines.size() == 1)
	_catch(regular[1], 1.0)
	money = GameState.money
	lines = _catch(regular[2], 1.0)
	_check("3 species: milestone paid", lines.size() == 2 and GameState.money - money > 100)
	money = GameState.money
	lines = _catch(regular[2], 1.0)
	_check("same species again: nothing", lines.is_empty() and GameState.money == money)
	lines = _catch(regular[2], 1.5)
	_check("big size record pays", lines.size() == 1 and lines[0].contains("Kỷ lục"))
	lines = _catch(regular[2], 1.1)
	_check("smaller: no record", lines.is_empty())
	money = GameState.money
	lines = _catch(glowing, 1.0)
	_check("aberrant fish: no reward", lines.is_empty() and GameState.money == money)
	_check("next milestone text", CollectionRewards.next_milestone_text().contains("6 loài"))


## Same order as HoldManager.add_catch.
func _catch(fish: FishData, size: float) -> PackedStringArray:
	var is_new := int(GameState.caught_species.get(fish.id, 0)) == 0
	var previous_best := GameState.best_size(fish)
	GameState.record_catch(fish, 1, size)
	return CollectionRewards.claim(fish, size, is_new, previous_best)


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
