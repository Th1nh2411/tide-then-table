class_name NightErrand3D
extends Node3D
## A calm night's small errand at sea (horror build): a faint ghost-light on
## the water some way out from the dock, with something floating in it — a
## bottle, a rope, a diary page. Rowing there and pressing E picks it up and
## shows what it says (CLUES, one per day). Kept in Rin's notebook
## ("note_clue_<day>", survives loop resets). Not added on omen nights or rằm.

const CLUES: LinesData = preload("res://data/story/clues.tres")
const REACH := 2.6
const NOTE_PREFIX := "note_clue_"

@export var distance := 20.0

var sea: SeaScene3D
var taken := false
var _ring: MeshInstance3D
var _item: MeshInstance3D
var _text: OnScreenText
var _time := 0.0


static func attach(owner: SeaScene3D) -> NightErrand3D:
	if GameState.has_flag(LoopCalendar.OMEN_FLAG) or RamNight.is_ram():
		return null
	var errand := NightErrand3D.new()
	errand.name = "NightErrand"
	errand.sea = owner
	owner.add_child(errand)
	return errand


static func clue_count() -> int:
	var count := 0
	for key: String in GameState.story_flags:
		if key.begins_with(NOTE_PREFIX):
			count += 1
	return count


func _ready() -> void:
	# A different spot each day, always ahead of the dock and inside the boat's reach.
	var angle := -0.9 + 0.3 * float((GameState.day * 5) % 7)
	position = sea.START + Vector3(sin(angle) * distance, 0, -cos(angle) * distance)
	_ring = OmenProps3D.glow_box(self, Vector3(0, 0.12, 0), Vector3(1.6, 0.02, 1.6), "7fe8d8", 1.6)
	_item = OmenProps3D.glow_box(self, Vector3(0, 0.22, 0), Vector3(0.12, 0.12, 0.34), "d9cfa8", 0.6)
	OmenProps3D.light(self, Vector3(0, 0.6, 0), "7fe8d8", 0.9, 5.0)
	_text = OnScreenText.new()
	add_child(_text)


func _process(delta: float) -> void:
	_time += delta
	if taken:
		return
	_ring.scale = Vector3.ONE * (1.0 + 0.12 * sin(_time * 1.6))
	_item.position.y = 0.22 + sin(_time * 1.3) * 0.05
	_item.rotation.y += delta * 0.3
	_text.prompt("E  Vớt lên" if _near() else "")


func _near() -> bool:
	var at := sea.boat.global_position
	return Vector2(at.x - global_position.x, at.z - global_position.z).length() < REACH


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if taken or key == null or not key.pressed or key.echo or key.physical_keycode != KEY_E or not _near():
		return
	get_viewport().set_input_as_handled()
	pick_up()


## Picks the thing up: its words on screen, a page in Rin's notebook.
func pick_up() -> void:
	taken = true
	_text.prompt("")
	_ring.visible = false
	_item.visible = false
	var index := clampi(GameState.day - 1, 0, CLUES.lines.size() - 1)
	GameState.set_flag(NOTE_PREFIX + str(index + 1))
	Sfx.play("splash")
	_text.say(CLUES.line(index), 7.0)
