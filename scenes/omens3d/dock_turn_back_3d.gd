class_name DockTurnBack3D
extends Node
## Until the boat first leaves the dock, Rin can still change his mind: R at
## the dock goes home to sleep (the night counts as "home" for LoopCalendar),
## so omens seen only from the pier stay fair. Once he has rowed out, R at
## the dock ends the trip as usual (SeaScene3D: the night counts as "out").

## The boat has left once this far from the dock point.
@export var leave_radius: float = 6.0

var sea: SeaScene3D
var left_dock := false
var _text: OnScreenText


func _ready() -> void:
	_text = OnScreenText.new()
	add_child(_text)


func _process(_delta: float) -> void:
	if not left_dock and sea.boat.position.distance_to(sea.START) > leave_radius:
		left_dock = true
	_text.prompt("R  Thôi, về nhà ngủ" if can_turn_back() else "")


func can_turn_back() -> bool:
	return not left_dock and not sea.ending and not sea.fishing and not sea.poi_busy \
		and not (sea.hold_ui and sea.hold_ui.visible) and not get_tree().paused and sea._at_dock()


## Children get input before their parent, so this runs before SeaScene3D's R.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.physical_keycode != KEY_R:
		return
	if not can_turn_back():
		return
	get_viewport().set_input_as_handled()
	turn_back()


func turn_back() -> void:
	sea.ending = true
	_text.prompt("")
	DayClock.stop()
	LoopCalendar.choose(false)
	GameState.resume_at = "home"
	SceneRouter.go_to(SeaTrip3D.BEDROOM_SCENE)
