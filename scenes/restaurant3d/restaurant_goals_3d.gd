class_name RestaurantGoals3D
extends RefCounted
## The 3D restaurant's goals: today's challenges (DailyChallenges) on the HUD
## card, NEO's line when one is met, and at closing lifetime stats
## (LifetimeStats), rewards and new achievements (Achievements, toast).
## The host owns `shift_log` (ShiftLog, filled by RestaurantService3D) and
## gets `shift_results` at closing (see finish_shift) for the scoreboard.

const CHALLENGES: ChallengeCatalog = preload("res://data/challenges/challenge_catalog.tres")
const ACHIEVEMENTS: AchievementCatalog = preload("res://data/achievements/achievement_catalog.tres")
## NEO speaks a moment after the service's own line ("+45k...").
const NEO_DELAY := 1.4

var host: Node3D
var card: ChallengeCard3D
var toast: AchievementToast
var picks: Array[ChallengeData] = []
var _announced: Dictionary = {}


func _init(owner: Node3D) -> void:
	host = owner


func build() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	host.add_child(layer)
	card = ChallengeCard3D.new()
	card.hidden_when = func() -> bool: return host.story_bridge == null or host.story_bridge.playing \
		or host.planning_panel.visible or host.panels.market_panel.visible or host.is_renovating() \
		or host.panels.summary_visible()
	layer.add_child(card)
	toast = AchievementToast.new()
	host.add_child(toast)
	var guide := Guide.new()
	guide.blocked = func() -> bool: return host.modal_open() or (host.story_bridge != null and host.story_bridge.playing)
	host.add_child(guide)
	guide.add("challenges3d", "Làm xong để nhận thưởng",func() -> bool: return card.visible and host.shift_running,
		func() -> Vector2: return Vector2(card.position.x - 4.0, card.position.y + 10.0))


## Shift opens: fresh log, today's challenges (rolled once a day, saved).
func start_shift() -> void:
	host.shift_log = ShiftLog.new()
	host.shift_log.logged.connect(refresh)
	var dishes: Array[DishData] = host.plan.available_dishes()
	var beer_on_sale := false
	for dish: DishData in host.menu.dishes:
		beer_on_sale = beer_on_sale or (dish.instant_serve and dish.unlock_day <= GameState.day)
	picks = DailyChallenges.ensure(CHALLENGES, GameState.day, DailyChallenges.context(dishes, beer_on_sale, DailyTrend.dish_id()))
	_announced.clear()
	var entries: Array[Dictionary] = []
	for challenge in picks:
		entries.append({"icon": challenge.icon, "text": "%s  +%dk" % [challenge.describe(GameState.day), challenge.reward_on(GameState.day)]})
	if card:
		card.bind(entries)
	refresh()


## Re-reads the log: card lines, NEO once per finished challenge.
func refresh(final: bool = false) -> void:
	for i in picks.size():
		var challenge := picks[i]
		var state := DailyChallenges.status(challenge, host.shift_log, GameState.day, CHALLENGES.fast_patience, final)
		if card:
			card.set_line(i, int(state["progress"]), int(state["target"]), bool(state["done"]), bool(state["failed"]),
				challenge.kind == ChallengeData.Kind.EARN)
		if bool(state["done"]) and not _announced.has(challenge.id) and not final:
			_announced[challenge.id] = true
			_announce(challenge)


func _announce(challenge: ChallengeData) -> void:
	var words := "NEO: Thử thách xong: %s +%dk" % [challenge.describe(GameState.day), challenge.reward_on(GameState.day)]
	if not host.is_inside_tree():
		return
	host.get_tree().create_timer(NEO_DELAY).timeout.connect(func() -> void:
		if is_instance_valid(host) and not host.sailing:
			host._show_note(words)
			Sfx.play("neo"))


## Closing: stats, challenge rewards, achievements. Returns host.shift_results:
## {"day", "stars", "served", "lost", "earned", "challenges": [{"id", "icon",
## "text", "progress", "target", "done", "reward"}], "achievements": [{"id",
## "title", "desc", "icon", "reward"}], "bonus": total k paid by both}.
func finish_shift(stars: int) -> Dictionary:
	var shift: ShiftLog = host.shift_log
	refresh(true)
	var challenges := DailyChallenges.settle(picks, shift, GameState.day, CHALLENGES.fast_patience)
	var bonus := 0
	for entry in challenges:
		bonus += int(entry["reward"])
		if int(entry["reward"]) > 0:
			LifetimeStats.add(GameState.stats, "challenges_done", 1)
	LifetimeStats.apply(GameState.stats, shift, stars, host.staff_roster.hired().size())
	var unlocked: Array[Dictionary] = []
	for achievement in Achievements.check(ACHIEVEMENTS, GameState.stats):
		bonus += achievement.reward_k
		unlocked.append({"id": achievement.id, "title": achievement.title, "desc": achievement.desc,
			"icon": achievement.icon, "reward": achievement.reward_k})
		if toast:
			toast.push(achievement.title, GoalIcons.badge(achievement.id, achievement.icon), achievement.reward_k)
	return {"day": GameState.day, "stars": stars, "served": shift.parties_served(), "lost": shift.lost,
		"earned": shift.earned, "challenges": challenges, "achievements": unlocked, "bonus": bonus}


## Short lines for the summary text (until the scoreboard replaces it).
static func summary_lines(results: Dictionary) -> String:
	var lines := PackedStringArray()
	var challenges: Array = results.get("challenges", [])
	if not challenges.is_empty():
		var done := challenges.filter(func(e: Dictionary) -> bool: return bool(e["done"])).size()
		lines.append("Thử thách: %d/%d xong" % [done, challenges.size()])
		for entry: Dictionary in challenges:
			if bool(entry["done"]):
				lines.append("  + %s  +%dk" % [entry["text"], int(entry["reward"])])
	for entry: Dictionary in results.get("achievements", []):
		lines.append("Thành tựu: %s  +%dk" % [entry["title"], int(entry["reward"])])
	return "\n".join(lines)
