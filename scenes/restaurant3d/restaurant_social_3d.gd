class_name RestaurantSocial3D
extends RefCounted
## The 3D restaurant's "Xóm Đèn Review" side: at closing the guests post
## (XomDenReview), followers / tier change, the weekly ranking (RivalRanking)
## is checked; the SocialMoment pops the new posts, NEO says tier-ups and
## rivals beaten, a tier-up also gets a toast. Results go to
## host.shift_results["social"] and ["rank"] for the scoreboard.

## NEO waits for the service / goals lines first.
const NEO_DELAY := 2.6
const NEO_STEP := 1.6

var host: Node3D
var moment: SocialMoment


func _init(owner: Node3D) -> void:
	host = owner


func build() -> void:
	moment = SocialMoment.new()
	host.add_child(moment)


## Call after the day record is added (RestaurantService3D.end_shift).
func close_shift() -> void:
	var shift: ShiftLog = host.shift_log
	var social := XomDenReview.apply_shift(shift, host.shift_results, GameState.day * 7919 + shift.earned)
	var rank := RivalRanking.close_day(GameState.day, GameState.day_history)
	host.shift_results["social"] = social
	host.shift_results["rank"] = rank
	if moment and not (social["posts"] as Array).is_empty():
		moment.play(social)
	var lines: Array[String] = []
	var tier_after: int = social["tier_after"]
	if tier_after > int(social["tier_before"]):
		var title := XomDenReview.tier_name(tier_after)
		lines.append("NEO: Quán lên hạng \"%s\" rồi anh Rin! +%dk" % [title, int(social["reward"])])
		var toast: AchievementToast = host.goals.toast if host.goals else null
		if toast:
			toast.push(title, GoalIcons.icon("tier_%d" % tier_after), int(social["reward"]))
	for rival_id: String in rank["beaten"]:
		var rival := RivalRanking.CATALOG.find(rival_id)
		lines.append("NEO: Tuần này mình vượt %s! +%dk" % [rival.display_name, rival.beat_reward_k])
	if not host.is_inside_tree():
		return
	for i in lines.size():
		var words := lines[i]
		host.get_tree().create_timer(NEO_DELAY + NEO_STEP * i).timeout.connect(func() -> void:
			if is_instance_valid(host) and not host.sailing:
				host._show_note(words)
				Sfx.play("neo"))


## Hook for the guest spawn interval (follower tier brings guests faster).
static func spawn_scale() -> float:
	return XomDenReview.spawn_interval_scale()
