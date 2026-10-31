extends Node
## Standalone test (F6) for "Xóm Đèn Review" + the weekly ranking: posts
## deterministic for a seed, stars / moods / captions, follower math, tiers
## and their one-time reward, ranking order + first-beat reward, save round
## trip, the phone tab and the shift-end moment build.

const TUNING: SocialTuning = preload("res://data/social/social_tuning.tres")
const POOL: ReviewPool = preload("res://data/social/review_pool.tres")
const RIVALS: RivalCatalog = preload("res://data/social/rival_catalog.tres")
const SAVE_PATH := "user://social_test_save.json"

var _failures := 0


func _ready() -> void:
	GameState.reset()
	_test_data()
	_test_posts()
	_test_followers_and_tiers()
	_test_apply_shift()
	_test_ranking()
	_test_save()
	await _test_ui()
	GameState.reset()
	SaveSystem.delete_save(SAVE_PATH)
	print("social_test: %s" % ("ALL PASS" if _failures == 0 else "%d FAIL" % _failures))
	get_tree().quit()


func _shift() -> ShiftLog:
	var shift := ShiftLog.new()
	var grill: DishData = load("res://data/dishes/ca_thu_nuong.tres")
	shift.record_dish(grill, 80, true, 90.0)
	shift.record_party(80, 16, 0.8, false, "ca_thu_nuong", 90.0)
	shift.record_party(60, 0, 0.3, false, "tom_luoc", 40.0)
	shift.record_party(50, 0, 0.45, false, "", 100.0)
	shift.record_party(70, 14, 0.65, false, "ca_thu_nuong", 95.0)
	shift.record_lost(0, "tom_luoc")
	return shift


func _test_data() -> void:
	_check("pool: one name per avatar id, captions <= 6 words", POOL.author_ids.size() == POOL.author_names.size()
		and POOL.author_ids.size() >= 6 and _all_short(POOL))
	_check("tiers: 4 rising thresholds, rewards, spawn scales", TUNING.tier_names.size() == 4
		and TUNING.tier_followers.size() == 4 and TUNING.tier_reward_k.size() == 4 and TUNING.tier_spawn_scale.size() == 4
		and TUNING.tier_followers[1] > TUNING.tier_followers[0] and TUNING.tier_followers[3] > TUNING.tier_followers[2])
	var names := ""
	for rival in RIVALS.rivals:
		names += rival.display_name + ","
	_check("3 rivals incl. Ốc Thâm Lam", RIVALS.rivals.size() == 3 and names.contains("Thâm Lam"))


func _all_short(pool: ReviewPool) -> bool:
	for list: Array[String] in [pool.happy_captions, pool.neutral_captions, pool.angry_captions, pool.hot_captions, pool.tip_captions]:
		if list.is_empty():
			return false
		for caption in list:
			if caption.split(" ", false).size() > 6:
				return false
	return true


func _test_posts() -> void:
	var shift := _shift()
	var a := XomDenReview.make_posts(shift, 3, "ca_thu_nuong", 50, 1234)
	var b := XomDenReview.make_posts(shift, 3, "ca_thu_nuong", 50, 1234)
	_check("same seed -> same posts", JSON.stringify(a) == JSON.stringify(b))
	var differs := false
	for seed in range(1, 12):
		differs = differs or JSON.stringify(XomDenReview.make_posts(shift, 3, "ca_thu_nuong", 50, seed)) != JSON.stringify(a)
	_check("other seeds differ", differs)
	_check("2-4 posts (4 tables -> 3)", a.size() == 3)
	var has_five := a.any(func(p: Dictionary) -> bool: return int(p["stars"]) == 5)
	var has_angry := a.any(func(p: Dictionary) -> bool: return p["mood"] == "angry" and int(p["stars"]) == 1)
	_check("best table + the guest who left are posted", has_five and has_angry)
	var authors: Dictionary = {}
	for post in a:
		authors[post["author"]] = true
	_check("no author twice, every post has a dish + caption", authors.size() == a.size()
		and a.all(func(p: Dictionary) -> bool: return str(p["dish"]) != "" and str(p["caption"]) != ""))
	_check("stars: fast + HOT = 5, slow + stale = 2 -> 1",
		XomDenReview.party_stars({"patience": 0.45, "dish": "x"}, "x") == 5
		and XomDenReview.party_stars({"patience": 0.25, "fresh": 30.0}, "") == 2
		and XomDenReview.party_stars({"patience": 0.1, "fresh": 30.0}, "") == 1)
	_check("moods", XomDenReview.mood_for(5) == "happy" and XomDenReview.mood_for(3) == "neutral"
		and XomDenReview.mood_for(2) == "angry")
	_check("empty shift -> no posts", XomDenReview.make_posts(ShiftLog.new(), 1, "", 0, 7).is_empty())


func _test_followers_and_tiers() -> void:
	var posts: Array = [{"likes": 20}, {"likes": 10}]
	# 5 stars: 12 + 30 likes * 0.1 = 3 + 2 HOT + 1 challenge * 3 - 1 lost * 2 = 18
	_check("follower delta adds up", XomDenReview.follower_delta(5, posts, 2, 1, 1) == 18)
	_check("bad day loses followers", XomDenReview.follower_delta(1, [], 0, 0, 3) < 0)
	_check("tier thresholds", XomDenReview.tier_for(0) == 0 and XomDenReview.tier_for(39) == 0
		and XomDenReview.tier_for(40) == 1 and XomDenReview.tier_for(5000) == 3)
	_check("tier progress", is_equal_approx(XomDenReview.tier_progress(80, 1), 0.5)
		and XomDenReview.tier_progress(999, 3) == 1.0)


