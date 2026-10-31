extends Node
## The 3D boat ramming a submerged rock: it bounces back instead of sliding,
## the hull rocks and settles, and the hull still takes damage.

const SEA := "res://scenes/sea3d/sea_scene_3d.tscn"

var failures: int = 0


func check(value: bool, label: String) -> void:
	print("PASS " + label if value else "FAIL " + label)
	if not value:
		failures += 1


func _ready() -> void:
	GameState.reset()
	var sea: SeaScene3D = load(SEA).instantiate()
	add_child(sea)
	for i in 5:
		await get_tree().physics_frame
	var rock: SubmergedRock3D = sea.submerged[0]
	sea.boat.position = rock.position + Vector3(3.0, 0, 0)
	sea.boat.rotation.y = PI * 0.5
	var hp: float = GameState.boat_hp
	var bounced := false
	var rocked := 0.0
	for i in 30:
		if i < 20 and not bounced:
			sea.boat.velocity = Vector3(-4.0, 0, 0)
		await get_tree().physics_frame
		rocked = maxf(rocked, sea.impact.rock.length())
		bounced = bounced or sea.boat.velocity.x > 0.3
	check(bounced, "boat bounces back off the rock")
	check(rocked > 0.03, "hull rocks on impact")
	check(GameState.boat_hp < hp, "impact still damages the hull")
	for i in 70:
		await get_tree().physics_frame
	check(sea.impact.rock.length() < 0.02, "rocking settles")
	print("boat_impact_test: %s" % ("ALL PASS" if failures == 0 else "%d FAIL" % failures))
	get_tree().quit(1 if failures else 0)
