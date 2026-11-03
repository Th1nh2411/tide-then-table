class_name UncannySea3D
extends Node3D
## Tonight's uncanny plan at sea (one line in SeaSetup3D). Calm nights keep
## the sea as the honest baseline: only the fake scare (a fish slaps into
## the thúng, once per playthrough, day 2 or 3). Omen nights (đêm âm): from
## the day wrong movement starts, the figures DarkNight3D sends move at a
## few frames a second; on mùng 13-14 the night's heavy effect plays out
## here if the village did not already have it (a drowned figure closer on
## the water each look, ending beside the thúng; a dash; a one-frame flash).

var sea: SeaScene3D
var plan: Dictionary = {}
## Seconds out before the heavy effect may start.
@export var heavy_after := 14.0
@export var choppy_fps := 7.0

var _heavy_wait := 0.0
var _heavy_started := false


static func attach(host: SeaScene3D) -> UncannySea3D:
	var node := UncannySea3D.new()
	node.name = "UncannySea"
	node.sea = host
	host.add_child(node)
	return node


func _ready() -> void:
	plan = UncannyDirector.tonight()
	_heavy_wait = heavy_after
	FakeFishScare3D.attach(sea)
	var dark := DarkNight3D.active(sea)
	if dark and GameState.day >= int(UncannyDirector.DOSE.light_from_day.get("choppy", 4)):
		dark.child_entered_tree.connect(_on_dark_child)


func _process(delta: float) -> void:
	if _heavy_started or sea.ending or DarkNight3D.active(sea) == null:
		return
	var heavy := str(plan.get("heavy", ""))
	if heavy == "" or int(GameState.story_flags.get(UncannyVillage3D.HEAVY_FLAG, -1)) == GameState.day:
		return
	if sea._at_dock() or sea.fishing:
		return
	_heavy_wait -= delta
	if _heavy_wait > 0.0:
		return
	_heavy_started = true
	var kind := UncannyHeavy3D.Kind.FLASH
	if heavy == "appear_close":
		kind = UncannyHeavy3D.Kind.APPEAR_CLOSE
	elif heavy == "dash":
		kind = UncannyHeavy3D.Kind.DASH
	var effect := UncannyHeavy3D.start(self, kind)
	effect.ground_y = SeaWater3D.WATER_Y
	effect.finished.connect(func() -> void: GameState.set_flag(UncannyVillage3D.HEAVY_FLAG, GameState.day))


## Đêm âm figures step through their motion at a few frames a second.
func _on_dark_child(node: Node) -> void:
	if node is DarkNightFigure3D:
		ChoppyNode3D.wrap(node as Node3D, choppy_fps)
