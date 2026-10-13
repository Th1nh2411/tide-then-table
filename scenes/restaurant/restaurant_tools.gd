class_name RestaurantTools
extends Node
## The restaurant's add-ons that only need a few references: Nhịp Sóng
## (WavePower, Rin keeps his speed), the quest box (QuestTracker) and the
## debug keys (RestaurantDebug F1/F2, CutsceneDebug F3/F4). Set the vars,
## then add it as a child.

signal message_requested(text: String, seconds: float)

var cutscene: CutscenePlayer
var cutscenes: Array[Cutscene] = []
var menu_panel: MenuSetupPanel
var plan: MenuPlan
var fish_catalog: FishCatalog
var stall: MarketStall
var wave_seconds: float = 4.0
## () -> bool: Nhịp Sóng only while serving.
var wave_allowed: Callable
## () -> Vector2: where the ripple starts (Rin on screen).
var ripple_origin: Callable


func _ready() -> void:
	var wave := WavePower.new()
	wave.seconds = wave_seconds
	wave.keep_rin_speed = true
	wave.can_use = wave_allowed
	wave.ripple_origin = ripple_origin
	add_child(wave)
	var tracker := QuestTracker.new()
	tracker.catalog = fish_catalog
	tracker.origin = Vector2(4, 26)  # under the order tickets
	add_child(tracker)
	cutscene.hidden_nodes.append(tracker)
	var story_debug := CutsceneDebug.new()
	story_debug.player = cutscene
	story_debug.cutscenes.assign(cutscenes)
	story_debug.message_requested.connect(func(text: String) -> void: message_requested.emit(text, 2.5))
	add_child(story_debug)
	var debug := RestaurantDebug.new()
	debug.menu_panel = menu_panel
	debug.plan = plan
	debug.fish_catalog = fish_catalog
	debug.stall = stall
	debug.message_requested.connect(func(text: String) -> void: message_requested.emit(text, 1.5))
	add_child(debug)
