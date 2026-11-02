class_name BedroomScene3D
extends Node3D
## Rin's room, where every day of the loop starts (horror build, PLAN §10).
## On arrival it judges last night's street-end choice (LoopCalendar): next
## day, back to mùng 9, or the ending; then autosaves. Rin walks (first
## person, FirstPersonView3D) to read the paper under the door and leaves
## through the door with E ("Ra quán").

const RESTAURANT := "res://scenes/restaurant3d/restaurant_scene_3d.tscn"
const ENDING := "res://scenes/ending/ending_scene.tscn"
const NEWS: NewsData = preload("res://data/story/news.tres")
const REACH := 1.3

@export var walk_speed := 1.6

## Shared shape with RestaurantScene3D for FirstPersonView3D.
var player: CharacterBody3D
var demo_camera: Camera3D
var body: Node3D = null
## FirstPersonView3D looks this way first (towards the door).
var start_yaw := 0.0
var text: OnScreenText
var leaving := false
var _calendar: Label3D


func _ready() -> void:
	var result := LoopCalendar.take_result()
	if result == LoopCalendar.Result.END:
		leaving = true  # nothing is built; straight on to the ending
		_go_to_ending()
		return
	if result == LoopCalendar.Result.NEXT:
		LoopCalendar.next_day()
	elif result == LoopCalendar.Result.RESET:
		LoopCalendar.reset_loop()
	_calendar = BedroomBuilder3D.build(self)
	_calendar.text = LoopCalendar.date_text(GameState.day).replace(" tháng", "\ntháng")
	player = CharacterBody3D.new()
	add_child(player)
	player.position = BedroomBuilder3D.START
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.6
	shape.shape = capsule
	shape.position.y = 0.8
	player.add_child(shape)
	demo_camera = Camera3D.new()
	add_child(demo_camera)
	demo_camera.position = player.position + Vector3(0, 1.55, 0)
	var to_door := BedroomBuilder3D.DOOR - BedroomBuilder3D.START
	start_yaw = atan2(-to_door.x, -to_door.z)
	demo_camera.rotation.y = start_yaw
	demo_camera.current = true
	text = OnScreenText.new()
	add_child(text)
	if result == LoopCalendar.Result.RESET:
		text.say("...Lại mùng 9?", 3.0)
	GameState.resume_at = "home"
	SaveSystem.autosave("home")
	Sfx.ambience("sea")
	Sfx.bed("room")


func _physics_process(_delta: float) -> void:
	if leaving or get_tree().paused:
		return
	var axes := Input.get_vector("turn_left", "turn_right", "throttle_forward", "throttle_back")
	var right := demo_camera.global_basis.x
	var forward := demo_camera.global_basis.z
	right.y = 0.0
	forward.y = 0.0
	var direction := (right.normalized() * axes.x + forward.normalized() * axes.y).limit_length(1.0)
	player.velocity = direction * walk_speed
	player.move_and_slide()


func _process(_delta: float) -> void:
	if leaving:
		return
	if _near(BedroomBuilder3D.DOOR):
		text.prompt("E  Ra quán")
	elif _near(BedroomBuilder3D.PAPER):
		text.prompt("E  Đọc báo")
	else:
		text.prompt("")


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.physical_keycode != KEY_E or leaving:
		return
	if _near(BedroomBuilder3D.DOOR):
		get_viewport().set_input_as_handled()
		leave()
	elif _near(BedroomBuilder3D.PAPER):
		get_viewport().set_input_as_handled()
		text.say("%s — %s\n%s" % [NEWS.title, LoopCalendar.date_text(GameState.day), NEWS.page(GameState.day)], 6.0)


## Called from _ready while the fade into this room is still running.
func _go_to_ending() -> void:
	while SceneRouter._is_transitioning:
		await get_tree().process_frame
	SceneRouter.go_to(ENDING)


func leave() -> void:
	leaving = true
	text.prompt("")
	SceneRouter.go_to(RESTAURANT)


func _near(point: Vector3) -> bool:
	var at := player.global_position
	return Vector2(at.x - point.x, at.z - point.z).length() < REACH
