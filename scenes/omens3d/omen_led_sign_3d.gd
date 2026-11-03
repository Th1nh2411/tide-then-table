class_name OmenLedSign3D
extends Node3D
## The LED strip on the shop front: cycles the fixed menu's dishes one at a
## time. On the "led_chao" night one entry is a dish the shop never sells
## (the omen's text, e.g. CHÁO TRẮNG: food for the dead).

const MENU: FixedMenuData = preload("res://data/restaurant/fixed_menu.tres")
const OMEN_ID := "led_chao"

@export var seconds_per_item: float = 1.8
@export var size := Vector2(2.7, 0.34)

var items: Array[String] = []
var _label: Label3D
var _clock := 0.0
var _index := 0


func _ready() -> void:
	OmenProps3D.box(self, Vector3.ZERO, Vector3(size.x + 0.1, size.y + 0.1, 0.05), "3a3a3a")
	OmenProps3D.box(self, Vector3(0, 0, 0.03), Vector3(size.x, size.y, 0.02), "0c0c0e")
	_label = Label3D.new()
	_label.font_size = 40
	_label.pixel_size = 0.005
	_label.modulate = Color("c9683a")  # old LED strip, dim
	_label.outline_size = 0
	_label.position = Vector3(0, 0, 0.05)
	add_child(_label)
	for dish in MENU.dishes:
		items.append(dish.display_name.to_upper())
	var omen := OmenPicker.tonight()
	if omen and omen.id == OMEN_ID:
		items.insert(mini(2, items.size()), omen.text)
	_show(0)


func _process(delta: float) -> void:
	_clock += delta
	if _clock >= seconds_per_item:
		_clock = 0.0
		_show(_index + 1)


func _show(index: int) -> void:
	if items.is_empty():
		return
	_index = index % items.size()
	_label.text = items[_index]
