class_name DailyChallenges
extends RefCounted
## Today's restaurant challenges (Dave the Diver style): `per_day` picked
## when the shift opens, deterministically from the day, only among ones the
## day can really meet (a grill dish on the menu, beer on sale, today's HOT
## dish on the menu). Ids kept in story flags (saved) so a reload keeps them:
## "challenge_day", "challenge_ids" ("a,b,c"). Progress comes from the
## ShiftLog; rewards are paid once at closing ("challenge_paid_day").
## Pure logic, no nodes.

const DAY_FLAG := "challenge_day"
const IDS_FLAG := "challenge_ids"
const PAID_FLAG := "challenge_paid_day"


## What today's menu allows. `dishes` = what can be served this shift.
static func context(dishes: Array[DishData], beer_on_sale: bool, hot_id: String) -> Dictionary:
	var grill := false
	var hot := false
	for dish in dishes:
		grill = grill or (dish.cook_type == DishData.CookType.GRILL and not dish.instant_serve)
		hot = hot or (hot_id != "" and dish.id == hot_id)
	return {"grill": grill, "beer": beer_on_sale, "hot": hot}


static func is_possible(challenge: ChallengeData, day: int, ctx: Dictionary) -> bool:
	if challenge.min_day > day:
		return false
	match challenge.kind:
		ChallengeData.Kind.GRILL:
			return bool(ctx.get("grill", false))
		ChallengeData.Kind.BEER:
			return bool(ctx.get("beer", false))
		ChallengeData.Kind.HOT:
			return bool(ctx.get("hot", false))
	return true


## Same day + same context = same picks.
static func roll(catalog: ChallengeCatalog, day: int, ctx: Dictionary) -> Array[ChallengeData]:
	var pool: Array[ChallengeData] = []
	for challenge in catalog.challenges:
		if is_possible(challenge, day, ctx):
			pool.append(challenge)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("rin_challenges_%d" % day)
	for i in range(pool.size() - 1, 0, -1):  # Fisher-Yates with the day's rng
		var j := rng.randi_range(0, i)
		var swap: ChallengeData = pool[i]
		pool[i] = pool[j]
		pool[j] = swap
	return pool.slice(0, mini(catalog.per_day, pool.size()))


## Today's picks: the saved ones if already rolled today, else rolled + saved.
static func ensure(catalog: ChallengeCatalog, day: int, ctx: Dictionary) -> Array[ChallengeData]:
	var saved := saved_for(catalog, day)
	if not saved.is_empty():
		return saved
	var picks := roll(catalog, day, ctx)
	GameState.set_flag(DAY_FLAG, day)
	var ids := PackedStringArray()
	for challenge in picks:
		ids.append(challenge.id)
	GameState.set_flag(IDS_FLAG, ",".join(ids))
	return picks


static func saved_for(catalog: ChallengeCatalog, day: int) -> Array[ChallengeData]:
	var picks: Array[ChallengeData] = []
	if int(GameState.story_flags.get(DAY_FLAG, 0)) != day:
		return picks
	for id: String in str(GameState.story_flags.get(IDS_FLAG, "")).split(",", false):
		var challenge := catalog.find(id)
		if challenge:
			picks.append(challenge)
	return picks


## How far along: progress so far (capped at the target).
static func progress(challenge: ChallengeData, shift: ShiftLog, fast_ratio: float) -> int:
	match challenge.kind:
		ChallengeData.Kind.PARTIES, ChallengeData.Kind.NOBODY_LEFT:
			return shift.parties_served()
		ChallengeData.Kind.GRILL:
			return shift.grill_count()
		ChallengeData.Kind.BEER:
			return shift.beer_count()
		ChallengeData.Kind.HOT:
			return shift.hot_count()
		ChallengeData.Kind.EARN:
			return shift.earned
		ChallengeData.Kind.FAST:
			return shift.fast_count(fast_ratio)
		ChallengeData.Kind.TIPS:
			return shift.tips_count()
	return 0


## {"progress", "target", "done", "failed"}. NOBODY_LEFT only counts as done
## once the shift is `final` (someone may still walk out).
static func status(challenge: ChallengeData, shift: ShiftLog, day: int, fast_ratio: float, final: bool) -> Dictionary:
	var target := challenge.target_on(day)
	var got := progress(challenge, shift, fast_ratio)
	var failed := challenge.kind == ChallengeData.Kind.NOBODY_LEFT and shift.lost > 0
	var done := got >= target and not failed
	if challenge.kind == ChallengeData.Kind.NOBODY_LEFT and not final:
		done = false
	return {"progress": mini(got, target), "target": target, "done": done, "failed": failed}


## Closing: pays every finished challenge once per day. Returns one entry per
## challenge: {"id", "icon", "text", "progress", "target", "done", "reward"} (reward
## 0 when not done, or when today's rewards were already paid).
static func settle(picks: Array[ChallengeData], shift: ShiftLog, day: int, fast_ratio: float) -> Array[Dictionary]:
	var already_paid := int(GameState.story_flags.get(PAID_FLAG, 0)) == day
	var results: Array[Dictionary] = []
	for challenge in picks:
		var state := status(challenge, shift, day, fast_ratio, true)
		var reward: int = challenge.reward_on(day) if bool(state["done"]) and not already_paid else 0
		if reward > 0:
			GameState.add_money(reward)
		results.append({"id": challenge.id, "icon": challenge.icon, "text": challenge.describe(day), "progress": state["progress"],
			"target": state["target"], "done": state["done"], "reward": reward})
	if not picks.is_empty():
		GameState.set_flag(PAID_FLAG, day)
	return results
