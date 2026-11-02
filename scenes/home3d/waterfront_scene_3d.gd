class_name WaterfrontScene3D
extends Node3D
## Xóm Đèn's waterfront, outside Rin's house (horror build). Morning: Rin
## steps out of the house and takes the lane to the restaurant. Evening (back
## from the shift, EVENING_FLAG): the night's choice is made here, in the open
## where the dock omens can be seen — the house door (sleep) or the pier, down
## into ông Tư's thúng (the night sea). First person (FirstPersonView3D).

const BEDROOM := "res://scenes/home3d/bedroom_scene_3d.tscn"
const RESTAURANT := "res://scenes/restaurant3d/restaurant_scene_3d.tscn"
const SEA := "res://scenes/sea3d/sea_scene_3d.tscn"
## Set by the restaurant when Rin walks home after the shift.
const EVENING_FLAG := "waterfront_evening"
const REACH := 1.4

@export var walk_speed := 1.7

## Shared shape with RestaurantScene3D / BedroomScene3D for FirstPersonView3D.
var player: CharacterBody3D
var demo_camera: Camera3D
var body: Node3D = null
var start_yaw := 0.0
var evening := false
var leaving := false
var text: OnScreenText


func _ready() -> void:
	evening = GameState.has_flag(EVENING_FLAG)
	WaterfrontBuilder3D.build(self, evening)
	if evening:
		RamShore3D.attach(self)  # rằm: the village releases hoa đăng
	var start := WaterfrontBuilder3D.EVENING_START if evening else WaterfrontBuilder3D.MORNING_START
	player = Walker3D.make_player(self, start)
	demo_camera = Camera3D.new()
	add_child(demo_camera)
	demo_camera.far = 300.0
	demo_camera.position = start + Vector3(0, 1.55, 0)
	# Morning: out of the door, facing the sea. Evening: from the lane, facing the house and pier.
	start_yaw = 0.0 if not evening else -PI * 0.5
	demo_camera.rotation.y = start_yaw
	demo_camera.current = true
	text = OnScreenText.new()
	add_child(text)
	Sfx.ambience("sea")
	Sfx.bed("sea" if evening else "room")


func _physics_process(_delta: float) -> void:
	if leaving or get_tree().paused:
		return
	Walker3D.step(player, demo_camera, walk_speed)


func _process(_delta: float) -> void:
	if not leaving:
		text.prompt(_choice_text())


func _choice_text() -> String:
	match _spot():
		"door":
			return "E  Vào nhà ngủ" if evening else ""
		"thung":
			return "E  Xuống thúng" if evening else ""
		"lane":
			return "" if evening else "E  Ra quán"
	return ""


## Where Rin stands: "door", "thung", "lane" or "".
func _spot() -> String:
	if Walker3D.near(player, WaterfrontBuilder3D.DOOR, REACH):
		return "door"
	if Walker3D.near(player, WaterfrontBuilder3D.THUNG, REACH + 0.6):
		return "thung"
	if Walker3D.near(player, WaterfrontBuilder3D.LANE, REACH + 0.6):
		return "lane"
	return ""


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.physical_keycode != KEY_E or leaving:
		return
	if _choice_text() == "":
		return
	get_viewport().set_input_as_handled()
	match _spot():
		"door":
			go_to_sleep()
		"thung":
			go_to_sea()
		"lane":
			go_to_restaurant()


func go_to_restaurant() -> void:
	_leave(RESTAURANT)


## The house door in the evening: no night at sea; the bedroom judges it.
func go_to_sleep() -> void:
	LoopCalendar.choose(false)
	_leave(BEDROOM)


## Down into the thúng: the night at sea (docking judges it as "went out").
func go_to_sea() -> void:
	_leave(SEA)


func _leave(path: String) -> void:
	leaving = true
	text.prompt("")
	GameState.story_flags.erase(EVENING_FLAG)
	SceneRouter.go_to(path)
