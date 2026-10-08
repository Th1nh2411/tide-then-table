extends Node2D
## Top-down restaurant prototype (F6 this scene). Vietnamese sidewalk
## seafood spot: open-air kitchen + food cart (the pass) on the left, low
## tables and plastic stools on the pavement, road below; 16 px tiles
## (Stardew scale), endless shift. Not wired into the game flow yet; built in code to stay throwaway.

const COOKING_SCENE := preload("res://scenes/restaurant/cooking/cooking_overlay.tscn")
const MENU := preload("res://data/dishes/menu.tres")

var room: TdRoom
var chef: TdChef
var waiter: TdWaiter
var kitchen: TdKitchen
var customers: TdCustomers
var hud: TdHud


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color(0.12, 0.1, 0.09)
	background.size = Vector2(640, 360)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	room = TdRoom.new()
	add_child(room)
	var bikes := TdBikes.new()
	bikes.room = room
	add_child(bikes)
	var people := Node2D.new()
	people.y_sort_enabled = true
	add_child(people)

	chef = TdChef.new()
	chef.room = room
	chef.hat = true
	chef.label = "Rin"
	chef.speed = 95.0
	chef.position = room.grid.to_world(Vector2i(4, 8))
	people.add_child(chef)

	var cooking: CookingOverlay = COOKING_SCENE.instantiate()
	add_child(cooking)
	# Pops over the road below the kitchen: tables and the cart stay visible.
	var panel := cooking.get_node("Panel") as Control
	panel.offset_left = 8.0
	panel.offset_right = 238.0
	panel.offset_top = 196.0
	panel.offset_bottom = 312.0

	customers = TdCustomers.new()
	kitchen = TdKitchen.new()
	kitchen.room = room
	kitchen.chef = chef
	kitchen.customers = customers
	kitchen.cooking = cooking
	kitchen.menu = MENU
	customers.room = room
	customers.people_layer = people
	customers.kitchen = kitchen
	customers.bikes = bikes
	add_child(kitchen)
	add_child(customers)

	waiter = TdWaiter.new()
	waiter.room = room
	waiter.customers = customers
	waiter.body_color = Color(0.85, 0.5, 0.2)
	waiter.label = "Bảo"
	waiter.position = room.grid.to_world(Vector2i(10, 8))
	people.add_child(waiter)

	var markers := TdMarkers.new()
	markers.room = room
	markers.chef = chef
	markers.customers = customers
	markers.kitchen = kitchen
	add_child(markers)

	var layer := CanvasLayer.new()
	add_child(layer)
	hud = TdHud.new()
	hud.kitchen = kitchen
	hud.customers = customers
	layer.add_child(hud)