func _test_apply_shift() -> void:
	GameState.reset()
	GameState.day = 3
	GameState.social = {"followers": 35, "tier": 0, "posts": []}
	GameState.money = 0
	var result := XomDenReview.apply_shift(_shift(), {"stars": 5, "challenges": [{"done": true}]}, 99)
	_check("result keys", result.has_all(["followers_before", "followers_after", "tier_before", "tier_after", "posts"]))
	_check("followers up, tier 1 reached and paid once", int(result["followers_after"]) > 40
		and int(result["tier_after"]) == 1 and GameState.money == TUNING.tier_reward_k[1])
	var scale := XomDenReview.spawn_interval_scale()
	_check("tier brings guests faster", scale < 1.0 and is_equal_approx(scale, TUNING.tier_spawn_scale[1]))
	GameState.social["followers"] = 0
	XomDenReview.apply_shift(_shift(), {"stars": 5}, 5)
	_check("tier never drops, no second reward", XomDenReview.tier() == 1 and GameState.money == TUNING.tier_reward_k[1])
	for i in 10:
		XomDenReview.apply_shift(_shift(), {"stars": 4}, i)
	_check("saved posts capped, newest first", XomDenReview.posts().size() == TUNING.max_saved_posts)


func _test_ranking() -> void:
	GameState.reset()
	var tham_lam := RIVALS.find("tham_lam")
	_check("rival curves are deterministic and grow", tham_lam.revenue(3) == tham_lam.revenue(3)
		and tham_lam.revenue(10) > tham_lam.revenue(2) and tham_lam.revenue(0) == 0)
	var history: Array = [{"day": 1, "earned": 50}, {"day": 2, "earned": 60}]
	var board := RivalRanking.week_board(2, history)
	_check("board: 4 eateries, best first", board.size() == 4
		and int(board[0]["total"]) >= int(board[1]["total"]) and int(board[2]["total"]) >= int(board[3]["total"]))
	_check("small week -> last place", RivalRanking.player_rank(board) == 4)
	_check("player daily window", RivalRanking.player_daily(2, history, 7) == [0, 0, 0, 0, 0, 50, 60])
	GameState.money = 0
	history.append({"day": 3, "earned": 3200})
	var closed := RivalRanking.close_day(3, history)
	_check("big day beats the small rivals", int(closed["rank_before"]) == 4 and int(closed["rank_after"]) < 4
		and (closed["beaten"] as Array).has("chu_hen") and GameState.has_flag("rival_beat_chu_hen"))
	var paid := GameState.money
	_check("first beat pays its reward", paid == int(closed["reward"]) and paid >= RIVALS.find("chu_hen").beat_reward_k)
	var again := RivalRanking.close_day(3, history)
	_check("beating again pays nothing", (again["beaten"] as Array).is_empty() and GameState.money == paid)


func _test_save() -> void:
	GameState.reset()
	GameState.social = {"followers": 77, "tier": 1, "posts": [{"day": 2, "author": "mimi", "name": "Mimi Review",
		"dish": "tom_luoc", "stars": 4, "mood": "happy", "caption": "Ngon xỉu luôn!", "likes": 23, "hot": true, "tip": false}]}
	_check("save written", SaveSystem.save_game(SAVE_PATH))
	GameState.reset()
	_check("reset clears social", GameState.social.is_empty() and XomDenReview.followers() == 0)
	_check("save loads", SaveSystem.load_game(SAVE_PATH))
	var post: Dictionary = XomDenReview.posts()[0] if not XomDenReview.posts().is_empty() else {}
	_check("social round trip (ints after JSON)", GameState.social.get("followers") is int
		and XomDenReview.followers() == 77 and XomDenReview.tier() == 1 and post.get("likes") is int
		and int(post.get("likes", 0)) == 23 and post.get("hot") == true and post.get("caption") == "Ngon xỉu luôn!")
	_check("junk social -> fresh", XomDenReview.from_save("bad").is_empty()
		and XomDenReview.from_save({"followers": -5, "tier": 99})["tier"] == 3)


func _test_ui() -> void:
	GameState.reset()
	GameState.day = 3
	XomDenReview.apply_shift(_shift(), {"stars": 5}, 3)
	GameState.add_day_record({"day": 3, "earned": 400})
	var review := PhoneReview.new()
	review.size = Vector2(384, 200)
	add_child(review)
	review.refresh()
	_check("phone review: one card per post", review.card_count() == XomDenReview.posts().size())
	review.show_page(true)
	_check("ranking page shows 4 bars", review._rank_view.visible and review._chart.board.size() == 4)
	var moment := SocialMoment.new()
	add_child(moment)
	moment.play({"followers_before": 0, "followers_after": 12, "posts": XomDenReview.posts()})
	_check("shift-end moment shows sticker + cards", moment.is_showing() and moment.get_child_count() >= 3)
	_check("placeholder frames are 16x16 nine-patches", SocialStyle.frame_image("social_card").get_size() == Vector2i(16, 16))
	await get_tree().process_frame


func _check(label: String, ok: bool) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		_failures += 1
