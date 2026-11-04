class_name Subtitles
extends CanvasLayer
## The one subtitle strip of the screen: a CanvasLayer "Subtitles" under the
## tree root holding a single SpeechStrip, so every source (restaurant notes,
## OnScreenText, the sea HUD, omens, ram scenes) shares one queue and two lines
## never draw over each other. It forgets its line when the scene changes.

const NODE_NAME := "Subtitles"

static var _layer: Subtitles

var strip := SpeechStrip.new()
var _scene_id: int = 0


func _init() -> void:
	name = NODE_NAME
	layer = 20
	add_child(strip)


func _ready() -> void:
	_scene_id = _current_id()


## The shared strip, made on first use (added to the root deferred when the
## root is still setting up the first scene).
static func of(from: Node) -> SpeechStrip:
	var tree := from.get_tree() if from.is_inside_tree() else Engine.get_main_loop() as SceneTree
	var found := find(tree)
	if found:
		return found
	_layer = Subtitles.new()
	tree.root.add_child.call_deferred(_layer)
	return _layer.strip


## The shared strip if one exists (null otherwise).
static func find(_tree: SceneTree) -> SpeechStrip:
	if is_instance_valid(_layer) and not _layer.is_queued_for_deletion():
		return _layer.strip
	return null


func _process(_delta: float) -> void:
	var now := _current_id()
	if now != _scene_id:
		_scene_id = now
		strip.reset()  # a new scene: the old one's lines go with it


func _current_id() -> int:
	var scene := get_tree().current_scene
	return scene.get_instance_id() if scene else 0
