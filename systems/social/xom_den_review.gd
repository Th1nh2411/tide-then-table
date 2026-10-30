class_name XomDenReview
extends RefCounted
## "Xóm Đèn Review", the street's food social network (Dave the Diver's
## Cooksta): after each shift 2-4 guests post about the dish they ate (stars
## from how long they waited, freshness, HOT dish, tips; a short caption by
## mood; likes). Followers grow / shrink with the day; follower tiers pay a
## one-time reward and bring guests a bit more often (spawn_interval_scale).
## State in GameState.social (saved): {"followers": int, "tier": int (highest
## reached), "posts": [post, newest first]}. Pure logic, no nodes.
## Post: {"day", "author" (avatar id), "name", "dish" (dish id, "" unknown),
## "stars" 1-5, "mood" happy|neutral|angry, "caption", "likes", "hot", "tip"}.

const TUNING: SocialTuning = preload("res://data/social/social_tuning.tres")
const POOL: ReviewPool = preload("res://data/social/review_pool.tres")


static func followers() -> int:
	return int(GameState.social.get("followers", 0))


static func tier() -> int:
	return int(GameState.social.get("tier", 0))


static func posts() -> Array:
	return GameState.social.get("posts", [])


## Stars of one served table's post.
static func party_stars(party: Dictionary, hot_id: String, t: SocialTuning = TUNING) -> int:
	var patience: float = float(party.get("patience", 0.0))
	var stars := 2
	if patience >= t.five_star_patience:
		stars = 5
	elif patience >= t.four_star_patience:
		stars = 4
	elif patience >= t.three_star_patience:
		stars = 3
	if float(party.get("fresh", 100.0)) < t.stale_freshness:
		stars -= 1
	if hot_id != "" and str(party.get("dish", "")) == hot_id:
		stars += 1
	return clampi(stars, 1, 5)


static func mood_for(stars: int) -> String:
	if stars >= 4:
		return "happy"
	return "neutral" if stars == 3 else "angry"


## The shift's posts, deterministic for `seed`. Always includes the best
## table and, if anyone left, one angry post.
static func make_posts(shift: ShiftLog, day: int, hot_id: String, follower_count: int, seed: int,
		pool: ReviewPool = POOL, t: SocialTuning = TUNING) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var candidates: Array[Dictionary] = []
	for party in shift.parties:
		candidates.append({"stars": party_stars(party, hot_id, t), "dish": str(party.get("dish", "")),
			"tip": int(party.get("tip", 0)) > 0})
	for dish_id in shift.lost_dishes:
		candidates.append({"stars": 1, "dish": dish_id, "tip": false})
	var result: Array[Dictionary] = []
	if candidates.is_empty():
		return result
	var wanted := clampi(t.min_posts + shift.parties.size() / maxi(t.tables_per_post, 1), t.min_posts, t.max_posts)
	var order: Array[int] = []
	for i in candidates.size():
		order.append(i)
	for i in range(order.size() - 1, 0, -1):  # Fisher-Yates with our rng
		var j := rng.randi_range(0, i)
		var swap := order[i]
		order[i] = order[j]
		order[j] = swap
	var picked: Array[int] = []
	var best := -1
	for i in shift.parties.size():
		if best < 0 or int(candidates[i]["stars"]) > int(candidates[best]["stars"]):
			best = i
	if best >= 0:
		picked.append(best)
	if shift.lost_dishes.size() > 0:
		picked.append(shift.parties.size())
	for i in order:
		if picked.size() >= wanted:
			break
		if not picked.has(i):
			picked.append(i)
	var authors: Array[int] = []
	for i in pool.author_ids.size():
		authors.append(i)
	for index in picked.slice(0, wanted):
		var entry: Dictionary = candidates[index]
		var dish_id: String = entry["dish"]
		if dish_id == "" and not shift.dishes.is_empty():
			dish_id = str(shift.dishes[rng.randi_range(0, shift.dishes.size() - 1)]["id"])
		result.append(_post(entry, dish_id, day, hot_id, follower_count, rng, authors, pool, t))
	return result


static func _post(entry: Dictionary, dish_id: String, day: int, hot_id: String, follower_count: int,
		rng: RandomNumberGenerator, authors: Array[int], pool: ReviewPool, t: SocialTuning) -> Dictionary:
	var stars: int = entry["stars"]
	var mood := mood_for(stars)
	var hot := hot_id != "" and dish_id == hot_id
	var tip: bool = entry["tip"]
	var lines: Array[String] = pool.captions(mood)
	if mood == "happy" and rng.randf() < pool.special_caption_chance:
		if hot and not pool.hot_captions.is_empty():
			lines = pool.hot_captions
		elif tip and not pool.tip_captions.is_empty():
			lines = pool.tip_captions
	var caption: String = lines[rng.randi_range(0, lines.size() - 1)] if not lines.is_empty() else ""
	var who := 0
	if not authors.is_empty():  # no author twice in one shift
		who = authors.pop_at(rng.randi_range(0, authors.size() - 1))
	var likes := (t.likes_base + stars * t.likes_per_star + follower_count * t.likes_follower_share) \
		* rng.randf_range(1.0 - t.likes_spread, 1.0 + t.likes_spread) * (t.hot_likes_scale if hot else 1.0)
	return {"day": day, "author": pool.author_ids[who] if who < pool.author_ids.size() else "",
		"name": pool.author_names[who] if who < pool.author_names.size() else "", "dish": dish_id,
		"stars": stars, "mood": mood, "caption": caption, "likes": maxi(roundi(likes), 0), "hot": hot, "tip": tip}


