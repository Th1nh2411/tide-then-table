extends Node
## Smoke test of the 3D restaurant's fixed setup: four tables, the fixed menu
## on the board, a good rating brings guests faster, no modal overlays.

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	GameState.reset()
	var room: Node3D = load("res://scenes/restaurant3d/restaurant_scene_3d.tscn").instantiate()
	room.auto_open = false
	add_child(room)
	await get_tree().process_frame
	var ok: bool = room.orders.size() == 4
	var board := room.get_node("WorldMenuBoard") as WorldMenuBoard3D
	ok = ok and board.displayed_dishes.size() == RestaurantService3D.FIXED_MENU.dishes.size()
	GameState.last_rating = 1
	room.rng.seed = 42
	var slow: float = room._next_spawn_interval()
	GameState.last_rating = 5
	room.rng.seed = 42
	ok = ok and room._next_spawn_interval() < slow and not room.modal_open()
	print(("PASS" if ok else "FAIL") + " restaurant3d: four tables, fixed menu board, rating brings guests")
	GameState.reset()
	get_tree().quit()
