class_name RestaurantFish3D
extends Node3D
## The fish side of the restaurant (3-fish rule, LoopCalendar): the tray of
## fish Rin brought last night beside Bảo's cart (LoopCalendar.shop_fish),
## and Bảo's words once per shift: a grumble the day after Rin stayed home on
## an omen night (no fish to sell) or a word on last night's fish, then
## asking for tonight's fish.

const NODE_NAME := "ShopFish"
## On a stool left of Bảo, against the cart's back corner.
const TRAY_POSITION := Vector3(0.35, 0, -5.45)
const ASK_LINE := "Bảo: Tối nay kiếm ít nhất 3 con nghe, mai quán cần cá."
const GRUMBLE_LINE := "Bảo: Hôm qua mày đi đâu, hết cá bán rồi."
## Last night's catch is on the tray (data/story/bao.tres "fish").
const BAO: NpcLinesData = preload("res://data/story/bao.tres")

## Seconds after the shift opens before Bảo speaks, and between his lines.
@export var talk_delay := 3.0
@export var line_gap := 4.5

var host: RestaurantScene3D
var fish_count := 0
var lines: Array[String] = []
var _next := 0
var _wait := 0.0


static func build(owner: RestaurantScene3D) -> RestaurantFish3D:
	var shop := RestaurantFish3D.new()
	shop.name = NODE_NAME
	shop.host = owner
	owner.add_child(shop)
	return shop


## What Bảo says this shift (rằm: anh Út's night, he does not ask).
static func bao_lines() -> Array[String]:
	var said: Array[String] = []
	if GameState.has_flag(LoopCalendar.NO_FISH_FLAG):
		said.append(GRUMBLE_LINE)
	elif LoopCalendar.shop_fish() > 0:
		said.append(BAO.named_line("fish"))
	if not RamNight.is_ram():
		said.append(ASK_LINE)
	return said


func _ready() -> void:
	fish_count = LoopCalendar.shop_fish()
	lines = bao_lines()
	_wait = talk_delay
	position = TRAY_POSITION
	_build_tray()


func _process(delta: float) -> void:
	if _next >= lines.size() or not host.shift_running:
		return
	_wait -= delta
	if _wait <= 0.0:
		host._show_note(lines[_next])
		_next += 1
		_wait = line_gap


func _build_tray() -> void:
	var stool := MeshInstance3D.new()
	var leg := CylinderMesh.new()
	leg.top_radius = 0.2
	leg.bottom_radius = 0.22
	leg.height = 0.42
	stool.mesh = leg
	stool.material_override = _mat(Color("3d6b8a"))
	stool.position.y = 0.21
	add_child(stool)
	var tray := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.62, 0.06, 0.42)
	tray.mesh = box
	tray.material_override = _mat(Color("b9b4a6"))
	tray.position.y = 0.45
	add_child(tray)
	for i in range(fish_count):
		var model := FishBasket3D.fish_mesh(null, 1.0)
		add_child(model)
		model.position = Vector3(-0.17 + float(i % 3) * 0.17, 0.5 + float(i / 3) * 0.05, -0.1 + float((i / 3) % 2) * 0.2)
		model.rotation.y = PI * 0.5 + (i % 2) * 0.3


static func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.6
	return m