static func follower_delta(stars: int, new_posts: Array, hot_count: int, challenges_done: int, lost: int,
		t: SocialTuning = TUNING) -> int:
	var likes := 0
	for post: Dictionary in new_posts:
		likes += int(post.get("likes", 0))
	var by_stars: int = t.followers_by_stars[clampi(stars, 0, t.followers_by_stars.size() - 1)]
	return by_stars + roundi(likes * t.followers_per_like) + hot_count * t.followers_per_hot_dish \
		+ challenges_done * t.followers_per_challenge - lost * t.followers_per_lost


## Highest tier whose follower threshold is reached.
static func tier_for(follower_count: int, t: SocialTuning = TUNING) -> int:
	var reached := 0
	for i in t.tier_followers.size():
		if follower_count >= t.tier_followers[i]:
			reached = i
	return reached


## 0..1 from the current tier's threshold to the next (1 at the top tier).
static func tier_progress(follower_count: int, current_tier: int, t: SocialTuning = TUNING) -> float:
	if current_tier + 1 >= t.tier_followers.size():
		return 1.0
	var low: int = t.tier_followers[current_tier]
	var high: int = t.tier_followers[current_tier + 1]
	return clampf(float(follower_count - low) / maxf(high - low, 1.0), 0.0, 1.0)


static func tier_name(index: int, t: SocialTuning = TUNING) -> String:
	return t.tier_names[clampi(index, 0, t.tier_names.size() - 1)]


## Hook for the guest spawn interval: lower = more guests.
static func spawn_interval_scale(t: SocialTuning = TUNING) -> float:
	return t.tier_spawn_scale[clampi(tier(), 0, t.tier_spawn_scale.size() - 1)]


## Closing: posts, followers, tier (reward paid once per tier). Returns
## {"followers_before", "followers_after", "tier_before", "tier_after",
## "reward", "posts": [...]} (= host.shift_results["social"]).
static func apply_shift(shift: ShiftLog, results: Dictionary, seed: int, t: SocialTuning = TUNING,
		pool: ReviewPool = POOL) -> Dictionary:
	var before := followers()
	var tier_before := tier()
	var stars: int = int(results.get("stars", GameState.last_rating))
	var fresh := make_posts(shift, GameState.day, DailyTrend.dish_id(), before, seed, pool, t)
	var challenges_done := 0
	for entry: Dictionary in results.get("challenges", []):
		challenges_done += 1 if bool(entry.get("done", false)) else 0
	var after := maxi(before + follower_delta(stars, fresh, shift.hot_count(), challenges_done, shift.lost, t), 0)
	var tier_after := maxi(tier_before, tier_for(after, t))
	var reward := 0
	for i in range(tier_before + 1, tier_after + 1):
		reward += t.tier_reward_k[i] if i < t.tier_reward_k.size() else 0
	GameState.add_money(reward)
	var saved: Array = fresh.duplicate(true)
	saved.append_array(posts())
	GameState.social = {"followers": after, "tier": tier_after, "posts": saved.slice(0, t.max_saved_posts)}
	return {"followers_before": before, "followers_after": after, "tier_before": tier_before,
		"tier_after": tier_after, "reward": reward, "posts": fresh}


## Clean copy of saved social state (JSON floats -> ints, junk dropped).
static func from_save(data: Variant, t: SocialTuning = TUNING) -> Dictionary:
	if not data is Dictionary:
		return {}
	var count: Variant = data.get("followers")
	var level: Variant = data.get("tier")
	var clean_posts: Array = []
	var saved: Variant = data.get("posts")
	if saved is Array:
		for entry: Variant in saved:
			if entry is Dictionary and clean_posts.size() < t.max_saved_posts:
				clean_posts.append(_clean_post(entry))
	return {"followers": maxi(int(count), 0) if count is int or count is float else 0,
		"tier": clampi(int(level), 0, t.tier_followers.size() - 1) if level is int or level is float else 0,
		"posts": clean_posts}


static func _clean_post(entry: Dictionary) -> Dictionary:
	var number := func(key: String) -> int:
		var value: Variant = entry.get(key)
		return int(value) if value is int or value is float else 0
	return {"day": number.call("day"), "author": str(entry.get("author", "")), "name": str(entry.get("name", "")),
		"dish": str(entry.get("dish", "")), "stars": clampi(number.call("stars"), 1, 5),
		"mood": str(entry.get("mood", "neutral")), "caption": str(entry.get("caption", "")),
		"likes": maxi(number.call("likes"), 0), "hot": entry.get("hot", false) == true,
		"tip": entry.get("tip", false) == true}
